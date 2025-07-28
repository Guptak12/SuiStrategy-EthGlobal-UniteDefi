// module suistrat::suistrat_tests {
//     use sui::test_scenario;
//     use suistrat::treasury::{Self,init_treasury, get_cdt_supply};
//     use suistrat::token::CDT;
//     use sui::coin::{Self, split, value};
//     use sui::tx_context::TxContext;
//     use sui::transfer;
//     use sui::clock::{Self, Clock};
//     use sui::balance::{Self, Balance};

//     // #[test_only]
//     // fun test_mint_and_burn() {
//     //     let mut scenario = test_scenario::begin(@0x1);
//     //     let mut cap = {
//     //         let ctx = test_scenario::ctx(&mut scenario);

//     //         init_treasury(ctx);

//     //         coin::create_treasury_cap_for_testing<CDT>(ctx)
//     //     };

//     //     test_scenario::next_tx(&mut scenario, @0x1);
//     //     let mut treasury = test_scenario::take_shared<treasury::Treasury>(&scenario);
//     //     let cdt_coin = mint_cdt(&mut treasury, &mut cap, 100, test_scenario::ctx(&mut scenario));
//     //     assert!(value<CDT>(&cdt_coin) == 100);

//     //     let supply = get_cdt_supply(&treasury);
//     //     assert!(supply == 100);

//     //     let mut cdt_coin_mut = cdt_coin;
//     //     let burn_part = split(&mut cdt_coin_mut, 40, test_scenario::ctx(&mut scenario));
//     //     burn_cdt(&mut treasury, &mut cap, burn_part);

//     //     let new_supply = get_cdt_supply(&treasury);
//     //     assert!(new_supply == 60);

//     //     transfer::public_transfer(cdt_coin_mut, tx_context::sender(test_scenario::ctx(&mut scenario)));
//     //     test_scenario::return_to_sender(&scenario,cap);
//     //     test_scenario::return_to_sender(&scenario, treasury);
        
//     //     test_scenario::end(scenario);
//     // }

//     #[test_only]
// fun simulate_update_treasury_value(treasury: &mut Treasury, clock: &Clock) {
//     let current_balance = balance::value(&treasury.balance);
//     let current_time = clock::timestamp_ms(clock) / 1000;

//     if (treasury.last_update == 0) {
//         treasury.last_update = current_time;
//         return;
//     };

//     let time_elapsed = current_time - treasury.last_update;
//     if (time_elapsed == 0 || current_balance == 0) {
//         treasury.last_update = current_time;
//         return;
//     };

//     let seconds_per_year = 31_536_000u64;
//     let yield_amount = (current_balance * treasury.growth_rate * time_elapsed)
//         / (10000 * seconds_per_year);

//     if (yield_amount > 0) {
//         let fake_sui = test_scenario::create_fake_coin<SUI>(yield_amount);
//         TreasuryBond::update_treasury_value(treasury, option::some(fake_sui), clock);
//     } else {
//         TreasuryBond::update_treasury_value(treasury, option::none<balance::Balance<SUI>>(), clock);
//     }
// }

// }
