module suistrat::token {
    use suistrat::treasury::{Treasury,increment_cdt_supply,get_cdt_supply};
    use sui::coin::{Self, Coin};
    use sui::tx_context::TxContext;
    use sui::coin::TreasuryCap;

    public struct CDT has store, copy, drop {}

    public fun mint_cdt(
        treasury: &mut Treasury,
        cap: &mut TreasuryCap<CDT>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<CDT> {
        // Optionally validate mint logic here
        increment_cdt_supply(treasury, amount);
        coin::mint<CDT>(cap,amount, ctx)
    }
}
