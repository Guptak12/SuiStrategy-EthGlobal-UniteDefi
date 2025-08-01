module fusionplus::timelocks {
    use sui::clock::Clock;

    /// Simple timelock helper: returns deadline = deployed_at + offset
    public fun compute_deadline(deployed_at: u64, offset: u64): u64 {
        deployed_at + offset
    }
}