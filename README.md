# MyModule Staking

## Description
MyModule Staking is a smart contract built on the Move language, designed to facilitate secure and efficient staking of Aptos coins (APT). This contract allows users to stake their APT tokens, withdraw their staked amount, and receive staking rewards. It supports two types of staking: fixed and flexible, giving users the freedom to choose their preferred staking model.

## Vision
Our goal is to create a decentralized and secure staking mechanism that allows users to earn passive income while contributing to the stability and security of the Aptos ecosystem. By providing a seamless and efficient staking experience, we aim to enhance the adoption of decentralized finance (DeFi) on Aptos.

## Future Scope
- Implementing time-locked staking for fixed stake types.
- Adding an interest calculation mechanism for staking rewards.
- Enabling governance-based decision-making for staking parameters.
- Providing analytics and staking dashboards for better user experience.
- Enhancing security mechanisms for safer fund management.

## Contract Details
### Error Codes
- **EINVALID_STAKE_TYPE (1001):** The provided stake type is invalid.
- **ESTAKE_AMOUNT_ZERO (1002):** Staking amount must be greater than zero.

### Constants
- **STAKE_TYPE_FIXED (1):** Fixed-term staking.
- **STAKE_TYPE_FLEXIBLE (2):** Flexible staking.

### Functions
#### `stake(signer: &signer, amount: u64, stake_type: u8)`
- Allows users to stake a specified amount of AptosCoin.
- Validates the stake type and amount before processing.
- Deposits the staked amount into the module's staking pool.

#### `unstake(signer: &signer, withdraw_amount: u64)`
- Allows users to withdraw their staked amount.
- Transfers the specified amount from the staking pool back to the user.

#### `distribute_rewards(signer: &signer, rewards: u64)`
- Facilitates the distribution of staking rewards to users.
- Withdraws rewards from the staking pool and deposits them into the user's account.

## Deployment
To deploy this contract on Aptos, replace `0xYourModuleAddress` with the actual module address and use the Aptos CLI to publish the module.

---
For any queries or contributions, feel free to open an issue or submit a pull request!

## **contact address**
0x07f7663aa19f9026455df4b670cb59fe0b09ea22c66f8f7bb4e6fea7175ee7a4

![image](https://github.com/user-attachments/assets/f262ed15-6a74-4413-b285-6aa360af680b)
