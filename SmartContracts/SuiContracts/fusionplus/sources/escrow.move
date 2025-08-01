// escrow.move
address 0x1 {
module fusionplus::escrow {
    use sui::coin::{Coin, self};
    use sui::sui::SUI;
    use sui::event;
    use sui::clock::Clock;
    use sui::object::{UID, ID};
    use sui::tx_context::{TxContext, self};
    use sui::transfer;
    use sui::balance::{Balance, self};
    use std::vector;
    use std::string::String;
    use std::hash;

    // Error codes
    const EInvalidTimelock: u64 = 1;
    const ENotParticipant: u64 = 2;
    const ETimelockExpired: u64 = 3;
    const EAlreadyCompleted: u64 = 4;
    const EInvalidSecret: u64 = 5;
    const ENotInitiator: u64 = 6;
    const ETimelockNotExpired: u64 = 7;
    const EInsufficientBalance: u64 = 8;
    const ESwapNotFound: u64 = 9;

    /// Main HTLC structure holding swap details and fees
    public struct HTLC<T> has key, store {
        id: UID,
        swap_id: String,
        initiator: address,
        participant: address,
        hashed_secret: vector<u8>,
        timelock: u64,
        safety_deposit: u64,
        protocol_fee: u64,
        integrator_fee: u64,
        protocol_recipient: address,
        integrator_recipient: address,
        withdrawn: bool,
        refunded: bool,
        created_at: u64,
    }

    /// Holds the actual funds for the swap
    public struct SwapFunds<phantom T> has key, store {
        id: UID,
        htlc_id: ID,
        balance: Balance<T>,
    }

    /// Registry to track all swaps
    public struct SwapRegistry has key {
        id: UID,
        swaps: vector<ID>,
        total_swaps: u64,
        active_swaps: u64,
    }

    // Events
    public struct HTLCInitiated has copy, drop {
        swap_id: String,
        htlc_id: ID,
        initiator: address,
        participant: address,
        amount: u64,
        safety_deposit: u64,
        protocol_fee: u64,
        integrator_fee: u64,
        hashed_secret: vector<u8>,
        timelock: u64,
        timestamp: u64,
    }

    public struct HTLCWithdrawn has copy, drop {
        swap_id: String,
        htlc_id: ID,
        participant: address,
        secret: vector<u8>,
        amount: u64,
        timestamp: u64,
    }

    public struct HTLCRefunded has copy, drop {
        swap_id: String,
        htlc_id: ID,
        initiator: address,
        amount: u64,
        timestamp: u64,
    }

    public struct SwapCompleted has copy, drop {
        swap_id: String,
        success: bool,
        timestamp: u64,
    }

    /// Initialize the registry
    public fun init_registry(ctx: &mut TxContext) {
        let registry = SwapRegistry {
            id: object::new(ctx),
            swaps: vector::empty(),
            total_swaps: 0,
            active_swaps: 0,
        };
        transfer::share_object(registry);
    }
}
}