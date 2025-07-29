module suistrat::treasury {
     use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::event;
    use std::option::{Self, Option};

      public struct Treasury has key, store {
        id: UID,
        sui_balance: Balance<SUI>,          
        total_cdt_issued: u64,              
        total_strat_issued: u64,            
        growth_rate: u64,                   
        last_update: u64,                   
        total_yield_generated: u64,         
        protocol_revenue: u64,             
    }
    //Events
 public struct YieldGenerated has copy, drop {
        amount: u64,
        new_balance: u64,
        timestamp: u64,
    }

    public struct Deposited has copy, drop {
        user: address,
        amount: u64,
        timestamp: u64,
    }

    public struct Withdrawn has copy, drop {
        user: address,
        amount: u64,
        timestamp: u64,
    }

    public struct TreasuryExpanded has copy, drop {
        sui_added: u64,
        cdt_issued: u64,
        new_treasury_size: u64,
        timestamp: u64,
    } 



    public struct DeptReducted has copy, drop {
        cdt_burned: u64,
        strat_issued: u64,
        new_debt_level: u64,
        timestamp: u64,
    }


    // Initialize treasury
    public entry fun init_treasury(ctx: &mut TxContext) {
        let treasury = Treasury {
            id: object::new(ctx),
            sui_balance: balance::zero<SUI>(),
            total_cdt_issued: 0,
            growth_rate: 500, // 5% annual growth
            last_update: 0,
            total_yield_generated: 0,
            protocol_revenue: 0,
            total_strat_issued: 0,

        };
        transfer::share_object(treasury);
    }

    // Deposit SUI to treasury
    // public fun deposit_sui(treasury: &mut Treasury, payment: Coin<SUI>, clock: &Clock, ctx: &TxContext) {
    //     let amount = coin::value(&payment);
    //     balance::join(&mut treasury.balance, coin::into_balance(payment));
        
    //     let timestamp = clock::timestamp_ms(clock) / 1000;
    //     if (treasury.last_update == 0) {
    //         treasury.last_update = timestamp;
    //     };

    //     event::emit(Deposited {
    //         user: tx_context::sender(ctx),
    //         amount,
    //         timestamp,
    //     });
    // }

     // Withdraw SUI from treasury (only for burning CDT)
    // public(package) fun withdraw_sui(treasury: &mut Treasury, amount: u64, clock: &Clock, ctx: &mut TxContext): Coin<SUI> {
    //     update_treasury_value(treasury, option::none(),clock);
        
    //     let withdrawal_balance = balance::split(&mut treasury.balance, amount);
    //     let withdrawal_coin = coin::from_balance(withdrawal_balance, ctx);
        
    //     let timestamp = clock::timestamp_ms(clock) / 1000;
    //     event::emit(Withdrawn {
    //         user: tx_context::sender(ctx),
    //         amount,
    //         timestamp,
    //     });

    //     withdrawal_coin
    // }

     public(package) fun expand_treasury(
        treasury: &mut Treasury, 
        sui_payment: Coin<SUI>, 
        cdt_amount: u64,
        clock: &Clock,
        ctx: &TxContext
    ) {
        accrue_yield(treasury, clock);
        
        let sui_amount = coin::value(&sui_payment);
        balance::join(&mut treasury.sui_balance, coin::into_balance(sui_payment));
        
        treasury.total_cdt_issued = treasury.total_cdt_issued + cdt_amount;
        
        let timestamp = clock::timestamp_ms(clock) / 1000;
        event::emit(TreasuryExpanded {
            sui_added: sui_amount,
            cdt_issued: cdt_amount,
            new_treasury_size: balance::value(&treasury.sui_balance),
            timestamp,
        });
    }

     // Update treasury value with constant growth rate
    // fun update_treasury_value(treasury: &mut Treasury, clock: &Clock) {
    //     let current_time = clock::timestamp_ms(clock) / 1000;
        
    //     if (treasury.last_update == 0) {
    //         treasury.last_update = current_time;
    //         return
    //     };

    //     let time_elapsed = current_time - treasury.last_update;
    //     if (time_elapsed == 0) return;

    //     let current_balance = balance::value(&treasury.balance);
    //     if (current_balance == 0) {
    //         treasury.last_update = current_time;
    //         return
    //     };
    //     let seconds_per_year = 31536000u64; // 365 * 24 * 60 * 60
    //     let yield_amount = (current_balance * treasury.growth_rate * time_elapsed) / (10000 * seconds_per_year);

    //     if (yield_amount > 0) {
    //         // Create yield and add to balance
    //         let yield_balance = balance::create_for_testing<SUI>(yield_amount);
    //         balance::join(&mut treasury.balance, yield_balance);
    //         treasury.total_yield_generated = treasury.total_yield_generated + yield_amount;

    //         event::emit(YieldGenerated {
    //             amount: yield_amount,
    //             new_balance: balance::value(&treasury.balance),
    //             timestamp: current_time,
    //         });
    //     };

    //     treasury.last_update = current_time;
    // }

    public fun update_treasury_value(treasury: &mut Treasury, mut yield_balance: Option<balance::Balance<SUI>>, clock: &Clock) {
    let current_time = clock::timestamp_ms(clock) / 1000;

    if (treasury.last_update == 0) {
        treasury.last_update = current_time;
        option::destroy_none(yield_balance);
        return
    };

    let time_elapsed = current_time - treasury.last_update;

    if (time_elapsed == 0) {
        option::destroy_none(yield_balance);
        return
    };

    let current_balance = balance::value(&treasury.balance);
    if (current_balance == 0) {
        treasury.last_update = current_time;
        option::destroy_none(yield_balance);

        return;
    };

    let seconds_per_year = 31_536_000u64;
    let yield_amount = (current_balance * treasury.growth_rate * time_elapsed)
        / (10000 * seconds_per_year);

    if (yield_amount > 0 && option::is_some(&yield_balance)) {
        let yield_b = option::extract(&mut yield_balance);
        balance::join(&mut treasury.balance, yield_b);
        treasury.total_yield_generated = treasury.total_yield_generated + yield_amount;

        event::emit(YieldGenerated {
            amount: yield_amount,
            new_balance: balance::value(&treasury.balance),
            timestamp: current_time,
        });
    };
    option::destroy_none(yield_balance);


    treasury.last_update = current_time;
}

    // Package functions for token module
    public(package) fun increment_cdt_supply(treasury: &mut Treasury, amount: u64) {
        treasury.cdt_supply = treasury.cdt_supply + amount;
    }

    public(package) fun decrement_cdt_supply(treasury: &mut Treasury, amount: u64) {
        treasury.cdt_supply = treasury.cdt_supply - amount;
    }

    // View functions
    public fun get_cdt_supply(treasury: &Treasury): u64 {
        treasury.cdt_supply
    }

    public fun get_balance(treasury: &Treasury): u64 {
        balance::value(&treasury.balance)
    }

    public fun get_growth_rate(treasury: &Treasury): u64 {
        treasury.growth_rate
    }

    public fun get_total_yield(treasury: &Treasury): u64 {
        treasury.total_yield_generated
    }

    // Update growth rate (admin function)
    public fun set_growth_rate(treasury: &mut Treasury, new_rate: u64, _ctx: &TxContext) {
        treasury.growth_rate = new_rate;
    }

    // Manual yield update trigger
    public fun accrue_yield(treasury: &mut Treasury, clock: &Clock) {
        update_treasury_value(treasury, option::none(), clock);
    }

    // Calculate current value with pending yield
    public fun get_current_value(treasury: &Treasury, clock: &Clock): u64 {
        let current_time = clock::timestamp_ms(clock) / 1000;
        let time_elapsed = current_time - treasury.last_update;
        let current_balance = balance::value(&treasury.balance);
        
        if (time_elapsed == 0 || current_balance == 0) {
            return current_balance
        };

        let seconds_per_year = 31536000u64;
        let pending_yield = (current_balance * treasury.growth_rate * time_elapsed) / (10000 * seconds_per_year);
        current_balance + pending_yield
    }


}