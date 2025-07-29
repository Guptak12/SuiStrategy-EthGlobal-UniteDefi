#[test_only]
module suistrat::strategy_tests {
    use sui::test_scenario::{Self};
    use sui::clock::{Self, };
    use sui::coin::{Self, TreasuryCap};
    use suistrat::treasury::{Self, Treasury};
    use suistrat::tokens::{Self, STRAT, CDT, OptionNFT, LongBondPosition};

    const ADMIN: address = @0x123;
    const USER1: address = @0x456;
    const USER2: address = @0x789;

    #[test]
    fun test_complete_protocol_flow() {
        let mut scenario = test_scenario::begin(ADMIN);
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        
        // Initialize treasury and tokens
        {
            treasury::init_treasury(test_scenario::ctx(&mut scenario));
            tokens::init_strat(test_scenario::ctx(&mut scenario));
            tokens::init_cdt(test_scenario::ctx(&mut scenario));
        };
        
        test_scenario::next_tx(&mut scenario, ADMIN);

        // Get treasury caps
        let mut strat_cap = test_scenario::take_from_sender<TreasuryCap<STRAT>>(&scenario);
        let mut cdt_cap = test_scenario::take_from_sender<TreasuryCap<CDT>>(&scenario);
        let mut treasury = test_scenario::take_shared<Treasury>(&scenario);

        // USER1 creates long bond (deposits 1000 SUI)
        test_scenario::next_tx(&mut scenario, USER1);
        let sui_payment = coin::mint_for_testing<sui::sui::SUI>(1000, test_scenario::ctx(&mut scenario));
        let (bond_position, option_nft) = tokens::create_long_bond(
            &mut treasury,
            sui_payment,
            1200000, // Strike price: 1.2 STRAT per CDT
            31536000, // 1 year expiry
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Transfer assets to USER1
        transfer::public_transfer(bond_position, USER1);
        transfer::public_transfer(option_nft, USER1);

        // Check treasury expanded
        let (treasury_balance, total_cdt, total_strat, _) = treasury::get_protocol_stats(&treasury);
        assert!(treasury_balance == 1000, 0);
        assert!(total_cdt == 1000, 1);
        assert!(total_strat == 0, 2);

        // USER2 creates short bond (exchanges CDT for STRAT)
        test_scenario::next_tx(&mut scenario, USER2);
        let cdt_for_short = coin::mint(&mut cdt_cap, 500, test_scenario::ctx(&mut scenario));
        let strat_coin = tokens::create_short_bond(
            &mut treasury,
            &mut strat_cap,
            &mut cdt_cap,
            cdt_for_short,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Check protocol state after short bond
        let (_, total_cdt_after, total_strat_after, _) = treasury::get_protocol_stats(&treasury);
        assert!(total_cdt_after == 500, 3); // Reduced by 500
        assert!(total_strat_after == 500, 4); // Increased by 500

        // Simulate time passage and yield accrual (1 year)
        clock::increment_for_testing(&mut clock, 31536000000); // 1 year in milliseconds
        
        // Trigger yield accrual by calling accrue_yield
        treasury::accrue_yield(&mut treasury, &clock);

        // USER1 exercises option (before expiry)
        test_scenario::next_tx(&mut scenario, USER1);
        let bond_position = test_scenario::take_from_sender<LongBondPosition>(&scenario);
        let option_nft = test_scenario::take_from_sender<OptionNFT>(&scenario);
        
        let cdt_for_exercise = coin::mint(&mut cdt_cap, 1000, test_scenario::ctx(&mut scenario));
        let strat_from_option = tokens::exercise_option(
            &mut treasury,
            &mut strat_cap,
            &mut cdt_cap,
            option_nft,
            cdt_for_exercise,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Verify option exercise worked
        let strat_value = coin::value(&strat_from_option);
        assert!(strat_value > 0, 5);

        // Clean up
        coin::burn(&mut strat_cap, strat_coin);
        coin::burn(&mut strat_cap, strat_from_option);
        
        // Destroy position
        tokens::destroy_bond_position_for_testing(bond_position);

        test_scenario::return_to_sender(&scenario, strat_cap);
        test_scenario::return_to_sender(&scenario, cdt_cap);
        test_scenario::return_shared(treasury);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_expired_option_redemption() {
        let mut scenario = test_scenario::begin(ADMIN);
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        
        // Setup
        treasury::init_treasury(test_scenario::ctx(&mut scenario));
        tokens::init_cdt(test_scenario::ctx(&mut scenario));
        
        test_scenario::next_tx(&mut scenario, ADMIN);

        let mut cdt_cap = test_scenario::take_from_sender<TreasuryCap<CDT>>(&scenario);
        let mut treasury = test_scenario::take_shared<Treasury>(&scenario);

        // Create long bond
        test_scenario::next_tx(&mut scenario, USER1);
        let sui_payment = coin::mint_for_testing<sui::sui::SUI>(1000, test_scenario::ctx(&mut scenario));
        let (bond_position, option_nft) = tokens::create_long_bond(
            &mut treasury,
            sui_payment,
            1200000,
            3600, // 1 hour expiry
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Transfer assets to USER1
        transfer::public_transfer(bond_position, USER1);
        transfer::public_transfer(option_nft, USER1);

        // Fast forward past expiry (2 hours in milliseconds)
        clock::increment_for_testing(&mut clock, 7200000);

        // Get the transferred assets back
        test_scenario::next_tx(&mut scenario, USER1);
        let bond_position = test_scenario::take_from_sender<LongBondPosition>(&scenario);
        let option_nft = test_scenario::take_from_sender<OptionNFT>(&scenario);

        // Redeem expired option
        let cdt_for_redemption = coin::mint(&mut cdt_cap, 1000, test_scenario::ctx(&mut scenario));
        let sui_redeemed = tokens::redeem_expired_option(
            &mut treasury,
            &mut cdt_cap,
            option_nft,
            cdt_for_redemption,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // Verify redemption
        assert!(coin::value(&sui_redeemed) == 1000, 0);

        // Clean up
        coin::burn_for_testing(sui_redeemed);
        tokens::destroy_bond_position_for_testing(bond_position);

        test_scenario::return_to_sender(&scenario, cdt_cap);
        test_scenario::return_shared(treasury);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_yield_accrual() {
        let mut scenario = test_scenario::begin(ADMIN);
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        
        // Initialize treasury
        treasury::init_treasury(test_scenario::ctx(&mut scenario));
        test_scenario::next_tx(&mut scenario, ADMIN);
        
        let mut treasury = test_scenario::take_shared<Treasury>(&scenario);

        // Add initial balance to treasury
        let sui_payment = coin::mint_for_testing<sui::sui::SUI>(1000, test_scenario::ctx(&mut scenario));
        treasury::expand_treasury(&mut treasury, sui_payment, 1000, &clock, test_scenario::ctx(&mut scenario));

        // Check initial state
        let initial_yield = treasury::get_total_yield(&treasury);
        assert!(initial_yield == 0, 0);

        // Fast forward 1 year
        clock::increment_for_testing(&mut clock, 31536000000);
        
        // Trigger yield accrual
        treasury::accrue_yield(&mut treasury, &clock);

        // Check yield was accrued (5% of 1000 = 50)
        let final_yield = treasury::get_total_yield(&treasury);
        assert!(final_yield > 0, 1);
        
        // The exact amount depends on the growth rate calculation
        // With 5% annual rate (500 basis points), we expect around 50 yield
        assert!(final_yield >= 40 && final_yield <= 60, 2);

        test_scenario::return_shared(treasury);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }

    #[test]
    fun test_nav_calculation() {
        let mut scenario = test_scenario::begin(ADMIN);
        let mut clock = clock::create_for_testing(test_scenario::ctx(&mut scenario));
        
        // Setup
        treasury::init_treasury(test_scenario::ctx(&mut scenario));
        tokens::init_strat(test_scenario::ctx(&mut scenario));
        tokens::init_cdt(test_scenario::ctx(&mut scenario));
        
        test_scenario::next_tx(&mut scenario, ADMIN);

        let mut strat_cap = test_scenario::take_from_sender<TreasuryCap<STRAT>>(&scenario);
        let mut cdt_cap = test_scenario::take_from_sender<TreasuryCap<CDT>>(&scenario);
        let mut treasury = test_scenario::take_shared<Treasury>(&scenario);

        // Initial NAV should be 0 (no STRAT issued)
        let initial_nav = treasury::get_nav_per_strat(&treasury);
        assert!(initial_nav == 0, 0);

        // Add some treasury balance and issue STRAT
        let sui_payment = coin::mint_for_testing<sui::sui::SUI>(1000, test_scenario::ctx(&mut scenario));
        treasury::expand_treasury(&mut treasury, sui_payment, 1000, &clock, test_scenario::ctx(&mut scenario));

        // Create short bond to issue STRAT
        test_scenario::next_tx(&mut scenario, USER1);
        let cdt_for_short = coin::mint(&mut cdt_cap, 500, test_scenario::ctx(&mut scenario));
        let strat_coin = tokens::create_short_bond(
            &mut treasury,
            &mut strat_cap,
            &mut cdt_cap,
            cdt_for_short,
            &clock,
            test_scenario::ctx(&mut scenario)
        );

        // NAV should be treasury_balance / total_strat_issued = 1000 / 500 = 2
        let nav = treasury::get_nav_per_strat(&treasury);
        assert!(nav == 2, 1);

        // Clean up
        coin::burn(&mut strat_cap, strat_coin);
        test_scenario::return_to_sender(&scenario, strat_cap);
        test_scenario::return_to_sender(&scenario, cdt_cap);
        test_scenario::return_shared(treasury);
        clock::destroy_for_testing(clock);
        test_scenario::end(scenario);
    }
}