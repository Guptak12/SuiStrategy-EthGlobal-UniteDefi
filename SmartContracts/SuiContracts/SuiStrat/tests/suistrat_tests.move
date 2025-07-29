// module suistrat::suistrat_tests {
//     use sui::test_scenario;
//     use suistrat::treasury::{Self,init_treasury, get_cdt_supply};
//     use suistrat::token::CDT;
//     use sui::coin::{Self, split, value};
//     use sui::tx_context::TxContext;
//     use sui::transfer;
//     use sui::clock::{Self, Clock};
//     use sui::balance::{Self, Balance};

//   #[test]
//     fun test_expired_option_redemption() {
//         let mut scenario = test_scenario::begin(ADMIN);
//         let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        
//         // Setup
//         treasury::init_treasury(test_scenario::ctx(&mut scenario));
//         tokens::init_cdt(test_scenario::ctx(&mut scenario));
//         test_scenario::next_tx(&mut scenario, ADMIN);

//         let mut cdt_cap = test_scenario::take_from_sender<TreasuryCap<CDT>>(&scenario);
//         let mut treasury = test_scenario::take_shared<Treasury>(&scenario);

//         // Create long bond
//         test_scenario::next_tx(&mut scenario, USER1);
//         let sui_payment = coin::mint_for_testing<sui::sui::SUI>(1000, test_scenario::ctx(&mut scenario));
//         let (bond_position, option_nft) = tokens::create_long_bond(
//             &mut treasury,
//             &mut cdt_cap,
//             sui_payment,
//             1200000,
//             3600, // 1 hour expiry
//             &clock,
//             test_scenario::ctx(&mut scenario)
//         );

//         // Fast forward past expiry
//         clock::increment_for_testing(&mut clock, 7200000); // 2 hours

//         // Redeem expired option
//         let cdt_for_redemption = coin::mint_for_testing<CDT>(1000, test_scenario::ctx(&mut scenario));
//         let sui_redeemed = tokens::redeem_expired_option(
//             &mut treasury,
//             &mut cdt_cap,
//             option_nft,
//             cdt_for_redemption,
//             &clock,
//             test_scenario::ctx(&mut scenario)
//         );

//         // Verify redemption
//         assert!(coin::value(&sui_redeemed) == 1000, 0);

//         // Clean up
//         coin::burn_for_testing(sui_redeemed);
//         let LongBondPosition { id, holder: _, cdt_amount: _, sui_deposited: _, created_at: _, has_option_nft: _ } = bond_position;
//         object::delete(id);

//         test_scenario::return_to_sender(&scenario, cdt_cap);
//         test_scenario::return_shared(treasury);
//         clock::destroy_for_testing(clock);
//         test_scenario::end(scenario);
//     }

// }
