// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/*
      ___           ___           ___                         ___     
     /\  \         /\  \         /\  \          ___          /\  \    
     \:\  \       /::\  \       /::\  \        /\  \        /::\  \   
      \:\  \     /:/\:\  \     /:/\:\  \       \:\  \      /:/\:\  \  
  _____\:\  \   /:/  \:\  \   /:/ /::\  \       \:\  \    /:/ /::\  \ 
 /::::::::\__\ /:/__/ \:\__\ /:/_/:/\:\__\  ___  \:\__\  /:/_/:/\:\__\
 \:\~~\~~\/__/ \:\  \ /:/  / \:\/:/  \/__/ /\  \ |:|  |  \:\/:/  \/__/
  \:\  \        \:\  /:/  /   \::/__/      \:\  \|:|  |   \::/__/     
   \:\  \        \:\/:/  /     \:\  \       \:\__|:|__|    \:\  \     
    \:\__\        \::/  /       \:\__\       \::::/__/      \:\__\    
     \/__/         \/__/         \/__/        ~~~~           \/__/    

*
* MIT License
* ===========
*
* Copyright (c) 2020 NoavaFinance
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../../library/RewardsDistributionRecipientUpgradeable.sol";
import {PoolConstant} from "../../library/PoolConstant.sol";

import "../../interfaces/IStrategy.sol";
import "../../interfaces/IMasterChef.sol";
import "../../interfaces/INoavaMinter.sol";

import "../../vaults/VaultController.sol";

contract VaultRelayInternal is
    VaultController,
    IStrategy,
    RewardsDistributionRecipientUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    IMasterChef private constant CAKE_MASTER_CHEF =
        IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E);
    PoolConstant.PoolTypes public constant override poolType =
        PoolConstant.PoolTypes.FlipToCake;

    /* ========== STATE VARIABLES ========== */

    IStrategy private _rewardsToken;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    uint256 public override pid;
    mapping(address => uint256) private _depositedAt;

    address public relayer;

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyRelayer() {
        require(
            relayer != address(0) && msg.sender == relayer,
            "VaultRelayInternal: call is not the relayer"
        );
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);

    /* ========== INITIALIZER ========== */

    function initialize(uint256 _pid, address _relayer) external initializer {
        (address _token, , , ) = CAKE_MASTER_CHEF.poolInfo(_pid);
        __VaultController_init(IBEP20(_token));
        __RewardsDistributionRecipient_init();
        __ReentrancyGuard_init();

        _stakingToken.safeApprove(address(CAKE_MASTER_CHEF), uint256(-1));
        pid = _pid;

        rewardsDuration = 4 hours;

        rewardsDistribution = msg.sender;
        setRewardsToken(0xEDfcB78e73f7bA6aD2D829bf5D462a0924da28eD);
        relayer = _relayer;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balance() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function sharesOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function principalOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function depositedAt(address account)
        external
        view
        override
        returns (uint256)
    {
        return _depositedAt[account];
    }

    function withdrawableBalanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function rewardsToken() external view override returns (address) {
        return address(_rewardsToken);
    }

    function priceShare() external view override returns (uint256) {
        return 1e18;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account) public view override returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS - IStrategy ========== */

    function deposit(uint256) public override {
        revert("N/A");
    }

    function depositAll() external override {
        revert("N/A");
    }

    function withdraw(uint256) external override {
        revert("N/A");
    }

    function withdrawAll() external override {
        revert("N/A");
    }

    function getReward() external override {
        revert("N/A");
    }

    /* ========== MUTATIVE FUNCTIONS - RelayInternal ========== */

    function deposit(uint256 amount, address _to)
        external
        nonReentrant
        notPaused
        updateReward(_to)
        onlyRelayer
    {
        require(
            amount > 0,
            "VaultRelayInternal: amount must be greater than zero"
        );
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        _depositedAt[_to] = block.timestamp;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        uint256 cakeHarvested = _depositStakingToken(amount);
        emit Deposited(_to, amount);

        _harvest(cakeHarvested);
    }

    function withdraw(uint256 amount, address _to)
        public
        nonReentrant
        updateReward(_to)
        onlyRelayer
    {
        require(
            amount > 0,
            "VaultRelayInternal: amount must be greater than zero"
        );
        _totalSupply = _totalSupply.sub(amount);
        _balances[_to] = _balances[_to].sub(amount);
        uint256 cakeHarvested = _withdrawStakingToken(amount);

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(_to, amount, 0);

        _harvest(cakeHarvested);
    }

    function getReward(address _to)
        public
        nonReentrant
        updateReward(_to)
        onlyRelayer
    {
        uint256 reward = rewards[_to];
        if (reward > 0) {
            rewards[_to] = 0;
            uint256 before = IBEP20(CAKE).balanceOf(address(this));
            _rewardsToken.withdraw(reward);
            uint256 cakeBalance = IBEP20(CAKE).balanceOf(address(this)).sub(
                before
            );

            IBEP20(CAKE).safeTransfer(msg.sender, cakeBalance);
            emit ProfitPaid(_to, cakeBalance, 0);
        }
    }

    function withdrawAll(address _to) external onlyRelayer {
        uint256 _withdraw = withdrawableBalanceOf(_to);
        if (_withdraw > 0) {
            withdraw(_withdraw, _to);
        }
        getReward(_to);
    }

    function harvest() public override {
        uint256 cakeHarvested = _withdrawStakingToken(0);
        _harvest(cakeHarvested);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address) public override onlyOwner {
        revert("N/A");
    }

    function setRewardsToken(address newRewardsToken) public onlyOwner {
        require(
            address(_rewardsToken) == address(0),
            "VaultRelayInternal: rewards token already set"
        );

        _rewardsToken = IStrategy(newRewardsToken);
        IBEP20(CAKE).safeApprove(newRewardsToken, 0);
        IBEP20(CAKE).safeApprove(newRewardsToken, uint256(-1));
    }

    function notifyRewardAmount(uint256 reward)
        public
        override
        onlyRewardsDistribution
    {
        _notifyRewardAmount(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "VaultRelayInternal: reward duration can only be updated after the period ends"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

    function setRelayer(address newRelayer) external onlyOwner {
        relayer = newRelayer;
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _depositStakingToken(uint256 amount)
        private
        returns (uint256 cakeHarvested)
    {
        uint256 before = IBEP20(CAKE).balanceOf(address(this));
        CAKE_MASTER_CHEF.deposit(pid, amount);
        cakeHarvested = IBEP20(CAKE).balanceOf(address(this)).sub(before);
    }

    function _withdrawStakingToken(uint256 amount)
        private
        returns (uint256 cakeHarvested)
    {
        uint256 before = IBEP20(CAKE).balanceOf(address(this));
        CAKE_MASTER_CHEF.withdraw(pid, amount);
        cakeHarvested = IBEP20(CAKE).balanceOf(address(this)).sub(before);
    }

    function _harvest(uint256 cakeAmount) private {
        uint256 _before = _rewardsToken.sharesOf(address(this));
        _rewardsToken.deposit(cakeAmount);
        uint256 amount = _rewardsToken.sharesOf(address(this)).sub(_before);
        if (amount > 0) {
            _notifyRewardAmount(amount);
            emit Harvested(amount);
        }
    }

    function _notifyRewardAmount(uint256 reward)
        private
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 _balance = _rewardsToken.sharesOf(address(this));
        require(
            rewardRate <= _balance.div(rewardsDuration),
            "VaultRelayInternal: reward rate must be in the right range"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address tokenAddress, uint256 tokenAmount)
        external
        override
        onlyOwner
    {
        require(
            tokenAddress != address(_stakingToken) &&
                tokenAddress != _rewardsToken.stakingToken(),
            "VaultRelayInternal: cannot recover underlying token"
        );
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /// dev: TODO Will be removed after beta test (beta test only)
    function recoverForBetaTest(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}
