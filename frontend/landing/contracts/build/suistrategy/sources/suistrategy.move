/// SuiStrategy - Leveraged yield with real treasury value
/// A DeFi protocol that automates yield strategies and enables cross-chain swaps,
/// using bonds, smart automation, and structured products.
module suistrategy::suistrategy {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::object::{ID};
    use sui::sui::SUI;
    use std::option;

    // ======== Errors ========
    const E_INSUFFICIENT_BALANCE: u64 = 1;
    const E_BOND_NOT_MATURED: u64 = 2;
    const E_BOND_EXPIRED: u64 = 3;
    const E_INVALID_AMOUNT: u64 = 4;
    const E_UNAUTHORIZED: u64 = 5;

    // ======== Constants ========
    const BOND_MATURITY_PERIOD: u64 = 30 * 24 * 60 * 60 * 1000; // 30 days in milliseconds
    const BASIS_POINTS: u64 = 10000;

    // ======== Structs ========

    /// One-time witness for module initialization
    public struct SUISTRATEGY has drop {}

    /// Protocol treasury that holds SUI and manages bonding
    public struct Treasury has key {
        id: UID,
        sui_balance: Balance<SUI>,
        total_cdt_supply: u64,
        total_sstr_supply: u64,
        bond_counter: u64,
    }

    /// SSTR Token - Treasury-backed equity token
    public struct SSTR has drop {}

    /// CDT Token - Convertible Debt Token (0% interest)
    public struct CDT has drop {}

    /// Option NFT that represents conversion rights
    public struct OptionNFT has key, store {
        id: UID,
        bond_id: u64,
        cdt_amount: u64,
        created_at: u64,
        maturity_timestamp: u64,
        is_exercised: bool,
    }

    /// Bond position tracking
    public struct BondPosition has key {
        id: UID,
        bond_id: u64,
        depositor: address,
        sui_deposited: u64,
        cdt_minted: u64,
        created_at: u64,
        maturity_timestamp: u64,
        is_redeemed: bool,
    }

    /// Admin capability for protocol management
    public struct AdminCap has key {
        id: UID,
    }

    // ======== Events ========

    public struct BondCreated has copy, drop {
        bond_id: u64,
        depositor: address,
        sui_amount: u64,
        cdt_amount: u64,
        nft_id: ID,
        maturity_timestamp: u64,
    }

    public struct OptionExercised has copy, drop {
        bond_id: u64,
        exerciser: address,
        cdt_burned: u64,
        sstr_minted: u64,
    }

    public struct BondRedeemed has copy, drop {
        bond_id: u64,
        redeemer: address,
        sui_redeemed: u64,
    }

    public struct NAVCalculated has copy, drop {
        treasury_value: u64,
        sstr_supply: u64,
        nav_per_sstr: u64,
        timestamp: u64,
    }

    // ======== Init Function ========

    /// Initialize the protocol with treasury and admin capabilities only
    fun init(_witness: SUISTRATEGY, ctx: &mut TxContext) {
        // Create treasury
        let treasury = Treasury {
            id: object::new(ctx),
            sui_balance: balance::zero(),
            total_cdt_supply: 0,
            total_sstr_supply: 0,
            bond_counter: 0,
        };

        // Create admin capability
        let admin_cap = AdminCap {
            id: object::new(ctx),
        };

        // Transfer objects to sender
        transfer::share_object(treasury);
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }

    /// Initialize SSTR token (admin only)
    public entry fun init_sstr_token(
        _admin: &AdminCap,
        ctx: &mut TxContext
    ) {
        let (sstr_treasury, sstr_metadata) = coin::create_currency<SSTR>(
            SSTR {},
            9, // decimals
            b"SSTR",
            b"SuiStrategy Treasury Token",
            b"Treasury-backed equity token providing leveraged exposure to SUI growth",
            option::none(),
            ctx
        );

        transfer::public_transfer(sstr_treasury, tx_context::sender(ctx));
        transfer::public_transfer(sstr_metadata, tx_context::sender(ctx));
    }

    /// Initialize CDT token (admin only)
    public entry fun init_cdt_token(
        _admin: &AdminCap,
        ctx: &mut TxContext
    ) {
        let (cdt_treasury, cdt_metadata) = coin::create_currency<CDT>(
            CDT {},
            9, // decimals
            b"CDT",
            b"Convertible Debt Token",
            b"0% interest debt token convertible to SSTR",
            option::none(),
            ctx
        );

        transfer::public_transfer(cdt_treasury, tx_context::sender(ctx));
        transfer::public_transfer(cdt_metadata, tx_context::sender(ctx));
    }

    // ======== Public Functions ========

    /// Buy Long Bonds - Deposit SUI to receive CDT + Option NFTs
    public entry fun buy_long_bond(
        treasury: &mut Treasury,
        cdt_treasury: &mut TreasuryCap<CDT>,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let sui_amount = coin::value(&payment);
        assert!(sui_amount > 0, E_INVALID_AMOUNT);

        let current_time = clock::timestamp_ms(clock);
        let maturity_timestamp = current_time + BOND_MATURITY_PERIOD;
        
        // Update bond counter
        treasury.bond_counter = treasury.bond_counter + 1;
        let bond_id = treasury.bond_counter;

        // Add SUI to treasury
        let sui_balance = coin::into_balance(payment);
        balance::join(&mut treasury.sui_balance, sui_balance);

        // Calculate CDT amount (1:1 ratio for now, can be modified for bonding curve)
        let cdt_amount = sui_amount;
        
        // Mint CDT tokens
        let cdt_coin = coin::mint(cdt_treasury, cdt_amount, ctx);
        treasury.total_cdt_supply = treasury.total_cdt_supply + cdt_amount;

        // Create Option NFT
        let option_nft = OptionNFT {
            id: object::new(ctx),
            bond_id,
            cdt_amount,
            created_at: current_time,
            maturity_timestamp,
            is_exercised: false,
        };

        let nft_id = object::id(&option_nft);

        // Create bond position tracking
        let bond_position = BondPosition {
            id: object::new(ctx),
            bond_id,
            depositor: tx_context::sender(ctx),
            sui_deposited: sui_amount,
            cdt_minted: cdt_amount,
            created_at: current_time,
            maturity_timestamp,
            is_redeemed: false,
        };

        // Emit event
        event::emit(BondCreated {
            bond_id,
            depositor: tx_context::sender(ctx),
            sui_amount,
            cdt_amount,
            nft_id,
            maturity_timestamp,
        });

        // Transfer tokens and NFTs to sender
        transfer::public_transfer(cdt_coin, tx_context::sender(ctx));
        transfer::transfer(option_nft, tx_context::sender(ctx));
        transfer::transfer(bond_position, tx_context::sender(ctx));
    }

    /// View NAV / SSTR Value - Calculate Net Asset Value per SSTR token
    public fun calculate_nav(treasury: &Treasury): (u64, u64, u64) {
        let treasury_value = balance::value(&treasury.sui_balance);
        let sstr_supply = treasury.total_sstr_supply;
        
        let nav_per_sstr = if (sstr_supply > 0) {
            (treasury_value * BASIS_POINTS) / sstr_supply
        } else {
            BASIS_POINTS // 1:1 ratio if no SSTR exists
        };

        (treasury_value, sstr_supply, nav_per_sstr)
    }

    /// Exercise SSTR Option (NFT) After Maturity - Convert CDT + NFT to SSTR
    public entry fun exercise_option(
        treasury: &mut Treasury,
        sstr_treasury: &mut TreasuryCap<SSTR>,
        cdt_treasury: &mut TreasuryCap<CDT>,
        option_nft: OptionNFT,
        cdt_payment: Coin<CDT>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        
        // Check if bond has matured
        assert!(current_time >= option_nft.maturity_timestamp, E_BOND_NOT_MATURED);
        assert!(!option_nft.is_exercised, E_UNAUTHORIZED);

        let cdt_amount = coin::value(&cdt_payment);
        assert!(cdt_amount >= option_nft.cdt_amount, E_INSUFFICIENT_BALANCE);

        // Burn CDT tokens
        coin::burn(cdt_treasury, cdt_payment);
        treasury.total_cdt_supply = treasury.total_cdt_supply - option_nft.cdt_amount;

        // Calculate SSTR to mint (could include premium/discount based on NAV)
        let sstr_amount = option_nft.cdt_amount; // 1:1 for simplicity
        
        // Mint SSTR tokens
        let sstr_coin = coin::mint(sstr_treasury, sstr_amount, ctx);
        treasury.total_sstr_supply = treasury.total_sstr_supply + sstr_amount;

        // Emit event
        event::emit(OptionExercised {
            bond_id: option_nft.bond_id,
            exerciser: tx_context::sender(ctx),
            cdt_burned: option_nft.cdt_amount,
            sstr_minted: sstr_amount,
        });

        // Destroy NFT
        let OptionNFT { 
            id, 
            bond_id: _, 
            cdt_amount: _, 
            created_at: _, 
            maturity_timestamp: _, 
            is_exercised: _ 
        } = option_nft;
        object::delete(id);

        // Transfer SSTR to sender
        transfer::public_transfer(sstr_coin, tx_context::sender(ctx));
    }

    /// Redeem Bond If Expired - Get back underlying SUI
    public entry fun redeem_expired_bond(
        treasury: &mut Treasury,
        bond_position: &mut BondPosition,
        option_nft: OptionNFT,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let current_time = clock::timestamp_ms(clock);
        
        // Check if bond has expired (add grace period logic here)
        assert!(current_time > option_nft.maturity_timestamp, E_BOND_EXPIRED);
        assert!(!bond_position.is_redeemed, E_UNAUTHORIZED);
        assert!(bond_position.depositor == tx_context::sender(ctx), E_UNAUTHORIZED);

        // Mark as redeemed
        bond_position.is_redeemed = true;

        // Calculate redemption amount (could include penalties/fees)
        let redemption_amount = bond_position.sui_deposited;
        
        // Withdraw SUI from treasury
        let sui_balance = balance::split(&mut treasury.sui_balance, redemption_amount);
        let sui_coin = coin::from_balance(sui_balance, ctx);

        // Emit event
        event::emit(BondRedeemed {
            bond_id: bond_position.bond_id,
            redeemer: tx_context::sender(ctx),
            sui_redeemed: redemption_amount,
        });

        // Destroy NFT
        let OptionNFT { 
            id, 
            bond_id: _, 
            cdt_amount: _, 
            created_at: _, 
            maturity_timestamp: _, 
            is_exercised: _ 
        } = option_nft;
        object::delete(id);

        // Transfer redeemed SUI to sender
        transfer::public_transfer(sui_coin, tx_context::sender(ctx));
    }

    // ======== View Functions ========

    /// Get treasury information
    public fun get_treasury_info(treasury: &Treasury): (u64, u64, u64, u64) {
        (
            balance::value(&treasury.sui_balance),
            treasury.total_cdt_supply,
            treasury.total_sstr_supply,
            treasury.bond_counter
        )
    }

    /// Get bond position details
    public fun get_bond_position(bond: &BondPosition): (u64, address, u64, u64, u64, u64, bool) {
        (
            bond.bond_id,
            bond.depositor,
            bond.sui_deposited,
            bond.cdt_minted,
            bond.created_at,
            bond.maturity_timestamp,
            bond.is_redeemed
        )
    }

    /// Get option NFT details
    public fun get_option_nft(nft: &OptionNFT): (u64, u64, u64, u64, bool) {
        (
            nft.bond_id,
            nft.cdt_amount,
            nft.created_at,
            nft.maturity_timestamp,
            nft.is_exercised
        )
    }

    // ======== Admin Functions ========

    /// Emergency function to update treasury parameters (admin only)
    public entry fun update_treasury_params(
        _: &AdminCap,
        _treasury: &mut Treasury,
        // Add parameters for treasury management
        _ctx: &mut TxContext
    ) {
        // Treasury management logic
        // This is a placeholder for future treasury operations
        assert!(true, 0); // Placeholder
    }

    // ======== Test Functions ========
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(SUISTRATEGY {}, ctx);
    }
}
