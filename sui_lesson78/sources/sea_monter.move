module hero_game::sea_hero {
    use hero_game::hero::{Self, Hero};
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance, Supply};
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};

    struct SeaHeroAdmin has key {
        id: UID,
        supply: Supply<VBI_TOKEN>,
        monsters_created: u64,
        token_supply_max: u64,
        monster_max: u64
    }

    struct SeaMonster has key, store {
        id: UID,
        reward: Balance<VBI_TOKEN>
    }

    struct VBI_TOKEN has drop {}

    const EHERO_NOT_STRONG_ENOUGH: u64 = 0;
    const EINVALID_TOKEN_SUPPLY: u64 = 1;
    const EINVALID_MONSTER_SUPPLY: u64 = 2;

    fun init(ctx: &mut TxContext) {
        let game_admin = SeaHeroAdmin 
            {
                id: object::new(ctx),
                supply: balance::create_supply<VBI_TOKEN>(VBI_TOKEN {}),
                monsters_created: 0,
                token_supply_max: 10000000,
                monster_max: 10,
            };
            transfer::transfer(game_admin, tx_context::sender(ctx));
        
    }

    #[only_test]
    public entry fun new(ctx: &mut TxContext) {
        let game_admin = SeaHeroAdmin {
            id: object::new(ctx),
            supply: balance::create_supply<VBI_TOKEN>(VBI_TOKEN {}),
            token_supply_max: 100000,
            monster_max: 10,
            monsters_created: 0
        };

        transfer::transfer(game_admin, tx_context::sender(ctx));
    }

    public fun attack(hero : &Hero, monster: SeaMonster, ctx: &mut TxContext) {
        let reward = slay(hero, monster);
        transfer::public_transfer(coin::from_balance(reward, ctx)
        , tx_context::sender(ctx));
    }

    // --- Gameplay ---
    public fun slay(hero: &Hero, monster: SeaMonster ): Balance<VBI_TOKEN> {
       let SeaMonster {id, reward} = monster;
       object::delete(id);
       assert!(
        hero::hero_strength(hero) >= balance::value(&reward),
        EHERO_NOT_STRONG_ENOUGH
       );

       reward
    }

    // --- Object and coin creation ---
    public entry fun create_sea_monster(admin: &mut SeaHeroAdmin, reward_amount: u64, recipient: address, ctx: &mut TxContext) {
        let current_coin_supply = balance::supply_value(&admin.supply);
        let token_supply_max = admin.token_supply_max;
        assert!(reward_amount < token_supply_max, 0);
        assert!(token_supply_max - reward_amount >= current_coin_supply, 1);
        assert!(admin.monster_max - 1 >= admin.monsters_created, 2);
        let monter = SeaMonster {
            id: object::new(ctx),
            reward: balance::increase_supply(&mut admin.supply, reward_amount),
        };

        admin.monsters_created = admin.monsters_created + 1;

        transfer::public_transfer(monter,recipient)
    }

    public fun monster_reward(monter: &SeaMonster): u64 {
        balance::value(&monter.reward)
    }
}
