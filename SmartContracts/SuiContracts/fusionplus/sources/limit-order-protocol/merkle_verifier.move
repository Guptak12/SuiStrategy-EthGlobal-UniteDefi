module fusionplus::merkle {
    use std::vector;
    
    public fun verify_proof(root: &vector<u8>, leaf: &vector<u8>, proof: &vector<vector<u8>>, index: u64): bool {
        let mut computed = leaf.clone();
        let mut idx = index;
        let mut i = 0;
        while (i < vector::length(proof)) {
            let sibling = vector::borrow(proof, i);
            if (idx & 1 == 0) {
                computed = sha3_256_bytes(&computed.concat(sibling));
            } else {
                computed = sha3_256_bytes(&sibling.concat(&computed));
            }
            idx = idx >> 1;
            i = i + 1;
        }
        &computed == root
    }

    fun sha3_256_bytes(data: &vector<u8>): vector<u8> {
        // call sui::hash::sha3_256
        data.clone()
    }
}
