module fusionplus::escrow_src {
    use 0x1::fusionplus::escrow::{HTLC, SwapFunds, SwapRegistry, HTLCInitiated, HTLCWithdrawn, HTLCRefunded, SwapCompleted};
    use sui::coin::{Coin, self};
    use sui::sui::SUI;
    use sui::clock::Clock;
    use sui::tx_context::TxContext;
    use sui::transfer;
    use sui::balance::{Balance, self};
    use std::hash;

    /// Create and lock funds in source-side HTLC
    public fun initiate_src(
        registry: &mut SwapRegistry,
        swap_id: String,
        participant: address,
        hashed_secret: vector<u8>,
        timelock: u64,
        safety_deposit: u64,
        protocol_fee: u64,
        integrator_fee: u64,
        protocol_recipient: address,
        integrator_recipient: address,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // reuse initiate logic from escrow
        fusionplus::escrow::initiate_htlc_sui(
            registry, swap_id, participant, hashed_secret,
            timelock, safety_deposit, protocol_fee, integrator_fee,
            protocol_recipient, integrator_recipient,
            payment, clock, ctx
        );
    }

    /// Withdraw on source chain by revealing secret
    public fun withdraw_src(
        registry: &mut SwapRegistry,
        htlc: &mut HTLC<SUI>,
        funds: &mut SwapFunds<SUI>,
        secret: vector<u8>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // reuse common withdraw logic
        fusionplus::escrow::withdraw_htlc_sui(
            registry, htlc, funds, secret, clock, ctx
        );
    }

    /// Refund on source chain after expiration
    public fun refund_src(
        registry: &mut SwapRegistry,
        htlc: &mut HTLC<SUI>,
        funds: &mut SwapFunds<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        fusionplus::escrow::refund_htlc_sui(
            registry, htlc, funds, clock, ctx
        );
    }
}
