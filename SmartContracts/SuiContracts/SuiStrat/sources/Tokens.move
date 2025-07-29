module suistrat::token {
    use sui::object::{Self, UID};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::event;
    use sui::sui::SUI;
    use std::option::{Self, Option};
    use suistrat::treasury::{Self, Treasury};

    // Token struct
    public struct CDT has store,copy,drop {}

    public struct STRAT has store,copy,drop {}

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


  

 
    public entry fun init_cdt(ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            CDT {},
            6, 
            b"CDT",
            b"Convertible Debt Token",
            b"A token representing protocol liabilities",
            option::none(),
            ctx
        );
        
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    public entry fun init_strat(ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            STRAT {},
            6,
            b"STRAT",
            b"Strategy Token",
            b"Leveraged SUI exposure token representing equity in the protocol",
            option::none(),
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    public fun create_long_bond(treasury: &mut Treasury,
        cdt_cap: &mut TreasuryCap<CDT>,
        sui_payment: Coin<SUI>,
        strike_price: u64,
        expiry_duration: u64,
        clock: &Clock,
        ctx: &mut TxContext): (LongBondPosition, OptionNFT) {
            let sui_amount = coin::value(&sui_payment);
        let user = tx_context::sender(ctx);
        let timestamp = clock::timestamp_ms(clock) / 1000;

        let cdt_amount = sui_amount;

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

        (position, option_nft)
    }



    // Create a new strategy position by depositing SUI
    // public fun create_strategy(
    //     treasury: &mut Treasury,
    //     cap: &mut TreasuryCap<CDT>,
    //     payment: Coin<SUI>,
    //     clock: &Clock,
    //     ctx: &mut TxContext
    // ): UserStrategy {
    //     let sui_amount = coin::value(&payment);
    //     let user = tx_context::sender(ctx);
    //     let timestamp = clock::timestamp_ms(clock) / 1000;

    //     // Deposit SUI to treasury
    //     treasury::deposit_sui(treasury, payment, clock, ctx);

    //     // Mint CDT tokens (1:1 ratio for simplicity)
    //     let cdt_amount = sui_amount;
    //     treasury::increment_cdt_supply(treasury, cdt_amount);
    //     let _cdt_coin = coin::mint<CDT>(cap, cdt_amount, ctx);
    //     transfer::public_transfer(_cdt_coin, tx_context::sender(ctx));

    //     // Create user strategy position
    //     let strategy = UserStrategy {
    //         id: object::new(ctx),
    //         owner: user,
    //         cdt_amount,
    //         sui_deposited: sui_amount,
    //         created_at: timestamp,
    //     };

    //     event::emit(StrategyCreated {
    //         user,
    //         cdt_amount,
    //         sui_amount,
    //         timestamp,
    //     });

    //     strategy
    // }

    // Redeem strategy position
    // public fun redeem_strategy(
    //     treasury: &mut Treasury,
    //     cap: &mut TreasuryCap<CDT>,
    //     strategy: UserStrategy,
    //     clock: &Clock,
    //     ctx: &mut TxContext
    // ): Coin<SUI> {
    //     // Accrue yield first
    //     treasury::accrue_yield(treasury, clock);

    //     let UserStrategy { 
    //         id, 
    //         owner, 
    //         cdt_amount, 
    //         sui_deposited,
    //         created_at: _
    //     } = strategy;

    //     assert!(owner == tx_context::sender(ctx), 0);

    //     // Calculate redemption value based on current treasury value
    //     let total_cdt_supply = treasury::get_cdt_supply(treasury);
    //     let treasury_balance = treasury::get_balance(treasury);
        
    //     let redemption_value = if (total_cdt_supply > 0) {
    //         (cdt_amount * treasury_balance) / total_cdt_supply
    //     } else {
    //         0
    //     };

    //     // Create CDT coin to burn
    //     let cdt_to_burn = coin::mint<CDT>(cap, cdt_amount, ctx);
        
    //     // Burn CDT and get SUI
    //     coin::burn(cap, cdt_to_burn);
    //     treasury::decrement_cdt_supply(treasury, cdt_amount);
        
    //     let sui_coin = treasury::withdraw_sui(treasury, redemption_value, clock, ctx);
        
    //     let profit = if (redemption_value > sui_deposited) {
    //         redemption_value - sui_deposited
    //     } else {
    //         0
    //     };

    //     let timestamp = clock::timestamp_ms(clock) / 1000;
    //     event::emit(StrategyRedeemed {
    //         user: owner,
    //         cdt_burned: cdt_amount,
    //         sui_received: redemption_value,
    //         profit,
    //         timestamp,
    //     });

    //     object::delete(id);
    //     sui_coin
    // }

    // View functions
    public fun get_strategy_info(strategy: &UserStrategy): (address, u64, u64, u64) {
        (strategy.owner, strategy.cdt_amount, strategy.sui_deposited, strategy.created_at)
    }

    // Calculate current strategy value
    public fun calculate_strategy_value(
        strategy: &UserStrategy,
        treasury: &Treasury,
        clock: &Clock
    ): u64 {
        let total_cdt_supply = treasury::get_cdt_supply(treasury);
        if (total_cdt_supply == 0) return 0;
        
        let current_treasury_value = treasury::get_current_value(treasury, clock);
        (strategy.cdt_amount * current_treasury_value) / total_cdt_supply
    }



    public entry fun create_cdt(): CDT {
    CDT {}
}

}
