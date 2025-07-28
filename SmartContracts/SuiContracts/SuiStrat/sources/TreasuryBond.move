module suistrat::treasury {
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::clock::{Self, Clock};
    use sui::event;

    friend suistrat::token;

      public struct Treasury has key, store {
        id: UID,
        balance: Balance<SUI>,
        cdt_supply: u64,
        growth_rate: u64,
        last_update: u64,
        total_yield_generated: u64,
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


    public entry fun init_treasury(ctx: &mut TxContext) {
        let treasury = Treasury {
            id: object::new(ctx),
            balance: balance::zero<SUI>(),
            cdt_supply: 0,
            growth_rate: 500, // 5% growth
        };
        transfer::share_object(treasury);
    }

    // Returns current CDT supply
public fun get_cdt_supply(treasury: &Treasury): u64 {
    treasury.cdt_supply
}

// Increments CDT supply by amount
public fun increment_cdt_supply(treasury: &mut Treasury, amount: u64) {
    treasury.cdt_supply = treasury.cdt_supply + amount;
}
public fun decrement_cdt_supply(treasury: &mut Treasury, amount: u64) {
    treasury.cdt_supply = treasury.cdt_supply - amount;
}



}