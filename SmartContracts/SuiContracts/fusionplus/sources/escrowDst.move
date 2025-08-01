module fusionplus::escrow_dst {
    use 0x1::fusionplus::escrow::{HTLC, SwapFunds, SwapRegistry};
    use sui::coin::{Coin, self};
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::tx_context::TxContext;

    /// Destination-side operations mirror source, minus initiation
    public fun withdraw_dst(
        registry: &mut SwapRegistry,
        htlc: &mut HTLC<SUI>,
        funds: &mut SwapFunds<SUI>,
        secret: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // same logic as escrow_src.withdraw_src
        fusionplus::escrow_src::withdraw_src(
            registry, htlc, funds, secret, clock, ctx
        );
    }

    public fun refund_dst(
        registry: &mut SwapRegistry,
        htlc: &mut HTLC<SUI>,
        funds: &mut SwapFunds<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        fusionplus::escrow_src::refund_src(
            registry, htlc, funds, clock, ctx
        );
    }
}
