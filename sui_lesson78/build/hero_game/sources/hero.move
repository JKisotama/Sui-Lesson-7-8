module hero_game::hero {
    use sui::object::{Self,UID,ID};
    use sui::transfer;
    use sui::tx_context::{Self,TxContext};
    use std::option::{Self,Option};
    use sui::coin::{Self,Coin};
    use sui::event;
    use sui::sui::SUI;
    use sui::math;

    struct Hero has key, store {
        id: UID,
        hp: u64,
        mana: u64,
        level: u8,
        experience: u64,
        sword: Option<Sword>,
        game_id: ID,
    }

    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
        game_id: ID,
    }

    struct Potion has key, store {
        id: UID,
        potency: u64,
        game_id: ID,
    }

    struct Armor has key,store {
        id: UID,
        guard: u64,
        game_id: ID,
    }

    struct Monster has key {
        id: UID,
        hp: u64,
        strength: u64,
        game_id: ID,
    }

    struct GameInfo has key {
        id: UID,
        admin: address
    }

    struct GameAdmin has key {
        id: UID,
        monster_created: u64,
        potions_created: u64,
        game_id: ID,
    }

    struct MonterSlainEvent has copy, drop {
        slayer_address: address,
        hero: ID,
        monter: ID,
        game_id: ID,
    }

    const MAX_HP: u64 = 1000;
    const MAX_MAGIC: u64 = 100;
    const MIN_SWORD_COST: u64 = 100;

    const EBOAR_WON: u64 = 0;
    const EHERO_TIRED: u64 = 1;
    const ENOT_ADMIN: u64 = 2;
    const EINSUFFICIENT_FUNDS: u64 = 3;
    const ENO_SWORD: u64 = 4;
    const ASSERT_ERR: u64 = 5;

    #[allow(unused_function)]
    fun init(ctx: &mut TxContext) {
       create_game(ctx);
    }
    #[only_test]
    public entry fun new(ctx: &mut TxContext) {
        create_game(ctx);
    }

    fun create_game(ctx: &mut TxContext){
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let game_id = object::uid_to_inner(&id);

        transfer::freeze_object(GameInfo {
            id,
            admin: sender
        });

        transfer::transfer(
            GameAdmin {
                id: object::new(ctx),
                game_id,
                monster_created: 0,
                potions_created: 0
            }, 
            sender
        )
    }

    // --- Gameplay ---
    public entry fun attack(game: &GameInfo, hero: &mut Hero, monter: Monster, ctx: &TxContext) {
        check_id(game, hero.game_id);
        check_id(game, monter.game_id);
        let Monster {
            id: monter_id,
            strength: monter_strength,
            hp,
            game_id: _,
        } = monter;

        let hero_strength = hero_strength(hero);
        let monter_hp = hp;
        let hero_hp = hero.hp;
        while( monter_hp > hero_strength) {
            monter_hp = monter_hp - hero_strength;
            assert!(hero_hp >= monter_strength, EBOAR_WON);
            hero_hp = hero_hp - monter_strength;
        };

        hero.hp = hero.hp;
        hero.experience = hero.experience + hp;
        if(option::is_some(&hero.sword)) {
            level_up_sword(option::borrow_mut(&mut hero.sword), 1)
        };


        event::emit(MonterSlainEvent {
            slayer_address: tx_context::sender(ctx),
            hero: object::uid_to_inner(&hero.id),
            monter: object::uid_to_inner(&monter_id),
            game_id: id(game)
        });
        object::delete(monter_id);
    }

    public entry fun p2p_play(game: &GameInfo, hero1: &mut Hero, hero2: &mut Hero, ctx: &TxContext) {

    }

    public fun up_level_hero(hero: &Hero): u64 {
       hero.experience / 100 
    }

    public fun hero_strength(hero: &Hero): u64 {
        if(hero.hp == 0) {
            return 0
        };

        let sword_strength = if(option::is_some(&hero.sword)){
            sword_strength(option::borrow(&hero.sword))
        } else {
            0
        };
        (hero.experience * hero.hp ) + sword_strength
    }

    fun level_up_sword(sword: &mut Sword, amount: u64) {
        sword.magic + amount;
        sword.strength + amount;
    }

    fun level_up_armor(armor: &mut Armor, amount: u64) {
        armor.guard + amount;
    }

    public fun sword_strength(sword: &Sword): u64 {
        sword.magic + sword.strength

    }

    public fun heal(hero: &mut Hero, potion: Potion) {
        assert!(hero.game_id == potion.game_id, 403);
        let Potion{
            id,
            potency,
            game_id: _,
        } = potion;
        object::delete(id);
        let new_hp = hero.hp + potency;
        hero.hp = math::min(new_hp, MAX_HP)
    }

    public fun equip_sword(hero: &mut Hero, new_sword: Sword): Option<Sword> {
        option::swap_or_fill(&mut hero.sword, new_sword)
    }

    // --- Object creation ---
    public fun create_sword(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Sword {
        let value = coin::value(&payment);
        assert!(value >= MIN_SWORD_COST, EINSUFFICIENT_FUNDS);
        transfer::public_transfer(payment, game.admin);
        let magic = (value - MIN_SWORD_COST) / MIN_SWORD_COST;
        Sword{
            id: object::new(ctx),
            magic: math::min(magic,MAX_MAGIC),
            strength: 1,
            game_id: get_game_id(game)
        }
    }

    public fun create_armor(game: &GameInfo, payment: Coin<SUI>, ctx: &mut TxContext): Armor {
        let value = coin::value(&payment);
        assert!(value >= 10, ASSERT_ERR);

        let guard = (value*2);
        transfer::public_transfer(payment, game.admin);
        Armor{
            id: object::new(ctx),
            guard,
            game_id: get_game_id(game)
        }
    }

    public entry fun acquire_hero(
        game: &GameInfo, payment: Coin<SUI>,ctx: &mut TxContext) {
        let sword = create_sword(game, payment, ctx);
        let hero = create_hero(game, sword, ctx);
        transfer::public_transfer(hero, tx_context::sender(ctx))
    }

    public fun create_hero(game: &GameInfo, sword: Sword, ctx: &mut TxContext): Hero {
        Hero {
            id: object::new(ctx),
            hp: 100,
            mana: 100,
            level: 1,
            experience: 0,
            sword: option::some(sword),
            game_id: id(game)
        }
    }

    public entry fun send_potion(game: &GameInfo, payment: Coin<SUI>, player: address, potency: u64, admin: &mut GameAdmin,ctx: &mut TxContext) {
        check_id(game, admin.game_id);
        admin.potions_created = admin.potions_created + 1;
        transfer::public_transfer(Potion{
            id: object::new(ctx),
            potency,
            game_id: id(game)
        }, player);
        transfer::public_transfer(payment,game.admin)

    }

    public entry fun send_monster(game: &GameInfo, admin: &mut GameAdmin, hp: u64, strength: u64, player: address, ctx: &mut TxContext) {
        check_id(game, admin.game_id);
        admin.monster_created = admin.monster_created + 1;
        transfer::transfer(Monster{ 
            id: object::new(ctx),
            hp,
            strength,
            game_id: id(game)
        }, player)
    }

     public fun check_id (game_info: &GameInfo, id: ID) {
        assert!(id(game_info) == id, 403); 
    }

    public fun id(game_info: &GameInfo): ID {
        object::id(game_info)
    }

    public fun get_game_id(game_info: &GameInfo): ID {
        object::id(game_info)
    }
}
