module suistrat::token {
    use suistrat::treasury::{Treasury,increment_cdt_supply,get_cdt_supply,decrement_cdt_supply};
    use sui::coin::{Self, Coin};
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::coin::TreasuryCap;

    public struct CDT has store, copy, drop {}

    public struct UserStrategy has key, store {
    id: UID,
    owner: address,
    cdt: Coin<CDT>,
}



    public fun mint_cdt(
        treasury: &mut Treasury,
        cap: &mut TreasuryCap<CDT>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<CDT> {
        
        increment_cdt_supply(treasury, amount);
        let cdt_coin = coin::mint<CDT>(cap,amount, ctx);
        cdt_coin
    }


public fun burn_cdt(
    treasury: &mut Treasury,
    cap: &mut TreasuryCap<CDT>,
    coin: Coin<CDT>,
) {
    let amount = coin::value(&coin);
    coin::burn(cap, coin);
    decrement_cdt_supply(treasury, amount);
}
}

