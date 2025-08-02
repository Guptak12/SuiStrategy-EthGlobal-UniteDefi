// sui_escrow_factory.move
module fusionplus::escrow_factory {
    use sui::coin::{Self, Coin};
    use sui::sui::{Self, SUI};
    use sui::balance::{Self, Balance};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::hash;

    // ========== Constants ==========
    
    const ETH_CHAIN_ID: u256 = 1;
    
    // Error codes
    const E_INVALID_SECRET: u64 = 1;
    const E_INVALID_TIME: u64 = 2;
    const E_UNAUTHORIZED: u64 = 3;
    const E_ALREADY_WITHDRAWN: u64 = 4;
    const E_ALREADY_CANCELLED: u64 = 5;
    const E_INSUFFICIENT_BALANCE: u64 = 6;
    const E_INVALID_HASHLOCK: u64 = 7;

    // ========== Structs ==========

    /// Factory for creating cross-chain escrows
    public struct EscrowFactory has key {
        id: UID,
        admin: address,
        rescue_delay: u64,
    }

    /// Timelock configuration for cross-chain coordination
    public struct Timelocks has store, copy, drop {
        withdrawal_start: u64,
        public_withdrawal_start: u64,
        cancellation_start: u64,
        deployed_at: u64,
    }

    /// Source escrow for SUI → ETH swaps
    public struct SuiEscrowSrc<phantom T> has key {
        id: UID,
        // Immutable swap parameters
        order_hash: vector<u8>,
        hashlock: vector<u8>,
        maker: address,
        taker: address,
        // Locked funds
        amount: Balance<T>,
        safety_deposit: Balance<SUI>,
        // Timing controls
        timelocks: Timelocks,
        // State tracking
        is_withdrawn: bool,
        is_cancelled: bool,
        // Cross-chain reference
        eth_chain_id: u256,
    }

    /// Destination escrow for ETH → SUI swaps  
    public struct SuiEscrowDst<phantom T> has key {
        id: UID,
        // Immutable swap parameters
        order_hash: vector<u8>,
        hashlock: vector<u8>,
        maker: address,
        taker: address,
        // Locked funds
        amount: Balance<T>,
        safety_deposit: Balance<SUI>,
        // Timing controls
        timelocks: Timelocks,
        // State tracking
        is_withdrawn: bool,
        is_cancelled: bool,
        // Fee structure
        protocol_fee_amount: u64,
        integrator_fee_amount: u64,
        protocol_fee_recipient: address,
        integrator_fee_recipient: address,
    }

    // ========== Events ==========

    public struct SuiEscrowCreated has copy, drop {
        escrow_id: ID,
        order_hash: vector<u8>,
        hashlock: vector<u8>,
        maker: address,
        taker: address,
        amount: u64,
        eth_chain_id: u256,
    }

    public struct EscrowWithdrawal has copy, drop {
        escrow_id: ID,
        secret: vector<u8>,
        recipient: address,
    }

    public struct EscrowCancelled has copy, drop {
        escrow_id: ID,
        refund_recipient: address,
    }

    public struct SecretRevealed has copy, drop {
        order_hash: vector<u8>,
        secret: vector<u8>,
        hashlock: vector<u8>,
    }

    // ========== Factory Functions ==========

    /// Initialize the escrow factory
    fun init(ctx: &mut TxContext) {
        let factory = EscrowFactory {
            id: object::new(ctx),
            admin: tx_context::sender(ctx),
            rescue_delay: 7 * 24 * 60 * 60 * 1000, // 7 days in milliseconds
        };
        transfer::share_object(factory);
    }

    /// Create source escrow for SUI → ETH swap
    public entry fun create_src_escrow<T>(
        factory: &EscrowFactory,
        order_hash: vector<u8>,
        hashlock: vector<u8>,
        maker: address,
        taker: address,
        sui_coin: Coin<T>,
        safety_deposit: Coin<SUI>,
        withdrawal_delay: u64,
        public_withdrawal_delay: u64,
        cancellation_delay: u64,
        eth_chain_id: u256,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        
        let timelocks = Timelocks {
            withdrawal_start: current_time + withdrawal_delay,
            public_withdrawal_start: current_time + public_withdrawal_delay,
            cancellation_start: current_time + cancellation_delay,
            deployed_at: current_time,
        };

        let amount = coin::value(&sui_coin);
        let deposit_amount = coin::value(&safety_deposit);

        let escrow = SuiEscrowSrc<T> {
            id: object::new(ctx),
            order_hash,
            hashlock,
            maker,
            taker,
            amount: coin::into_balance(sui_coin),
            safety_deposit: coin::into_balance(safety_deposit),
            timelocks,
            is_withdrawn: false,
            is_cancelled: false,
            eth_chain_id,
        };

        let escrow_id = object::id(&escrow);

        event::emit(SuiEscrowCreated {
            escrow_id,
            order_hash,
            hashlock,
            maker,
            taker,
            amount,
            eth_chain_id,
        });

        transfer::share_object(escrow);
    }

    /// Create destination escrow for ETH → SUI swap
    public entry fun create_dst_escrow<T>(
        factory: &EscrowFactory,
        order_hash: vector<u8>,
        hashlock: vector<u8>,
        maker: address,
        taker: address,
        sui_coin: Coin<T>,
        safety_deposit: Coin<SUI>,
        withdrawal_delay: u64,
        public_withdrawal_delay: u64,
        cancellation_delay: u64,
        protocol_fee_amount: u64,
        integrator_fee_amount: u64,
        protocol_fee_recipient: address,
        integrator_fee_recipient: address,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        
        let timelocks = Timelocks {
            withdrawal_start: current_time + withdrawal_delay,
            public_withdrawal_start: current_time + public_withdrawal_delay,
            cancellation_start: current_time + cancellation_delay,
            deployed_at: current_time,
        };

        let escrow = SuiEscrowDst<T> {
            id: object::new(ctx),
            order_hash,
            hashlock,
            maker,
            taker,
            amount: coin::into_balance(sui_coin),
            safety_deposit: coin::into_balance(safety_deposit),
            timelocks,
            is_withdrawn: false,
            is_cancelled: false,
            protocol_fee_amount,
            integrator_fee_amount,
            protocol_fee_recipient,
            integrator_fee_recipient,
        };

        let escrow_id = object::id(&escrow);
        let mut escrow = escrow;


let split_coin = coin::from_balance(balance::split(&mut escrow.amount, 0), ctx);

let value_for_event = coin::value(&split_coin);


coin::destroy_zero(split_coin);

        event::emit(SuiEscrowCreated {
            escrow_id,
            order_hash,
            hashlock,
            maker,
            taker,
            amount:value_for_event,
            eth_chain_id: ETH_CHAIN_ID, 
        });

        transfer::share_object(escrow);
    }

    // ========== Source Escrow Functions ==========

    /// Withdraw from source escrow (SUI → ETH swap)
    public entry fun withdraw_src<T>(
        escrow: &mut SuiEscrowSrc<T>,
        secret: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        
        // Validate caller is taker
        assert!(sender == escrow.taker, E_UNAUTHORIZED);
        
        // Validate timing
        assert!(current_time >= escrow.timelocks.withdrawal_start, E_INVALID_TIME);
        assert!(current_time < escrow.timelocks.cancellation_start, E_INVALID_TIME);
        
        // Validate not already processed
        assert!(!escrow.is_withdrawn, E_ALREADY_WITHDRAWN);
        assert!(!escrow.is_cancelled, E_ALREADY_CANCELLED);
        
        // Validate secret
        let computed_hash = hash::keccak256(&secret);
        assert!(computed_hash == escrow.hashlock, E_INVALID_SECRET);
        
        // Mark as withdrawn
        escrow.is_withdrawn = true;
        
        // Transfer funds to taker
        let amount = balance::withdraw_all(&mut escrow.amount);
        let safety_deposit = balance::withdraw_all(&mut escrow.safety_deposit);
        
        transfer::public_transfer(coin::from_balance(amount, ctx), sender);
        transfer::public_transfer(coin::from_balance(safety_deposit, ctx), sender);
        
        // Emit events
        event::emit(EscrowWithdrawal {
            escrow_id: object::id(escrow),
            secret,
            recipient: sender,
        });
        
        event::emit(SecretRevealed {
            order_hash: escrow.order_hash,
            secret,
            hashlock: escrow.hashlock,
        });
    }

    /// Public withdraw from source escrow (anyone can call with secret)
    public entry fun public_withdraw_src<T>(
        escrow: &mut SuiEscrowSrc<T>,
        secret: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        
        // Validate timing - must be in public withdrawal period
        assert!(current_time >= escrow.timelocks.public_withdrawal_start, E_INVALID_TIME);
        assert!(current_time < escrow.timelocks.cancellation_start, E_INVALID_TIME);
        
        // Validate not already processed
        assert!(!escrow.is_withdrawn, E_ALREADY_WITHDRAWN);
        assert!(!escrow.is_cancelled, E_ALREADY_CANCELLED);
        
        // Validate secret
        let computed_hash = hash::keccak256(&secret);
        assert!(computed_hash == escrow.hashlock, E_INVALID_SECRET);
        
        // Mark as withdrawn
        escrow.is_withdrawn = true;
        
        // Transfer funds to taker, safety deposit to caller
        let amount = balance::withdraw_all(&mut escrow.amount);
        let safety_deposit = balance::withdraw_all(&mut escrow.safety_deposit);
        
        transfer::public_transfer(coin::from_balance(amount, ctx), escrow.taker);
        transfer::public_transfer(coin::from_balance(safety_deposit, ctx), tx_context::sender(ctx));
        
        // Emit events
        event::emit(EscrowWithdrawal {
            escrow_id: object::id(escrow),
            secret,
            recipient: escrow.taker,
        });
        
        event::emit(SecretRevealed {
            order_hash: escrow.order_hash,
            secret,
            hashlock: escrow.hashlock,
        });
    }

    /// Cancel source escrow (taker only)
    public entry fun cancel_src<T>(
        escrow: &mut SuiEscrowSrc<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        
        // Validate caller is taker
        assert!(sender == escrow.taker, E_UNAUTHORIZED);
        
        // Validate timing - must be after cancellation period
        assert!(current_time >= escrow.timelocks.cancellation_start, E_INVALID_TIME);
        
        // Validate not already processed
        assert!(!escrow.is_withdrawn, E_ALREADY_WITHDRAWN);
        assert!(!escrow.is_cancelled, E_ALREADY_CANCELLED);
        
        // Mark as cancelled
        escrow.is_cancelled = true;
        
        // Refund to maker
        let amount = balance::withdraw_all(&mut escrow.amount);
        let safety_deposit = balance::withdraw_all(&mut escrow.safety_deposit);
        
        transfer::public_transfer(coin::from_balance(amount, ctx), escrow.maker);
        transfer::public_transfer(coin::from_balance(safety_deposit, ctx), sender);
        
        event::emit(EscrowCancelled {
            escrow_id: object::id(escrow),
            refund_recipient: escrow.maker,
        });
    }

    // ========== Destination Escrow Functions ==========

    /// Withdraw from destination escrow (ETH → SUI swap)
    public entry fun withdraw_dst<T>(
        escrow: &mut SuiEscrowDst<T>,
        secret: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        
        // Validate caller is taker
        assert!(sender == escrow.taker, E_UNAUTHORIZED);
        
        // Validate timing
        assert!(current_time >= escrow.timelocks.withdrawal_start, E_INVALID_TIME);
        assert!(current_time < escrow.timelocks.cancellation_start, E_INVALID_TIME);
        
        // Validate not already processed
        assert!(!escrow.is_withdrawn, E_ALREADY_WITHDRAWN);
        assert!(!escrow.is_cancelled, E_ALREADY_CANCELLED);
        
        // Validate secret
        let computed_hash = hash::keccak256(&secret);
        assert!(computed_hash == escrow.hashlock, E_INVALID_SECRET);
        
        // Mark as withdrawn
        escrow.is_withdrawn = true;
        
        // Handle fee distribution
        let total_amount = balance::value(&escrow.amount);
        let protocol_fee = escrow.protocol_fee_amount;
        let integrator_fee = escrow.integrator_fee_amount;
        let maker_amount = total_amount - protocol_fee - integrator_fee;
        
        // Transfer fees
        if (protocol_fee > 0) {
            let fee_balance = balance::split(&mut escrow.amount, protocol_fee);
            transfer::public_transfer(
                coin::from_balance(fee_balance, ctx), 
                escrow.protocol_fee_recipient
            );
        };
        
        if (integrator_fee > 0) {
            let fee_balance = balance::split(&mut escrow.amount, integrator_fee);
            transfer::public_transfer(
                coin::from_balance(fee_balance, ctx), 
                escrow.integrator_fee_recipient
            );
        };
        
        // Transfer remaining amount to maker
        let maker_balance = balance::withdraw_all(&mut escrow.amount);
        transfer::public_transfer(coin::from_balance(maker_balance, ctx), escrow.maker);
        
        // Transfer safety deposit to caller
        let safety_deposit = balance::withdraw_all(&mut escrow.safety_deposit);
        transfer::public_transfer(coin::from_balance(safety_deposit, ctx), sender);
        
        // Emit events
        event::emit(EscrowWithdrawal {
            escrow_id: object::id(escrow),
            secret,
            recipient: escrow.maker,
        });
        
        event::emit(SecretRevealed {
            order_hash: escrow.order_hash,
            secret,
            hashlock: escrow.hashlock,
        });
    }

    /// Public withdraw from destination escrow
    public entry fun public_withdraw_dst<T>(
        escrow: &mut SuiEscrowDst<T>,
        secret: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        
        // Validate timing - must be in public withdrawal period
        assert!(current_time >= escrow.timelocks.public_withdrawal_start, E_INVALID_TIME);
        assert!(current_time < escrow.timelocks.cancellation_start, E_INVALID_TIME);
        
        // Validate not already processed
        assert!(!escrow.is_withdrawn, E_ALREADY_WITHDRAWN);
        assert!(!escrow.is_cancelled, E_ALREADY_CANCELLED);
        
        // Validate secret
        let computed_hash = hash::keccak256(&secret);
        assert!(computed_hash == escrow.hashlock, E_INVALID_SECRET);
        
        // Mark as withdrawn
        escrow.is_withdrawn = true;
        
        // Handle fee distribution (same as private withdrawal)
        let total_amount = balance::value(&escrow.amount);
        let protocol_fee = escrow.protocol_fee_amount;
        let integrator_fee = escrow.integrator_fee_amount;
        
        // Transfer fees
        if (protocol_fee > 0) {
            let fee_balance = balance::split(&mut escrow.amount, protocol_fee);
            transfer::public_transfer(
                coin::from_balance(fee_balance, ctx), 
                escrow.protocol_fee_recipient
            );
        };
        
        if (integrator_fee > 0) {
            let fee_balance = balance::split(&mut escrow.amount, integrator_fee);
            transfer::public_transfer(
                coin::from_balance(fee_balance, ctx), 
                escrow.integrator_fee_recipient
            );
        };
        
        // Transfer remaining amount to maker
        let maker_balance = balance::withdraw_all(&mut escrow.amount);
        transfer::public_transfer(coin::from_balance(maker_balance, ctx), escrow.maker);
        
        // Transfer safety deposit to caller
        let safety_deposit = balance::withdraw_all(&mut escrow.safety_deposit);
        transfer::public_transfer(coin::from_balance(safety_deposit, ctx), tx_context::sender(ctx));
        
        // Emit events
        event::emit(EscrowWithdrawal {
            escrow_id: object::id(escrow),
            secret,
            recipient: escrow.maker,
        });
        
        event::emit(SecretRevealed {
            order_hash: escrow.order_hash,
            secret,
            hashlock: escrow.hashlock,
        });
    }

    /// Cancel destination escrow
    public entry fun cancel_dst<T>(
        escrow: &mut SuiEscrowDst<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        
        // Validate caller is taker
        assert!(sender == escrow.taker, E_UNAUTHORIZED);
        
        // Validate timing - must be after cancellation period
        assert!(current_time >= escrow.timelocks.cancellation_start, E_INVALID_TIME);
        
        // Validate not already processed
        assert!(!escrow.is_withdrawn, E_ALREADY_WITHDRAWN);
        assert!(!escrow.is_cancelled, E_ALREADY_CANCELLED);
        
        // Mark as cancelled
        escrow.is_cancelled = true;
        
        // Refund to taker
        let amount = balance::withdraw_all(&mut escrow.amount);
        let safety_deposit = balance::withdraw_all(&mut escrow.safety_deposit);
        
        transfer::public_transfer(coin::from_balance(amount, ctx), escrow.taker);
        transfer::public_transfer(coin::from_balance(safety_deposit, ctx), sender);
        
        event::emit(EscrowCancelled {
            escrow_id: object::id(escrow),
            refund_recipient: escrow.taker,
        });
    }

    // ========== Emergency Functions ==========

    /// Emergency rescue function (admin only, after rescue delay)
    public entry fun rescue_funds<T>(
        factory: &EscrowFactory,
        escrow_src: &mut SuiEscrowSrc<T>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        let current_time = clock::timestamp_ms(clock);
        
        // Only admin can rescue
        assert!(sender == factory.admin, E_UNAUTHORIZED);
        
        // Must wait for rescue delay
        assert!(
            current_time >= escrow_src.timelocks.deployed_at + factory.rescue_delay, 
            E_INVALID_TIME
        );
        
        // Transfer all funds to admin
        if (balance::value(&escrow_src.amount) > 0) {
            let amount = balance::withdraw_all(&mut escrow_src.amount);
            transfer::public_transfer(coin::from_balance(amount, ctx), sender);
        };
        
        if (balance::value(&escrow_src.safety_deposit) > 0) {
            let deposit = balance::withdraw_all(&mut escrow_src.safety_deposit);
            transfer::public_transfer(coin::from_balance(deposit, ctx), sender);
        };
    }

    // ========== View Functions ==========

    /// Get escrow source information
    public fun get_src_escrow_info<T>(escrow: &SuiEscrowSrc<T>): (
        vector<u8>, // order_hash
        vector<u8>, // hashlock
        address,    // maker
        address,    // taker
        u64,        // amount
        u64,        // safety_deposit
        bool,       // is_withdrawn
        bool        // is_cancelled
    ) {
        (
            escrow.order_hash,
            escrow.hashlock,
            escrow.maker,
            escrow.taker,
            balance::value(&escrow.amount),
            balance::value(&escrow.safety_deposit),
            escrow.is_withdrawn,
            escrow.is_cancelled
        )
    }

    /// Get escrow destination information
    public fun get_dst_escrow_info<T>(escrow: &SuiEscrowDst<T>): (
        vector<u8>, // order_hash
        vector<u8>, // hashlock
        address,    // maker
        address,    // taker
        u64,        // amount
        u64,        // safety_deposit
        bool,       // is_withdrawn
        bool        // is_cancelled
    ) {
        (
            escrow.order_hash,
            escrow.hashlock,
            escrow.maker,
            escrow.taker,
            balance::value(&escrow.amount),
            balance::value(&escrow.safety_deposit),
            escrow.is_withdrawn,
            escrow.is_cancelled
        )
    }

    /// Validate secret against hashlock
    public fun validate_secret(secret: vector<u8>, hashlock: vector<u8>): bool {
        let computed_hash = hash::keccak256(&secret);
        computed_hash == hashlock
    }

    // ========== Test Functions ==========
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}