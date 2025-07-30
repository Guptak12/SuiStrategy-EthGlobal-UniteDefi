module suistrat::strat {
    use sui::coin;
    // One-time witness for STRAT currency
    public struct STRAT has drop {}

    // Initialize STRAT currency
    fun init(witness: STRAT, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            witness,
            6,
            b"STRAT", 
            b"Strategy Token",
            b"Leveraged SUI exposure token representing equity in the protocol",
            option::none(),
            ctx
        );
        
        transfer::public_freeze_object(metadata);
        // transfer::share_object(&treasury_cap);

        transfer::public_share_object(treasury_cap);
    }
}
