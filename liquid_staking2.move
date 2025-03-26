module MyModule::LiquidStaking {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::vector;
    use aptos_framework::table;
    use aptos_framework::table_with_length;

    /// Errors
    const EINSUFFICIENT_BALANCE: u64 = 1;
    const EINVALID_AMOUNT: u64 = 2;
    const EPOOL_NOT_INITIALIZED: u64 = 3;
    const EINVALID_REWARD_RATE: u64 = 4;
    const EINVALID_LOCK_PERIOD: u64 = 5;
    const EINVALID_ADMIN: u64 = 6;
    const EPOOL_PAUSED: u64 = 7;
    const EINVALID_APY: u64 = 8;
    const EINVALID_MIN_STAKE: u64 = 9;
    const EINVALID_MAX_STAKE: u64 = 10;
    const EINVALID_WITHDRAWAL_FEE: u64 = 11;
    const EINVALID_COMPOUND_FREQUENCY: u64 = 12;
    const EINVALID_STAKE_ID: u64 = 13;
    const EINVALID_STAKE_TYPE: u64 = 14;
    const EINVALID_BENEFICIARY: u64 = 15;
    const EINVALID_DELEGATION: u64 = 16;
    const EINVALID_SLASH_RATE: u64 = 17;
    const EINVALID_COOLDOWN: u64 = 18;
    const EINVALID_EMERGENCY: u64 = 19;
    const EINVALID_UPGRADE: u64 = 20;

    /// Events
    struct StakeEvent has drop, store {
        user: address,
        amount: u64,
        stake_type: u8,
        lock_period: u64,
        timestamp: u64,
    }

    struct UnstakeEvent has drop, store {
        user: address,
        amount: u64,
        stake_id: u64,
        timestamp: u64,
    }

    struct RewardEvent has drop, store {
        user: address,
        amount: u64,
        stake_id: u64,
        timestamp: u64,
    }

    struct EmergencyEvent has drop, store {
        admin: address,
        action: u8,
        timestamp: u64,
    }

    struct UpgradeEvent has drop, store {
        admin: address,
        version: u64,
        timestamp: u64,
    }

    struct DelegateEvent has drop, store {
        delegator: address,
        delegate: address,
        amount: u64,
        timestamp: u64,
    }

    /// Stake types
    const STAKE_TYPE_FLEXIBLE: u8 = 0;
    const STAKE_TYPE_LOCKED: u8 = 1;
    const STAKE_TYPE_FIXED: u8 = 2;

    /// Admin capabilities
    struct AdminCapability has key {
        admin: address,
        version: u64,
        is_paused: bool,
        emergency_mode: bool,
        upgrade_cooldown: u64,
        last_upgrade: u64,
    }

    /// Staking pool data
    struct StakingPool has key {
        total_staked: u64,
        reward_rate: u64,  // Reward rate in basis points (1% = 100)
        last_update: u64,
        total_rewards: u64,
        stakers: vector<address>,
        min_stake: u64,
        max_stake: u64,
        withdrawal_fee: u64,  // in basis points
        compound_frequency: u64,  // in seconds
        slash_rate: u64,  // in basis points
        cooldown_period: u64,  // in seconds
        total_slashed: u64,
        total_compounded: u64,
        total_delegated: u64,
        total_beneficiaries: u64,
        total_stake_types: u64,
        total_stake_ids: u64,
        total_stake_holders: u64,
        total_stake_events: u64,
        total_unstake_events: u64,
        total_reward_events: u64,
        total_emergency_events: u64,
        total_upgrade_events: u64,
        total_delegate_events: u64,
    }

    /// User staking data
    struct UserStake has key {
        stakes: table_with_length::TableWithLength<u64, StakeInfo>,
        total_staked: u64,
        total_rewards: u64,
        total_claimed: u64,
        total_delegated: u64,
        total_beneficiaries: u64,
        last_claim: u64,
        last_compound: u64,
        last_delegate: u64,
        last_beneficiary: u64,
        is_delegated: bool,
        is_beneficiary: bool,
        is_slashed: bool,
        is_cooldown: bool,
        cooldown_end: u64,
    }

    /// Stake information
    struct StakeInfo has store {
        amount: u64,
        rewards: u64,
        stake_type: u8,
        lock_period: u64,
        start_time: u64,
        end_time: u64,
        last_claim: u64,
        last_compound: u64,
        is_active: bool,
        is_locked: bool,
        is_fixed: bool,
        is_delegated: bool,
        is_beneficiary: bool,
        is_slashed: bool,
        is_cooldown: bool,
        cooldown_end: u64,
        delegate: address,
        beneficiary: address,
        apy: u64,  // in basis points
        compound_count: u64,
        reward_count: u64,
        unstake_count: u64,
        delegate_count: u64,
        beneficiary_count: u64,
        slash_count: u64,
        cooldown_count: u64,
    }

    /// Initialize the staking pool
    public fun initialize(
        admin: &signer,
        reward_rate: u64,
        min_stake: u64,
        max_stake: u64,
        withdrawal_fee: u64,
        compound_frequency: u64,
        slash_rate: u64,
        cooldown_period: u64
    ) {
        assert!(reward_rate <= 10000, EINVALID_REWARD_RATE);
        assert!(min_stake > 0, EINVALID_MIN_STAKE);
        assert!(max_stake >= min_stake, EINVALID_MAX_STAKE);
        assert!(withdrawal_fee <= 10000, EINVALID_WITHDRAWAL_FEE);
        assert!(compound_frequency > 0, EINVALID_COMPOUND_FREQUENCY);
        assert!(slash_rate <= 10000, EINVALID_SLASH_RATE);
        assert!(cooldown_period > 0, EINVALID_COOLDOWN);
        
        move_to(admin, StakingPool {
            total_staked: 0,
            reward_rate,
            last_update: timestamp::now_seconds(),
            total_rewards: 0,
            stakers: vector::empty(),
            min_stake,
            max_stake,
            withdrawal_fee,
            compound_frequency,
            slash_rate,
            cooldown_period,
            total_slashed: 0,
            total_compounded: 0,
            total_delegated: 0,
            total_beneficiaries: 0,
            total_stake_types: 0,
            total_stake_ids: 0,
            total_stake_holders: 0,
            total_stake_events: 0,
            total_unstake_events: 0,
            total_reward_events: 0,
            total_emergency_events: 0,
            total_upgrade_events: 0,
            total_delegate_events: 0,
        });

        move_to(admin, AdminCapability {
            admin: signer::address_of(admin),
            version: 1,
            is_paused: false,
            emergency_mode: false,
            upgrade_cooldown: 86400, // 24 hours
            last_upgrade: timestamp::now_seconds(),
        });
    }

    /// Stake Aptos with different types
    public fun stake(
        user: &signer,
        amount: u64,
        stake_type: u8,
        lock_period: u64,
        apy: u64
    ) acquires StakingPool, UserStake, AdminCapability {
        assert!(amount > 0, EINVALID_AMOUNT);
        assert!(amount >= borrow_global<StakingPool>(@MyModule).min_stake, EINVALID_MIN_STAKE);
        assert!(amount <= borrow_global<StakingPool>(@MyModule).max_stake, EINVALID_MAX_STAKE);
        assert!(stake_type <= STAKE_TYPE_FIXED, EINVALID_STAKE_TYPE);
        assert!(apy <= 10000, EINVALID_APY);
        
        let admin = borrow_global<AdminCapability>(@MyModule);
        assert!(!admin.is_paused, EPOOL_PAUSED);
        assert!(!admin.emergency_mode, EINVALID_EMERGENCY);
        
        let user_addr = signer::address_of(user);
        let pool = borrow_global_mut<StakingPool>(@MyModule);
        
        // Update rewards for all stakers
        update_rewards(pool);
        
        // Withdraw Aptos from user
        let stake_amount = coin::withdraw<AptosCoin>(user, amount);
        
        // Create module account signer
        let module_signer = account::create_signer_with_capability(&pool);
        coin::deposit<AptosCoin>(&module_signer, stake_amount);
        
        // Update pool state
        pool.total_staked = pool.total_staked + amount;
        pool.total_stake_types = pool.total_stake_types + 1;
        pool.total_stake_ids = pool.total_stake_ids + 1;
        pool.total_stake_holders = pool.total_stake_holders + 1;
        pool.total_stake_events = pool.total_stake_events + 1;
        
        // Update or create user stake
        if (!exists<UserStake>(user_addr)) {
            move_to(user, UserStake {
                stakes: table_with_length::new(),
                total_staked: 0,
                total_rewards: 0,
                total_claimed: 0,
                total_delegated: 0,
                total_beneficiaries: 0,
                last_claim: timestamp::now_seconds(),
                last_compound: timestamp::now_seconds(),
                last_delegate: timestamp::now_seconds(),
                last_beneficiary: timestamp::now_seconds(),
                is_delegated: false,
                is_beneficiary: false,
                is_slashed: false,
                is_cooldown: false,
                cooldown_end: 0,
            });
        };
        
        let user_stake = borrow_global_mut<UserStake>(user_addr);
        let stake_id = pool.total_stake_ids;
        
        // Create stake info
        let stake_info = StakeInfo {
            amount,
            rewards: 0,
            stake_type,
            lock_period,
            start_time: timestamp::now_seconds(),
            end_time: timestamp::now_seconds() + lock_period,
            last_claim: timestamp::now_seconds(),
            last_compound: timestamp::now_seconds(),
            is_active: true,
            is_locked: stake_type == STAKE_TYPE_LOCKED,
            is_fixed: stake_type == STAKE_TYPE_FIXED,
            is_delegated: false,
            is_beneficiary: false,
            is_slashed: false,
            is_cooldown: false,
            cooldown_end: 0,
            delegate: @0x0,
            beneficiary: @0x0,
            apy,
            compound_count: 0,
            reward_count: 0,
            unstake_count: 0,
            delegate_count: 0,
            beneficiary_count: 0,
            slash_count: 0,
            cooldown_count: 0,
        };
        
        // Add stake to user's stakes
        table_with_length::add(&mut user_stake.stakes, stake_id, stake_info);
        user_stake.total_staked = user_stake.total_staked + amount;
        
        // Add user to stakers list if not already present
        if (!vector::contains(&pool.stakers, &user_addr)) {
            vector::push_back(&mut pool.stakers, user_addr);
        };
        
        // Emit event
        event::emit(StakeEvent {
            user: user_addr,
            amount,
            stake_type,
            lock_period,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Unstake with different options
    public fun unstake(
        user: &signer,
        stake_id: u64,
        amount: u64,
        force: bool
    ) acquires StakingPool, UserStake, AdminCapability {
        assert!(amount > 0, EINVALID_AMOUNT);
        
        let admin = borrow_global<AdminCapability>(@MyModule);
        assert!(!admin.is_paused, EPOOL_PAUSED);
        assert!(!admin.emergency_mode, EINVALID_EMERGENCY);
        
        let user_addr = signer::address_of(user);
        let pool = borrow_global_mut<StakingPool>(@MyModule);
        let user_stake = borrow_global_mut<UserStake>(user_addr);
        
        // Get stake info
        let stake_info = table_with_length::borrow_mut(&mut user_stake.stakes, stake_id);
        assert!(stake_info.is_active, EINVALID_STAKE_ID);
        assert!(stake_info.amount >= amount, EINSUFFICIENT_BALANCE);
        
        // Check lock period
        if (stake_info.is_locked && !force) {
            assert!(timestamp::now_seconds() >= stake_info.end_time, EINVALID_LOCK_PERIOD);
        };
        
        // Update rewards
        update_rewards(pool);
        
        // Calculate withdrawal fee
        let fee = (amount * pool.withdrawal_fee) / 10000;
        let withdraw_amount = amount - fee;
        
        // Create module account signer
        let module_signer = account::create_signer_with_capability(&pool);
        
        // Withdraw Aptos from pool
        let unstake_amount = coin::withdraw<AptosCoin>(&module_signer, withdraw_amount);
        coin::deposit<AptosCoin>(user, unstake_amount);
        
        // Update states
        pool.total_staked = pool.total_staked - amount;
        pool.total_unstake_events = pool.total_unstake_events + 1;
        
        stake_info.amount = stake_info.amount - amount;
        stake_info.unstake_count = stake_info.unstake_count + 1;
        
        if (stake_info.amount == 0) {
            stake_info.is_active = false;
        };
        
        user_stake.total_staked = user_stake.total_staked - amount;
        
        // Remove user from stakers if they have no stake left
        if (user_stake.total_staked == 0) {
            let i = 0;
            while (i < vector::length(&pool.stakers)) {
                if (*vector::borrow(&pool.stakers, i) == user_addr) {
                    vector::remove(&mut pool.stakers, i);
                    break
                };
                i = i + 1;
            };
        };
        
        // Emit event
        event::emit(UnstakeEvent {
            user: user_addr,
            amount: withdraw_amount,
            stake_id,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Claim rewards with compound option
    public fun claim_rewards(
        user: &signer,
        stake_id: u64,
        compound: bool
    ) acquires StakingPool, UserStake, AdminCapability {
        let admin = borrow_global<AdminCapability>(@MyModule);
        assert!(!admin.is_paused, EPOOL_PAUSED);
        assert!(!admin.emergency_mode, EINVALID_EMERGENCY);
        
        let user_addr = signer::address_of(user);
        let pool = borrow_global_mut<StakingPool>(@MyModule);
        let user_stake = borrow_global_mut<UserStake>(user_addr);
        
        // Get stake info
        let stake_info = table_with_length::borrow_mut(&mut user_stake.stakes, stake_id);
        assert!(stake_info.is_active, EINVALID_STAKE_ID);
        
        // Update rewards
        update_rewards(pool);
        
        let rewards = stake_info.rewards;
        assert!(rewards > 0, EINSUFFICIENT_BALANCE);
        
        if (compound) {
            // Compound rewards
            stake_info.amount = stake_info.amount + rewards;
            stake_info.compound_count = stake_info.compound_count + 1;
            stake_info.last_compound = timestamp::now_seconds();
            pool.total_compounded = pool.total_compounded + rewards;
            user_stake.last_compound = timestamp::now_seconds();
        } else {
            // Create module account signer
            let module_signer = account::create_signer_with_capability(&pool);
            
            // Transfer rewards
            let reward_amount = coin::withdraw<AptosCoin>(&module_signer, rewards);
            coin::deposit<AptosCoin>(user, reward_amount);
            
            stake_info.reward_count = stake_info.reward_count + 1;
            user_stake.total_claimed = user_stake.total_claimed + rewards;
        };
        
        stake_info.rewards = 0;
        stake_info.last_claim = timestamp::now_seconds();
        user_stake.last_claim = timestamp::now_seconds();
        
        // Emit event
        event::emit(RewardEvent {
            user: user_addr,
            amount: rewards,
            stake_id,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Delegate stake to another address
    public fun delegate_stake(
        user: &signer,
        stake_id: u64,
        delegate: address
    ) acquires StakingPool, UserStake, AdminCapability {
        assert!(delegate != @0x0, EINVALID_DELEGATION);
        
        let admin = borrow_global<AdminCapability>(@MyModule);
        assert!(!admin.is_paused, EPOOL_PAUSED);
        assert!(!admin.emergency_mode, EINVALID_EMERGENCY);
        
        let user_addr = signer::address_of(user);
        let pool = borrow_global_mut<StakingPool>(@MyModule);
        let user_stake = borrow_global_mut<UserStake>(user_addr);
        
        // Get stake info
        let stake_info = table_with_length::borrow_mut(&mut user_stake.stakes, stake_id);
        assert!(stake_info.is_active, EINVALID_STAKE_ID);
        assert!(!stake_info.is_delegated, EINVALID_DELEGATION);
        
        // Update rewards
        update_rewards(pool);
        
        // Update delegation
        stake_info.is_delegated = true;
        stake_info.delegate = delegate;
        stake_info.delegate_count = stake_info.delegate_count + 1;
        
        user_stake.is_delegated = true;
        user_stake.total_delegated = user_stake.total_delegated + stake_info.amount;
        user_stake.last_delegate = timestamp::now_seconds();
        
        pool.total_delegated = pool.total_delegated + stake_info.amount;
        pool.total_delegate_events = pool.total_delegate_events + 1;
        
        // Emit event
        event::emit(DelegateEvent {
            delegator: user_addr,
            delegate,
            amount: stake_info.amount,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Set beneficiary for stake
    public fun set_beneficiary(
        user: &signer,
        stake_id: u64,
        beneficiary: address
    ) acquires StakingPool, UserStake, AdminCapability {
        assert!(beneficiary != @0x0, EINVALID_BENEFICIARY);
        
        let admin = borrow_global<AdminCapability>(@MyModule);
        assert!(!admin.is_paused, EPOOL_PAUSED);
        assert!(!admin.emergency_mode, EINVALID_EMERGENCY);
        
        let user_addr = signer::address_of(user);
        let pool = borrow_global_mut<StakingPool>(@MyModule);
        let user_stake = borrow_global_mut<UserStake>(user_addr);
        
        // Get stake info
        let stake_info = table_with_length::borrow_mut(&mut user_stake.stakes, stake_id);
        assert!(stake_info.is_active, EINVALID_STAKE_ID);
        assert!(!stake_info.is_beneficiary, EINVALID_BENEFICIARY);
        
        // Update beneficiary
        stake_info.is_beneficiary = true;
        stake_info.beneficiary = beneficiary;
        stake_info.beneficiary_count = stake_info.beneficiary_count + 1;
        
        user_stake.is_beneficiary = true;
        user_stake.total_beneficiaries = user_stake.total_beneficiaries + 1;
        user_stake.last_beneficiary = timestamp::now_seconds();
        
        pool.total_beneficiaries = pool.total_beneficiaries + 1;
    }

    /// Emergency pause/unpause
    public fun emergency_pause(admin: &signer, pause: bool) acquires AdminCapability {
        let admin_cap = borrow_global_mut<AdminCapability>(@MyModule);
        assert!(signer::address_of(admin) == admin_cap.admin, EINVALID_ADMIN);
        
        admin_cap.is_paused = pause;
        
        // Emit event
        event::emit(EmergencyEvent {
            admin: signer::address_of(admin),
            action: if (pause) 1 else 0,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Emergency mode
    public fun emergency_mode(admin: &signer, enable: bool) acquires AdminCapability {
        let admin_cap = borrow_global_mut<AdminCapability>(@MyModule);
        assert!(signer::address_of(admin) == admin_cap.admin, EINVALID_ADMIN);
        
        admin_cap.emergency_mode = enable;
        
        // Emit event
        event::emit(EmergencyEvent {
            admin: signer::address_of(admin),
            action: if (enable) 2 else 3,
            timestamp: timestamp::now_seconds(),
        });
    }

    /// Upgrade pool parameters
    public fun upgrade_pool(
        admin: &signer,
        reward_rate: u64,
        min_stake: u64,
        max_stake: u64,
        withdrawal_fee: u64,
        compound_frequency: u64,
        slash_rate: u64,
        cooldown_period: u64
    ) acquires StakingPool, AdminCapability {
        let admin_cap = borrow_global_mut<AdminCapability>(@MyModule);
        assert!(signer::address_of(admin) == admin_cap.admin, EINVALID_ADMIN);
        
        let current_time = timestamp::now_seconds();
        assert!(current_time >= admin_cap.last_upgrade + admin_cap.upgrade_cooldown, EINVALID_UPGRADE);
        
        assert!(reward_rate <= 10000, EINVALID_REWARD_RATE);
        assert!(min_stake > 0, EINVALID_MIN_STAKE);
        assert!(max_stake >= min_stake, EINVALID_MAX_STAKE);
        assert!(withdrawal_fee <= 10000, EINVALID_WITHDRAWAL_FEE);
        assert!(compound_frequency > 0, EINVALID_COMPOUND_FREQUENCY);
        assert!(slash_rate <= 10000, EINVALID_SLASH_RATE);
        assert!(cooldown_period > 0, EINVALID_COOLDOWN);
        
        let pool = borrow_global_mut<StakingPool>(@MyModule);
        pool.reward_rate = reward_rate;
        pool.min_stake = min_stake;
        pool.max_stake = max_stake;
        pool.withdrawal_fee = withdrawal_fee;
        pool.compound_frequency = compound_frequency;
        pool.slash_rate = slash_rate;
        pool.cooldown_period = cooldown_period;
        
        admin_cap.version = admin_cap.version + 1;
        admin_cap.last_upgrade = current_time;
        
        // Emit event
        event::emit(UpgradeEvent {
            admin: signer::address_of(admin),
            version: admin_cap.version,
            timestamp: current_time,
        });
    }

    /// Update rewards for all stakers
    fun update_rewards(pool: &mut StakingPool) acquires UserStake {
        let current_time = timestamp::now_seconds();
        let time_diff = current_time - pool.last_update;
        
        if (time_diff == 0 || pool.total_staked == 0) {
            return
        };
        
        let reward_per_second = (pool.reward_rate * pool.total_staked) / (10000 * 365 * 24 * 60 * 60);
        let total_rewards = reward_per_second * time_diff;
        
        let i = 0;
        while (i < vector::length(&pool.stakers)) {
            let staker_addr = *vector::borrow(&pool.stakers, i);
            let user_stake = borrow_global_mut<UserStake>(staker_addr);
            
            let j = 0;
            while (j < table_with_length::length(&user_stake.stakes)) {
                let stake_info = table_with_length::borrow_mut(&mut user_stake.stakes, j);
                if (stake_info.is_active) {
                    let user_rewards = (stake_info.amount * total_rewards) / pool.total_staked;
                    stake_info.rewards = stake_info.rewards + user_rewards;
                };
                j = j + 1;
            };
            
            i = i + 1;
        };
        
        pool.last_update = current_time;
        pool.total_rewards = pool.total_rewards + total_rewards;
    }

    /// Get user's staked amount
    public fun get_staked_amount(user: address): u64 acquires UserStake {
        if (exists<UserStake>(user)) {
            borrow_global<UserStake>(user).total_staked
        } else {
            0
        }
    }

    /// Get user's pending rewards
    public fun get_pending_rewards(user: address): u64 acquires UserStake {
        if (exists<UserStake>(user)) {
            borrow_global<UserStake>(user).total_rewards
        } else {
            0
        }
    }

    /// Get total staked amount
    public fun get_total_staked(): u64 acquires StakingPool {
        borrow_global<StakingPool>(@MyModule).total_staked
    }

    /// Get pool statistics
    public fun get_pool_stats(): (
        u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, u64
    ) acquires StakingPool {
        let pool = borrow_global<StakingPool>(@MyModule);
        (
            pool.total_staked,
            pool.reward_rate,
            pool.total_rewards,
            pool.min_stake,
            pool.max_stake,
            pool.withdrawal_fee,
            pool.compound_frequency,
            pool.slash_rate,
            pool.cooldown_period,
            pool.total_slashed,
            pool.total_compounded,
            pool.total_delegated,
            pool.total_beneficiaries,
            pool.total_stake_types,
            pool.total_stake_ids,
            pool.total_stake_holders,
            pool.total_stake_events,
            pool.total_unstake_events,
            pool.total_reward_events,
            pool.total_delegate_events
        )
    }

    /// Get user statistics
    public fun get_user_stats(user: address): (
        u64, u64, u64, u64, u64, u64, u64, u64, u64, u64, bool, bool, bool, bool, u64
    ) acquires UserStake {
        if (exists<UserStake>(user)) {
            let user_stake = borrow_global<UserStake>(user);
            (
                user_stake.total_staked,
                user_stake.total_rewards,
                user_stake.total_claimed,
                user_stake.total_delegated,
                user_stake.total_beneficiaries,
                user_stake.last_claim,
                user_stake.last_compound,
                user_stake.last_delegate,
                user_stake.last_beneficiary,
                table_with_length::length(&user_stake.stakes),
                user_stake.is_delegated,
                user_stake.is_beneficiary,
                user_stake.is_slashed,
                user_stake.is_cooldown,
                user_stake.cooldown_end
            )
        } else {
            (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false, false, false, 0)
        }
    }

    /// Get stake information
    public fun get_stake_info(user: address, stake_id: u64): (
        u64, u64, u8, u64, u64, u64, u64, u64, bool, bool, bool, bool, bool, bool, bool, bool, u64, address, address, u64, u64, u64, u64, u64, u64, u64, u64
    ) acquires UserStake {
        if (exists<UserStake>(user)) {
            let user_stake = borrow_global<UserStake>(user);
            let stake_info = table_with_length::borrow(&user_stake.stakes, stake_id);
            (
                stake_info.amount,
                stake_info.rewards,
                stake_info.stake_type,
                stake_info.lock_period,
                stake_info.start_time,
                stake_info.end_time,
                stake_info.last_claim,
                stake_info.last_compound,
                stake_info.is_active,
                stake_info.is_locked,
                stake_info.is_fixed,
                stake_info.is_delegated,
                stake_info.is_beneficiary,
                stake_info.is_slashed,
                stake_info.is_cooldown,
                stake_info.cooldown_end,
                stake_info.delegate,
                stake_info.beneficiary,
                stake_info.apy,
                stake_info.compound_count,
                stake_info.reward_count,
                stake_info.unstake_count,
                stake_info.delegate_count,
                stake_info.beneficiary_count,
                stake_info.slash_count,
                stake_info.cooldown_count
            )
        } else {
            (0, 0, 0, 0, 0, 0, 0, 0, false, false, false, false, false, false, false, false, @0x0, @0x0, 0, 0, 0, 0, 0, 0, 0, 0)
        }
    }
} 