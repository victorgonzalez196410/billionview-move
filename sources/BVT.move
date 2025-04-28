module BVT::bvt_coin {
    use std::string;
    use std::vector;
    use std::signer;

    use aptos_framework::coin::{Self, MintCapability, FreezeCapability, BurnCapability};
    use aptos_framework::account::Self;

    /// Account has no capabilities (burn/mint).
    const ENO_CAPABILITIES: u64 = 1;

    /// Total supply of coin.
    const TOTAL_SUPPLY: u64 = 500000000;

    struct BvtCoin {}

    /// Capability wrappers

    struct FreezeCapabilityWrapper<phantom CoinType> has key {
        freeze_cap: FreezeCapability<CoinType>,
    }

    struct MintCapabilityWrapper<phantom CoinType> has key {
        mint_cap: MintCapability<CoinType>,
    }

    struct BurnCapabilityWrapper<phantom CoinType> has key {
        burn_cap: BurnCapability<CoinType>,
    }


    fun init_module(deployer: &signer) {
        initialize<BvtCoin>(
            deployer,
            b"BVT Coin",
            b"BVT",
            6,
            true, // monitor_supply
        );
    }

    public fun initialize<CoinType>(
        account: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8,
        monitor_supply: bool,
    ) {
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<CoinType>(
            account,
            string::utf8(name),
            string::utf8(symbol),
            decimals,
            monitor_supply,
        );

        // register the deployer account
        coin::register<CoinType>(account);

        // mint coins
        let account_addr = signer::address_of(account);
        let amount = TOTAL_SUPPLY * 1000000;
        let coins_minted = coin::mint(amount, &mint_cap);
        coin::deposit(account_addr, coins_minted);

        move_to(account, BurnCapabilityWrapper<CoinType> { burn_cap });

        // Burn the freeze & mint capabilities (move to resource account with dropped signer)
        let (resource_account, _) = account::create_resource_account(account, vector::empty<u8>());
        move_to(&resource_account, FreezeCapabilityWrapper<CoinType> { freeze_cap });
        move_to(&resource_account, MintCapabilityWrapper<CoinType> { mint_cap });
    }

    public entry fun register(account: &signer) {
        coin::register<BvtCoin>(account);
    }

    public entry fun transfer(from: &signer, to: address, amount: u64) {
        coin::transfer<BvtCoin>(from, to, amount);
    }
}
