module MyModule::Staking {
    use std::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;

    // Error codes
    const EINVALID_STAKE_TYPE: u64 = 1001; // Added this constant
    const ESTAKE_AMOUNT_ZERO: u64 = 1002; 

    // Constants for stake type
    const STAKE_TYPE_FIXED: u8 = 1;
    const STAKE_TYPE_FLEXIBLE: u8 = 2;

    /// Function to stake coins
    public entry fun stake(signer: &signer, amount: u64, stake_type: u8) {
        assert!(stake_type <= STAKE_TYPE_FIXED, EINVALID_STAKE_TYPE);
        assert!(amount > 0, ESTAKE_AMOUNT_ZERO);

        let user_address = signer::address_of(signer);

        // Withdraw funds from the user's account
        let stake_amount = coin::withdraw<AptosCoin>(signer, amount);
        
        // Deposit the funds into the module's address
        coin::deposit<AptosCoin>(@MyModule, stake_amount);
    }

    /// Function to unstake coins
    public entry fun unstake(signer: &signer, withdraw_amount: u64) {
        let user_address = signer::address_of(signer);

        // Withdraw funds from module's staking pool
        let unstake_amount = coin::withdraw<AptosCoin>(signer, withdraw_amount);
        
        // Deposit back into the user's account
        coin::deposit<AptosCoin>(user_address, unstake_amount);
    }

    /// Function to distribute rewards
    public entry fun distribute_rewards(signer: &signer, rewards: u64) {
        let user_address = signer::address_of(signer);

        // Withdraw rewards from module
        let reward_amount = coin::withdraw<AptosCoin>(signer, rewards);
        
        // Deposit rewards into user's account
        coin::deposit<AptosCoin>(user_address, reward_amount);
    }
}
