// SUI Move contract for ETH-SUI cross-chain atomic swaps
// This is the counterpart to the Ethereum escrow contracts

module cross_chain_escrow::escrow {
    use std::vector;
    use std::option::{Self, Option};
    
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::hash;
    use sui::address;
    use sui::table::{Self, Table};
    use sui::vec_map::{Self, VecMap};

    // ============= Error Codes =============
    const E_INVALID_HASHLOCK: u64 = 1;
    const E_INVALID_SECRET: u64 = 2;
    const E_ESCROW_EXPIRED: u64 = 3;
    const E_ESCROW_NOT_EXPIRED: u64 = 4;
    const E_UNAUTHORIZED: u64 = 5;
    const E_INSUFFICIENT_AMOUNT: u64 = 6;
    const E_ESCROW_ALREADY_EXISTS: u64 = 7;
    const E_ESCROW_NOT_FOUND: u64 = 8;
    const E_INVALID_TIMELOCK: u64 = 9;
    const E_WITHDRAWAL_TOO_EARLY: u64 = 10;
    const E_CANCELLATION_TOO_EARLY: u64 = 11;
    const E_ESCROW_ALREADY_COMPLETED: u64 = 12;
    const E_INVALID_WITNESS: u64 = 13;

    // ============= Structs =============

    /// Cross-chain escrow for atomic swaps
    public struct CrossChainEscrow<phantom T> has key, store {
        id: UID,
        order_hash: vector<u8>,
        hashlock: vector<u8>,
        sui_maker: address,
        eth_counterparty: address,
        locked_amount: Balance<T>,
        safety_deposit: u64,
        created_at: u64,
        withdrawal_time: u64,
        public_withdrawal_time: u64,
        cancellation_time: u64,
        status: u8, // 0: Active, 1: Completed, 2: Cancelled
        witnesses: vector<address>,
    }

    /// Capability for escrow administration
    public struct EscrowAdminCap has key, store {
        id: UID,
    }

    /// Registry for tracking all escrows
    public struct EscrowRegistry has key {
        id: UID,
        escrows: Table<vector<u8>, ID>, // order_hash -> escrow_id
        authorized_validators: VecMap<address, bool>,
        min_validators: u64,
        max_escrow_duration: u64,
    }

    /// Witness for creating escrows
    public struct CrossChainWitness has drop {}

    /// Configuration for timelock settings
    public struct TimelockConfig has copy, drop, store {
        finality_delay: u64,
        public_window: u64,
        cancellation_delay: u64,
    }

    // ============= Events =============

    public struct EscrowCreated has copy, drop {
        escrow_id: ID,
        order_hash: vector<u8>,
        sui_maker: address,
        eth_counterparty: address,
        amount: u64,
        withdrawal_time: u64,
        cancellation_time: u64,
    }

    public struct EscrowWithdrawn has copy, drop {
        escrow_id: ID,
        order_hash: vector<u8>,
        secret: vector<u8>,
        recipient: address,
        amount: u64,
    }

    public struct EscrowCancelled has copy, drop {
        escrow_id: ID,
        order_hash: vector<u8>,
        cancelled_by: address,
        refunded_amount: u64,
    }

    public struct ValidatorAdded has copy, drop {
        validator: address,
        added_by: address,
    }

    // ============= Initialization =============

    /// Initialize the escrow module
    fun init(ctx: &mut TxContext) {
        // Create admin capability
        let admin_cap = EscrowAdminCap {
            id: object::new(ctx),
        };

        // Create escrow registry
        let registry = EscrowRegistry {
            id: object::new(ctx),
            escrows: table::new(ctx),
            authorized_validators: vec_map::empty(),
            min_validators: 2,
            max_escrow_duration: 604800000, // 7 days in milliseconds
        };

        // Transfer admin capability to deployer
        transfer::transfer(admin_cap, tx_context::sender(ctx));
        transfer::share_object(registry);
    }

    // ============= Public Functions =============

    /// Create a new cross-chain escrow
    public fun create_escrow<T>(
        registry: &mut EscrowRegistry,
        payment: Coin<T>,
        order_hash: vector<u8>,
        hashlock: vector<u8>,
        eth_counterparty: address,
        timelock_config: TimelockConfig,
        safety_deposit: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ): ID {
        // Validate inputs
        assert!(vector::length(&order_hash) == 32, E_INVALID_HASHLOCK);
        assert!(vector::length(&hashlock) == 32, E_INVALID_HASHLOCK);
        assert!(!table::contains(&registry.escrows, order_hash), E_ESCROW_ALREADY_EXISTS);
        
        let amount = coin::value(&payment);
        assert!(amount > 0, E_INSUFFICIENT_AMOUNT);
        
        let current_time = clock::timestamp_ms(clock);
        
        // Validate timelocks
        assert!(timelock_config.finality_delay > 0, E_INVALID_TIMELOCK);
        assert!(timelock_config.public_window > timelock_config.finality_delay, E_INVALID_TIMELOCK);
        assert!(timelock_config.cancellation_delay > timelock_config.public_window, E_INVALID_TIMELOCK);
        assert!(timelock_config.cancellation_delay <= registry.max_escrow_duration, E_INVALID_TIMELOCK);

        // Calculate timelock timestamps
        let withdrawal_time = current_time + timelock_config.finality_delay;
        let public_withdrawal_time = current_time + timelock_config.public_window;
        let cancellation_time = current_time + timelock_config.cancellation_delay;

        // Create escrow
        let escrow = CrossChainEscrow<T> {
            id: object::new(ctx),
            order_hash,
            hashlock,
            sui_maker: tx_context::sender(ctx),
            eth_counterparty,
            locked_amount: coin::into_balance(payment),
            safety_deposit,
            created_at: current_time,
            withdrawal_time,
            public_withdrawal_time,
            cancellation_time,
            status: 0, // Active
            witnesses: vector::empty(),
        };

        let escrow_id = object::id(&escrow);
        
        // Register escrow
        table::add(&mut registry.escrows, order_hash, escrow_id);

        // Emit event
        event::emit(EscrowCreated {
            escrow_id,
            order_hash,
            sui_maker: tx_context::sender(ctx),
            eth_counterparty,
            amount,
            withdrawal_time,
            cancellation_time,
        });

        // Share escrow object
        transfer::share_object(escrow);
        escrow_id
    }

    /// Withdraw funds from escrow with secret (for ETH counterparty)
    public fun withdraw<T>(
        escrow: &mut CrossChainEscrow<T>,
        secret: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<T> {
        assert!(escrow.status == 0, E_ESCROW_ALREADY_COMPLETED);
        
        let current_time = clock::timestamp_ms(clock);
        assert!(current_time >= escrow.withdrawal_time, E_WITHDRAWAL_TOO_EARLY);
        assert!(current_time < escrow.cancellation_time, E_ESCROW_EXPIRED);

        // Verify secret matches hashlock
        let computed_hash = hash::sha2_256(secret);
        assert!(computed_hash == escrow.hashlock, E_INVALID_SECRET);

        // Mark as completed
        escrow.status = 1;

        // Calculate withdrawal amount (keeping safety deposit for gas)
        let total_amount = balance::value(&escrow.locked_amount);
        let withdrawal_amount = if (total_amount > escrow.safety_deposit) {
            total_amount - escrow.safety_deposit
        } else {
            total_amount
        };

        // Create coin for withdrawal
        let withdrawn_balance = balance::split(&mut escrow.locked_amount, withdrawal_amount);
        let withdrawal_coin = coin::from_balance(withdrawn_balance, ctx);

        // Emit event
        event::emit(EscrowWithdrawn {
            escrow_id: object::id(escrow),
            order_hash: escrow.order_hash,
            secret,
            recipient: tx_context::sender(ctx),
            amount: withdrawal_amount,
        });

        withdrawal_coin
    }

    /// Public withdrawal (anyone can trigger after public window)
    public fun public_withdraw<T>(
        escrow: &mut CrossChainEscrow<T>,
        secret: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<T> {
        assert!(escrow.status == 0, E_ESCROW_ALREADY_COMPLETED);
        
        let current_time = clock::timestamp_ms(clock);
        assert!(current_time >= escrow.public_withdrawal_time, E_WITHDRAWAL_TOO_EARLY);
        assert!(current_time < escrow.cancellation_time, E_ESCROW_EXPIRED);

        // Verify secret
        let computed_hash = hash::sha2_256(secret);
        assert!(computed_hash == escrow.hashlock, E_INVALID_SECRET);

        // Mark as completed
        escrow.status = 1;

        // Withdraw to ETH counterparty (since this is public withdrawal)
        let total_amount = balance::value(&escrow.locked_amount);
        let withdrawal_amount = if (total_amount > escrow.safety_deposit) {
            total_amount - escrow.safety_deposit
        } else {
            total_amount
        };

        let withdrawn_balance = balance::split(&mut escrow.locked_amount, withdrawal_amount);
        let withdrawal_coin = coin::from_balance(withdrawn_balance, ctx);

        event::emit(EscrowWithdrawn {
            escrow_id: object::id(escrow),
            order_hash: escrow.order_hash,
            secret,
            recipient: escrow.eth_counterparty,
            amount: withdrawal_amount,
        });

        // Note: In practice, this would need to send to ETH counterparty
        // For now, sending to transaction sender who should forward it
        withdrawal_coin
    }

    /// Cancel escrow and refund to maker
    public fun cancel<T>(
        escrow: &mut CrossChainEscrow<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<T> {
        // Only maker can cancel during private cancellation period
        assert!(tx_context::sender(ctx) == escrow.sui_maker, E_UNAUTHORIZED);
        assert!(escrow.status == 0, E_ESCROW_ALREADY_COMPLETED);
        
        let current_time = clock::timestamp_ms(clock);
        assert!(current_time >= escrow.cancellation_time, E_CANCELLATION_TOO_EARLY);

        // Mark as cancelled
        escrow.status = 2;

        // Refund full amount to maker
        let refund_amount = balance::value(&escrow.locked_amount);
        let refund_balance = balance::withdraw_all(&mut escrow.locked_amount);
        let refund_coin = coin::from_balance(refund_balance, ctx);

        event::emit(EscrowCancelled {
            escrow_id: object::id(escrow),
            order_hash: escrow.order_hash,
            cancelled_by: tx_context::sender(ctx),
            refunded_amount: refund_amount,
        });

        refund_coin
    }

    /// Public cancellation (anyone can trigger)
    public fun public_cancel<T>(
        escrow: &mut CrossChainEscrow<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Coin<T> {
        assert!(escrow.status == 0, E_ESCROW_ALREADY_COMPLETED);
        
        let current_time = clock::timestamp_ms(clock);
        // Add buffer time for public cancellation
        assert!(current_time >= escrow.cancellation_time + 3600000, E_CANCELLATION_TOO_EARLY); // +1 hour

        // Mark as cancelled
        escrow.status = 2;

        // Refund to maker
        let refund_amount = balance::value(&escrow.locked_amount);
        let refund_balance = balance::withdraw_all(&mut escrow.locked_amount);
        let refund_coin = coin::from_balance(refund_balance, ctx);

        event::emit(EscrowCancelled {
            escrow_id: object::id(escrow),
            order_hash: escrow.order_hash,
            cancelled_by: tx_context::sender(ctx),
            refunded_amount: refund_amount,
        });

        refund_coin
    }

    // ============= Validator Functions =============

    /// Add validator witness to escrow (for cross-chain verification)
    public fun add_validator_witness(
        registry: &EscrowRegistry,
        escrow: &mut CrossChainEscrow<T>,
        ctx: &TxContext
    ) {
        let validator = tx_context::sender(ctx);
        assert!(vec_map::contains(&registry.authorized_validators, &validator), E_UNAUTHORIZED);
        
        // Add witness if not already present
        if (!vector::contains(&escrow.witnesses, &validator)) {
            vector::push_back(&mut escrow.witnesses, validator);
        };
    }

    /// Check if escrow has sufficient validator witnesses
    public fun has_sufficient_witnesses<T>(
        registry: &EscrowRegistry,
        escrow: &CrossChainEscrow<T>
    ): bool {
        vector::length(&escrow.witnesses) >= registry.min_validators
    }

    // ============= Admin Functions =============

    /// Add authorized validator
    public fun add_validator(
        _: &EscrowAdminCap,
        registry: &mut EscrowRegistry,
        validator: address,
        ctx: &TxContext
    ) {
        vec_map::insert(&mut registry.authorized_validators, validator, true);
        
        event::emit(ValidatorAdded {
            validator,
            added_by: tx_context::sender(ctx),
        });
    }

    /// Remove validator
    public fun remove_validator(
        _: &EscrowAdminCap,
        registry: &mut EscrowRegistry,
        validator: address,
    ) {
        if (vec_map::contains(&registry.authorized_validators, &validator)) {
            vec_map::remove(&mut registry.authorized_validators, &validator);
        };
    }

    /// Update minimum validators required
    public fun update_min_validators(
        _: &EscrowAdminCap,
        registry: &mut EscrowRegistry,
        new_min: u64,
    ) {
        registry.min_validators = new_min;
    }

    /// Emergency cleanup of expired escrows
    public fun cleanup_expired_escrow<T>(
        _: &EscrowAdminCap,
        escrow: &mut CrossChainEscrow<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ): Option<Coin<T>> {
        let current_time = clock::timestamp_ms(clock);
        
        // Only cleanup if significantly expired (7 days past cancellation)
        if (current_time >= escrow.cancellation_time + 604800000 && escrow.status == 0) {
            escrow.status = 2; // Mark as cancelled
            
            let refund_amount = balance::value(&escrow.locked_amount);
            if (refund_amount > 0) {
                let refund_balance = balance::withdraw_all(&mut escrow.locked_amount);
                let refund_coin = coin::from_balance(refund_balance, ctx);
                
                event::emit(EscrowCancelled {
                    escrow_id: object::id(escrow),
                    order_hash: escrow.order_hash,
                    cancelled_by: tx_context::sender(ctx),
                    refunded_amount: refund_amount,
                });
                
                option::some(refund_coin)
            } else {
                option::none()
            }
        } else {
            option::none()
        }
    }

    // ============= View Functions =============

    /// Get escrow details
    public fun get_escrow_info<T>(escrow: &CrossChainEscrow<T>): (
        vector<u8>, // order_hash
        vector<u8>, // hashlock
        address,    // sui_maker
        address,    // eth_counterparty
        u64,        // amount
        u64,        // withdrawal_time
        u64,        // cancellation_time
        u8          // status
    ) {
        (
            escrow.order_hash,
            escrow.hashlock,
            escrow.sui_maker,
            escrow.eth_counterparty,
            balance::value(&escrow.locked_amount),
            escrow.withdrawal_time,
            escrow.cancellation_time,
            escrow.status
        )
    }

    /// Check if escrow exists in registry
    public fun escrow_exists(registry: &EscrowRegistry, order_hash: vector<u8>): bool {
        table::contains(&registry.escrows, order_hash)
    }

    /// Get escrow ID by order hash
    public fun get_escrow_id(registry: &EscrowRegistry, order_hash: vector<u8>): Option<ID> {
        if (table::contains(&registry.escrows, order_hash)) {
            option::some(*table::borrow(&registry.escrows, order_hash))
        } else {
            option::none()
        }
    }

    /// Check if address is authorized validator
    public fun is_authorized_validator(registry: &EscrowRegistry, validator: address): bool {
        vec_map::contains(&registry.authorized_validators, &validator)
    }

    /// Get witness count for escrow
    public fun get_witness_count<T>(escrow: &CrossChainEscrow<T>): u64 {
        vector::length(&escrow.witnesses)
    }

    /// Check if escrow is active
    public fun is_escrow_active<T>(escrow: &CrossChainEscrow<T>): bool {
        escrow.status == 0
    }

    /// Check if withdrawal is allowed
    public fun can_withdraw<T>(escrow: &CrossChainEscrow<T>, clock: &Clock): bool {
        if (escrow.status != 0) return false;
        
        let current_time = clock::timestamp_ms(clock);
        current_time >= escrow.withdrawal_time && current_time < escrow.cancellation_time
    }

    /// Check if cancellation is allowed
    public fun can_cancel<T>(escrow: &CrossChainEscrow<T>, clock: &Clock): bool {
        if (escrow.status != 0) return false;
        
        let current_time = clock::timestamp_ms(clock);
        current_time >= escrow.cancellation_time
    }

    // ============= Utility Functions =============

    /// Create default timelock configuration
    public fun default_timelock_config(): TimelockConfig {
        TimelockConfig {
            finality_delay: 1800000,  // 30 minutes
            public_window: 5400000,   // 1.5 hours
            cancellation_delay: 90000000, // 25 hours
        }
    }

    /// Create conservative timelock configuration
    public fun conservative_timelock_config(): TimelockConfig {
        TimelockConfig {
            finality_delay: 3600000,  // 1 hour
            public_window: 10800000,  // 3 hours
            cancellation_delay: 180000000, // 50 hours
        }
    }

    /// Create fast timelock configuration
    public fun fast_timelock_config(): TimelockConfig {
        TimelockConfig {
            finality_delay: 900000,   // 15 minutes
            public_window: 2700000,   // 45 minutes
            cancellation_delay: 45000000, // 12.5 hours
        }
    }

    /// Verify secret against hashlock
    public fun verify_secret(secret: vector<u8>, hashlock: vector<u8>): bool {
        let computed_hash = hash::sha2_256(secret);
        computed_hash == hashlock
    }

    // ============= Test Functions =============

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }

    #[test_only]
    public fun create_test_escrow<T>(
        registry: &mut EscrowRegistry,
        payment: Coin<T>,
        ctx: &mut TxContext
    ): ID {
        let order_hash = b"test_order_hash_32_bytes_long!!";
        let hashlock = b"test_hashlock_32_bytes_long_too!";
        let eth_counterparty = @0x1234;
        let timelock_config = default_timelock_config();
        
        // Mock clock for testing
        let clock = clock::create_for_testing(ctx);
        let escrow_id = create_escrow(
            registry,
            payment,
            order_hash,
            hashlock,
            eth_counterparty,
            timelock_config,
            1000, // safety deposit
            &clock,
            ctx
        );
        clock::destroy_for_testing(clock);
        escrow_id
    }
}