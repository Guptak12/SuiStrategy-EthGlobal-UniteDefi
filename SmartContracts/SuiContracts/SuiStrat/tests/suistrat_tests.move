module suistrat::suistrat_tests {
    use sui::test_scenario;
    use suistrat::treasury::{Self,init_treasury, get_cdt_supply};
    use suistrat::token::{mint_cdt, burn_cdt, CDT};
    use sui::coin::{Self, split, value};

    #[test_only]
    fun test_mint_and_burn() {
        let mut scenario = test_scenario::begin(@0x1);
        let mut cap = {
            let ctx = test_scenario::ctx(&mut scenario);

            init_treasury(ctx);

            coin::create_treasury_cap_for_testing<CDT>(ctx)
        };

        test_scenario::next_tx(&mut scenario, @0x1);
        let mut treasury = test_scenario::take_shared<treasury::Treasury>(&scenario);
        let cdt_coin = mint_cdt(&mut treasury, &mut cap, 100, test_scenario::ctx(&mut scenario));
        assert!(value<CDT>(&cdt_coin) == 100);

        let supply = get_cdt_supply(&treasury);
        assert!(supply == 100);

        let mut cdt_coin_mut = cdt_coin;
        let burn_part = split(&mut cdt_coin_mut, 40, test_scenario::ctx(&mut scenario));
        burn_cdt(&mut treasury, &mut cap, burn_part);

        let new_supply = get_cdt_supply(&treasury);
        assert!(new_supply == 60);

        transfer::public_transfer(cdt_coin_mut, tx_context::sender(test_scenario::ctx(&mut scenario)));
        test_scenario::return_to_sender(&scenario,cap);
        test_scenario::return_to_sender(&scenario, treasury);
        
        test_scenario::end(scenario);
    }
}
