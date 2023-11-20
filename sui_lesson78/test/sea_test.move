module hero_game::hero_test {
    use sui::coin;
        use sui::test_scenario;
        use hero_game::hero::{Self, GameInfo, GameAdmin, Hero, Monster};
        use hero_game::sea_hero::{Self, SeaHeroAdmin, SeaMonster};
        use hero_game::sea_hero_helper::{Self, HelpMeSlayThisMonster};

    #[test]
    fun test_slay_monter() {
        use sui::coin;

        let admin = @0xAD014;
        let player = @0xA01C;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            hero::new(test_scenario::ctx(scenario))
        };

         test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let admin_cap: GameAdmin = test_scenario::take_from_sender<GameAdmin>(scenario);

            hero::send_monster(game_ref, &mut admin_cap, 100, 2, player, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_immutable(game);
        };

         test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let admin_cap: GameAdmin = test_scenario::take_from_sender<GameAdmin>(scenario);

            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let monster: Monster = test_scenario::take_from_sender<Monster>(scenario);

            hero::attack(game_ref,&mut hero, monster, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, admin_cap);
            test_scenario::return_to_sender(scenario, hero);
            test_scenario::return_immutable(game);
        };

        test_scenario::end(scenario_val);

    }

     #[test]
    fun test_slay_sea_monter() {
        use sui::coin;

        let admin = @0xAD014;
        let player = @0xA01C;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            sea_hero::new(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, player);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        test_scenario::next_tx(scenario, admin);
        {
            let sea_admin_cap: SeaHeroAdmin = test_scenario::take_from_sender<SeaHeroAdmin>(scenario);

            sea_hero::create_sea_monster(&mut sea_admin_cap, 10, player, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, sea_admin_cap);
        };

         test_scenario::next_tx(scenario, player);
        {
            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let monster: SeaMonster = test_scenario::take_from_sender<SeaMonster>(scenario);

            sea_hero::attack(&hero, monster, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, hero);
        };

        test_scenario::end(scenario_val);
    }


     #[test]
    fun test_hero_helper_slay() {
        use sui::coin;

        let admin = @0xAD014;
        let player1 = @0xA01C;
        let player2 = @0xA02C;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            sea_hero::new(test_scenario::ctx(scenario));
        };

        // create hero 1
        test_scenario::next_tx(scenario, player1);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // create hero 2
        test_scenario::next_tx(scenario, player2);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(800, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // create sea monster
        test_scenario::next_tx(scenario, admin);
        {
            let sea_admin_cap: SeaHeroAdmin = test_scenario::take_from_sender<SeaHeroAdmin>(scenario);

            sea_hero::create_sea_monster(&mut sea_admin_cap, 10, player1, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, sea_admin_cap);
        };

        // hero 1 create help
        test_scenario::next_tx(scenario, player1);
        {
            let monster: SeaMonster = test_scenario::take_from_sender<SeaMonster>(scenario);

            sea_hero_helper::create_help(monster, 15, player2, test_scenario::ctx(scenario));
        };

        // hero 2 attack sea monster
        test_scenario::next_tx(scenario, player2);
        {
            let hero: Hero = test_scenario::take_from_sender<Hero>(scenario);
            let wrapper: HelpMeSlayThisMonster = test_scenario::take_from_sender<HelpMeSlayThisMonster>(scenario);

            sea_hero_helper::attack(&hero, wrapper, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, hero);
        };

        test_scenario::end(scenario_val);
    }

     #[test]
    fun test_hero_attack_hero() {
        use sui::coin;

        let admin = @0xAD014;
        let player1 = @0xA01C;
        let player2 = @0xA02C;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            sea_hero::new(test_scenario::ctx(scenario));
        };

        // create hero 1
        test_scenario::next_tx(scenario, player1);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(1000, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };
        // create hero 2
        test_scenario::next_tx(scenario, player2);
        {
            let game: GameInfo = test_scenario::take_immutable<GameInfo>(scenario);
            let game_ref: &GameInfo = &game;
            let coin = coin::mint_for_testing(800, test_scenario::ctx(scenario));

            hero::acquire_hero(game_ref, coin, test_scenario::ctx(scenario));
            test_scenario::return_immutable(game);
        };

        // hero 1 vs hero 2
        test_scenario::next_tx(scenario, admin);
        {
            
        };
        test_scenario::end(scenario_val);
    }
}
