module fusionplus::settlement {
    use sui::coin::{Coin, self};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::event;
    use 0x1::fusionplus::order::{Order, hash_order, verify_signature};
    use 0x1::fusionplus::merkle::{verify_proof};
    use 0x1::fusionplus::escrow_src::{initiate_src};
    
    public fun settle_and_initiate(
        order: Order,
        signature: vector<u8>,
        pubkey: vector<u8>,
        proof_root: vector<u8>,
        proof: vector<vector<u8>>,
        leaf_hash: vector<u8>,
        leaf_index: u64,
        extra: vector<u8>,
        registry: &mut 0x1::fusionplus::escrow::SwapRegistry,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let order_hash = hash_order(&order);
        assert!(verify_signature(&order_hash, signature, pubkey), 100);
        assert!(verify_proof(&proof_root, &leaf_hash, &proof, leaf_index), 101);
        // decode extra for htlc params: swap_id, participant, timelock, fees, recipients
        initiate_src(registry, /*... decode extra ...*/ payment, &Clock::now(), ctx);
        event::emit(SettlementInitiated { order_hash, swap_id: extra })
    }
    public struct SettlementInitiated has copy, drop {
        order_hash: vector<u8>,
        swap_id: vector<u8>,
    }
}
