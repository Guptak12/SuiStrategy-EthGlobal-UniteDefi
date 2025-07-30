module suistrat::tokens {
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::sui::SUI;
    use suistrat::treasury::{Self, Treasury};
    use suistrat::cdt::CDT;
    use suistrat::strat::STRAT;

    // Token types are imported from their respective modules

    public struct OptionNFT has key, store {
        id: UID,
        strike_price: u64,
        expiry: u64,
        activation_time: u64,
        original_cdt_amount: u64,
        holder: address,
    }

    public struct LongBondPosition has key, store {
        id: UID,
        holder: address,
        cdt_amount: u64,
        sui_deposited: u64,
        created_at: u64,
        has_option_nft: bool,
    }

    // User strategy position
    public struct LongBondCreated has copy, drop {
        user: address,
        sui_amount: u64,
        cdt_amount: u64,
        option_id: address,
        timestamp: u64,
    }

    public struct ShortBondCreated has copy, drop {
        user: address,
        cdt_burned: u64,
        strat_received: u64,
        timestamp: u64,
    }

    public struct OptionExercised has copy, drop {
        user: address,
        option_id: address,
        cdt_amount: u64,
        strat_received: u64,
        timestamp: u64,
    }

    public struct OptionExpired has copy, drop {
        user: address,
        option_id: address,
        cdt_amount: u64,
        sui_received: u64,
        timestamp: u64,
    }

    public entry fun create_long_bond(treasury: &mut Treasury,
    cdt_cap: &mut TreasuryCap<CDT>,
        sui_payment: Coin<SUI>,
        strike_price: u64,
        expiry_duration: u64,
        clock: &Clock,
        ctx: &mut TxContext) {
            let sui_amount = coin::value(&sui_payment);
        let user = tx_context::sender(ctx);
        let timestamp = clock::timestamp_ms(clock) / 1000;

        let cdt_amount = sui_amount;
        // let cdt_cap = coin::treasury_cap<CDT>();
        // let strat_cap = coin::treasury_cap<STRAT>();

        treasury::expand_treasury(treasury, sui_payment, cdt_amount, clock, ctx);

        let option_nft = OptionNFT {
            id: object::new(ctx),
            strike_price,
            expiry: timestamp + expiry_duration,
            activation_time: timestamp, // Immediately exercisable (American option)
            original_cdt_amount: cdt_amount,
            holder: user,
        };

        let option_id = object::uid_to_address(&option_nft.id);

        let position = LongBondPosition {
            id: object::new(ctx),
            holder: user,
            cdt_amount,
            sui_deposited: sui_amount,
            created_at: timestamp,
            has_option_nft: true,
        };

        event::emit(LongBondCreated {
            user,
            sui_amount,
            cdt_amount,
            option_id,
            timestamp,
        });
        let cdt_coin = coin::mint<CDT>(cdt_cap, cdt_amount, ctx);
        transfer::public_transfer(cdt_coin, user);


        transfer::transfer(option_nft, user);
        transfer::transfer(position, user)
    }



    public entry fun create_short_bond(
        treasury: &mut Treasury,
        cdt_cap: &mut TreasuryCap<CDT>,
    strat_cap: &mut TreasuryCap<STRAT>,
        cdt_payment: Coin<CDT>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let cdt_amount = coin::value(&cdt_payment);
        let user = tx_context::sender(ctx);
        let timestamp = clock::timestamp_ms(clock) / 1000;
        // let cdt_cap = coin::treasury_cap<CDT>();
        // let strat_cap = coin::treasury_cap<STRAT>();
        // Burn CDT
        coin::burn(cdt_cap, cdt_payment);

        // Calculate STRAT to issue (market rate based on treasury NAV)
        let treasury_balance = treasury::get_treasury_balance(treasury);
        let total_strat = treasury::get_total_strat_issued(treasury);
        
        // Simple pricing: STRAT amount based on current NAV
        let strat_amount = if (total_strat == 0) {
            cdt_amount // Bootstrap case
        } else {
            (cdt_amount * total_strat) / treasury_balance
        };

        treasury::reduce_debt(treasury, cdt_amount, strat_amount, clock, ctx);
        let strat_coin = coin::mint(strat_cap, strat_amount, ctx);

        event::emit(ShortBondCreated {
            user,
            cdt_burned: cdt_amount,
            strat_received: strat_amount,
            timestamp,
        });

        transfer::public_transfer(strat_coin, user);
    }

     public entry fun exercise_option(
        treasury: &mut Treasury,
        cdt_cap: &mut TreasuryCap<CDT>,
    strat_cap: &mut TreasuryCap<STRAT>,
        option_nft: OptionNFT,
        cdt_payment: Coin<CDT>,
        clock: &Clock,
        ctx: &mut TxContext
    ){
        let current_time = clock::timestamp_ms(clock) / 1000;
        let user = tx_context::sender(ctx);
        // let cdt_cap = coin::treasury_cap<CDT>();
        // let strat_cap = coin::treasury_cap<STRAT>();

        // Verify option is valid and not expired
        assert!(option_nft.holder == user, 1);
        assert!(current_time <= option_nft.expiry, 2);
        assert!(current_time >= option_nft.activation_time, 3);
        
        let cdt_amount = coin::value(&cdt_payment);
        assert!(cdt_amount >= option_nft.original_cdt_amount, 4);

        // Burn CDT
        coin::burn(cdt_cap, cdt_payment);

        // Calculate STRAT based on strike price
        let strat_amount = (option_nft.original_cdt_amount * option_nft.strike_price) / 1000000; // Assuming 6 decimal precision

        // Process conversion
        let sui_coin = treasury::process_conversion(treasury, cdt_amount, 0, strat_amount, clock, ctx);
        coin::destroy_zero(sui_coin);
        let strat_coin = coin::mint(strat_cap, strat_amount, ctx);

        let option_id = object::uid_to_address(&option_nft.id);
        event::emit(OptionExercised {
            user,
            option_id,
            cdt_amount: option_nft.original_cdt_amount,
            strat_received: strat_amount,
            timestamp: current_time,
        });

        // Destroy option NFT
        let OptionNFT { id, strike_price: _, expiry: _, activation_time: _, original_cdt_amount: _, holder: _ } = option_nft;
        object::delete(id);

        transfer::public_transfer(strat_coin, user);

    }


   public entry fun redeem_expired_option(
        treasury: &mut Treasury,
        cdt_cap: &mut TreasuryCap<CDT>,
        option_nft: OptionNFT,
        cdt_payment: Coin<CDT>,
        clock: &Clock,
        ctx: &mut TxContext
    ){
        let current_time = clock::timestamp_ms(clock) / 1000;
        let user = tx_context::sender(ctx);
        // let cdt_cap = coin::treasury_cap<CDT>();

        // Verify option is expired
        assert!(option_nft.holder == user, 1);
        assert!(current_time > option_nft.expiry, 2);
        
        let cdt_amount = coin::value(&cdt_payment);
        assert!(cdt_amount >= option_nft.original_cdt_amount, 3);

        // Burn CDT
        coin::burn(cdt_cap, cdt_payment);

        // Calculate SUI redemption value (original USD value)
        let sui_amount = option_nft.original_cdt_amount; // 1:1 redemption

        // Process conversion and get SUI
        let sui_coin = treasury::process_conversion(treasury, cdt_amount, 1, sui_amount, clock, ctx);
        

        let option_id = object::uid_to_address(&option_nft.id);
        event::emit(OptionExpired {
            user,
            option_id,
            cdt_amount: option_nft.original_cdt_amount,
            sui_received: sui_amount,
            timestamp: current_time,
        });

        // Destroy option NFT
        let OptionNFT { id, strike_price: _, expiry: _, activation_time: _, original_cdt_amount: _, holder: _ } = option_nft;
        object::delete(id);

                transfer::public_transfer(sui_coin, user);

    }

    // View functions
    public fun get_option_info(option: &OptionNFT): (u64, u64, u64, u64, address) {
        (option.strike_price, option.expiry, option.activation_time, option.original_cdt_amount, option.holder)
    }

    public fun get_bond_position_info(position: &LongBondPosition): (address, u64, u64, u64, bool) {
        (position.holder, position.cdt_amount, position.sui_deposited, position.created_at, position.has_option_nft)
    }

    public fun is_option_exercisable(option: &OptionNFT, clock: &Clock): bool {
        let current_time = clock::timestamp_ms(clock) / 1000;
        current_time >= option.activation_time && current_time <= option.expiry
    }

    public fun is_option_expired(option: &OptionNFT, clock: &Clock): bool {
        let current_time = clock::timestamp_ms(clock) / 1000;
        current_time > option.expiry
    }

     #[test_only]
    public fun destroy_bond_position_for_testing(position: LongBondPosition) {
        let LongBondPosition { 
            id, 
            holder: _, 
            cdt_amount: _, 
            sui_deposited: _, 
            created_at: _, 
            has_option_nft: _ 
        } = position;
        object::delete(id);
    }
}