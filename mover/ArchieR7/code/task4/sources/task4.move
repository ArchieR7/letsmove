module task4::dice_game {
    use task2::faucet_coin::{FAUCET_COIN};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::clock::{Self, Clock};

    const EPoolNotEnough: u64 = 1;

    public struct Game has key {
        id: UID,
        pool: Balance<FAUCET_COIN>
    }

    public struct AdminCapability has key {
        id: UID
    }

    fun init(ctx: &mut TxContext) {
        let game = Game {
            id: object::new(ctx),
            pool: balance::zero<FAUCET_COIN>(),
        };
        let admin_capability = AdminCapability {
            id: object::new(ctx),
        };
        transfer::share_object(game);
        transfer::transfer(admin_capability, tx_context::sender(ctx));
    }

    public entry fun throw_dice(clock: &Clock, game: &mut Game, bet_coin: Coin<FAUCET_COIN>, ctx: &mut TxContext) {
        assert!(balance::value(&game.pool) >= coin::value(&bet_coin), EPoolNotEnough);
        let random_number = get_random_number(clock);
        if (random_number > 3) {
            let mut prize_balance = balance::split(&mut game.pool, coin::value(&bet_coin));
            coin::put(&mut prize_balance, bet_coin);
            let prize_coin = coin::from_balance(prize_balance, ctx);
            transfer::public_transfer(prize_coin, tx_context::sender(ctx));
        } else {
            balance::join(&mut game.pool, coin::into_balance(bet_coin));
        }
    }

    public entry fun withdraw(_: &AdminCapability, game: &mut Game, amount: u64, ctx: &mut TxContext) {
        let split_coin = balance::split(&mut game.pool, amount);
        let withdraw_coin = coin::from_balance(split_coin, ctx);
        transfer::public_transfer(withdraw_coin, tx_context::sender(ctx));
    }

    fun get_random_number(clock: &Clock): u8 {
        ((clock::timestamp_ms(clock) & 6) as u8) + 1
    }
}
