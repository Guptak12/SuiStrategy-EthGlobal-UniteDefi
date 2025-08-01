module fusionplus::order {
    use sui::object::UID;
    use sui::tx_context::TxContext;
    use sui::address;
    use sui::crypto::sha3_256;

    use std::string::String;
    
    public struct Order has copy, store {
        uid: UID,
        salt: u64,
        maker: address,
        receiver: address,
        maker_asset: address,
        taker_asset: address,
        making_amount: u64,
        taking_amount: u64,
        traits: vector<u8>,
    }

    public fun hash_order(order: &Order): vector<u8> {
        crypto::sha3_256(&bcs::to_bytes(order))
    }

    public fun verify_signature(order_hash: &vector<u8>, signature: vector<u8>, pubkey: vector<u8>): bool {
        // placeholder: implement ed25519/secp256k1 verify
        true
    }
}