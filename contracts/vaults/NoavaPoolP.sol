// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "../library/RewardsDistributionRecipientUpgradeable.sol";
import "../library/PausableUpgradeable.sol";
import "../interfaces/legacy/IStrategyHelper.sol";
import "../interfaces/IPancakeRouter02.sol";
import "../interfaces/legacy/IStrategyLegacy.sol";

contract NoavaPool is
    IStrategyLegacy,
    RewardsDistributionRecipientUpgradeable,
    ReentrancyGuard,
    PausableUpgradeable
{
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== STATE VARIABLES ========== */

    IBEP20 public rewardsToken; // Noava/bnb flip
    IBEP20 public stakingToken; // Noava
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 90 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    mapping(address => bool) private _stakePermission;

    /* ========== Noava HELPER ========= */
    IStrategyHelper public helper;
    IPancakeRouter02 private constant ROUTER =
        IPancakeRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    /* ========== INITIALIZER ========== */

    function initialize(IBEP20 _stakingToken, address _rewardsDistribution)
        external
        initializer
    {
        require(
            _rewardsDistribution != address(0),
            "Pool: rewardsDistribution must be set"
        );
        rewardsDistribution = _rewardsDistribution;
        _stakePermission[msg.sender] = true;
        require(
            address(_stakingToken) != address(0),
            "Pool: stakingToken must be set"
        );
        stakingToken = _stakingToken;

        stakingToken.safeApprove(address(ROUTER), type(uint256).max);
        address wbnb = ROUTER.WETH();

        IBEP20(wbnb).safeApprove(address(ROUTER), type(uint256).max);

        __Ownable_init();
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
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

    function principalOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function profitOf(address account)
        public
        view
        override
        returns (
            uint256 _usd,
            uint256 _Noava,
            uint256 _bnb
        )
    {
        _usd = 0;
        _Noava = 0;
        _bnb = helper.tvlInBNB(address(rewardsToken), earned(account));
    }

    function tvl() public view override returns (uint256) {
        uint256 price = helper.tokenPriceInBNB(address(stakingToken));
        return _totalSupply.mul(price).div(1e18);
    }

    function apy()
        public
        view
        override
        returns (
            uint256 _usd,
            uint256 _Noava,
            uint256 _bnb
        )
    {
        uint256 tokenDecimals = 1e18;
        uint256 __totalSupply = _totalSupply;
        if (__totalSupply == 0) {
            __totalSupply = tokenDecimals;
        }

        uint256 rewardPerTokenPerSecond = rewardRate.mul(tokenDecimals).div(
            __totalSupply
        );
        uint256 NoavaPrice = helper.tokenPriceInBNB(address(stakingToken));
        uint256 flipPrice = helper.tvlInBNB(address(rewardsToken), 1e18);

        _usd = 0;
        _Noava = 0;
        _bnb = rewardPerTokenPerSecond.mul(365 days).mul(flipPrice).div(
            NoavaPrice
        );
    }

    function withdrawableBalanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
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

    function earned(address account) public view returns (uint256) {
        return
            _balances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function _deposit(uint256 amount, address _to)
        private
        nonReentrant
        notPaused
        updateReward(_to)
    {
        require(amount > 0, "amount");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(_to, amount);
    }

    function deposit(uint256 amount) public override {
        _deposit(amount, msg.sender);
    }

    function depositAll() external override {
        deposit(stakingToken.balanceOf(msg.sender));
    }

    function withdraw(uint256 amount)
        public
        override
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "amount");
        require(amount <= _balances[msg.sender], "balance");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function withdrawAll() external override {
        uint256 _withdraw = _balances[msg.sender];
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
        getReward();
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            reward = _flipToNoava(reward);
            IBEP20(stakingToken).safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function _flipToNoava(uint256 amount) private returns (uint256 reward) {
        address wbnb = ROUTER.WETH();
        uint256 balanceBefore = IBEP20(stakingToken).balanceOf(address(this));
        (, uint256 rewardWBNB) = ROUTER.removeLiquidity(
            address(stakingToken),
            wbnb,
            amount,
            0,
            0,
            address(this),
            block.timestamp
        );
        address[] memory path = new address[](2);
        path[0] = wbnb;
        path[1] = address(stakingToken);
        ROUTER.swapExactTokensForTokens(
            rewardWBNB,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 balanceAfter = IBEP20(stakingToken).balanceOf(address(this));

        reward = balanceAfter.sub(balanceBefore);
    }

    function harvest() external override {}

    function info(address account)
        external
        view
        override
        returns (UserInfo memory)
    {
        UserInfo memory userInfo;

        userInfo.balance = _balances[account];
        userInfo.principal = _balances[account];
        userInfo.available = _balances[account];

        Profit memory profit;
        (uint256 usd, uint256 noava, uint256 bnb) = profitOf(account);
        profit.usd = usd;
        profit.noava = noava;
        profit.bnb = bnb;
        userInfo.profit = profit;

        userInfo.poolTVL = tvl();

        APY memory poolAPY;
        (usd, noava, bnb) = apy();
        poolAPY.usd = usd;
        poolAPY.noava = noava;
        poolAPY.bnb = bnb;
        userInfo.poolAPY = poolAPY;

        return userInfo;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function setRewardsToken(address _rewardsToken) external onlyOwner {
        require(
            address(rewardsToken) == address(0),
            "set rewards token already"
        );

        rewardsToken = IBEP20(_rewardsToken);

        IBEP20(_rewardsToken).safeApprove(address(ROUTER), type(uint256).max);
    }

    function setHelper(IStrategyHelper _helper) external onlyOwner {
        require(address(_helper) != address(0), "zero address");
        require(address(helper) == address(0), "helper already defined");
        helper = _helper;
    }

    function setStakePermission(address _address, bool permission)
        external
        onlyOwner
    {
        _stakePermission[_address] = permission;
    }

    function stakeTo(uint256 amount, address _to) external canStakeTo {
        _deposit(amount, _to);
    }

    function notifyRewardAmount(uint256 reward)
        external
        override
        onlyRewardsDistribution
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
        uint256 _balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= _balance.div(rewardsDuration), "reward");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken) &&
                tokenAddress != address(rewardsToken),
            "tokenAddress"
        );
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        require(periodFinish == 0 || block.timestamp > periodFinish, "period");
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
    }

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

    modifier canStakeTo() {
        require(_stakePermission[msg.sender], "auth");
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
