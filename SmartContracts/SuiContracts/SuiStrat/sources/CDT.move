module suistrat::cdt {
    use sui::coin;
    // One-time witness for CDT currency
    public struct CDT has drop {}

    // Initialize CDT currency
    fun init(witness: CDT, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            6, 
            b"CDT",
            b"Convertible Debt Token",
            b"A token representing protocol liabilities",
            option::none(),
            ctx
        );
        
        transfer::public_freeze_object(metadata);
        // transfer::share_object(&treasury_cap);

        transfer::public_share_object(treasury_cap);

    }
}
