module suistrat::treasury {
    use sui::balance::{Self,Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use suistrat::token::CDT;


    public struct Treasury has key,store {
        id: UID,
        balance: Balance<SUI>,
        cdt_supply: u64,
        growth_rate: u64

    }

    public fun init_treasury(ctx: &mut TxContext) {
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



}