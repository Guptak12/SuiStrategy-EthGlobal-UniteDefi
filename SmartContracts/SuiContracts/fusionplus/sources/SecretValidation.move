module cross_chain_swap::crypto {
    use sui::hash;
    
    public fun validate_secret(secret: vector<u8>, hashlock: vector<u8>): bool {
        hash::keccak256(&secret) == hashlock
    }
}