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
* SOFTWARE.
*/

import "@openzeppelin/contracts/math/Math.sol";
import "@pancakeswap/pancake-swap-lib/contracts/math/SafeMath.sol";
import "@pancakeswap/pancake-swap-lib/contracts/token/BEP20/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import {PoolConstant} from "../library/PoolConstant.sol";

import "../interfaces/IStrategy.sol";
import "../interfaces/INoavaMinter.sol";
import "../interfaces/INoavaChef.sol";
import "../interfaces/INoavaPool.sol";
import "../interfaces/IZap.sol";

import "./VaultController.sol";

contract VaultNoavaMaximizer is
    VaultController,
    IStrategy,
    ReentrancyGuardUpgradeable
{
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private constant NOAVA = 0xC9849E6fdB743d08fAeE3E34dd2D1bc69EA11a51;
    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address private constant CAKE = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;

    PoolConstant.PoolTypes public constant override poolType =
        PoolConstant.PoolTypes.NoavaToNoava;
    IZap public constant zap = IZap(0xdC2bBB0D33E0e7Dea9F5b98F46EDBaC823586a0C);

    address public constant FEE_BOX =
        0x3749f69B2D99E5586D95d95B6F9B5252C71894bb;
    address private constant NOAVA_POOL_V1 =
        0xCADc8CB26c8C7cB46500E61171b5F27e9bd7889D;

    uint256 private constant DUST = 1000;

    uint256 public constant override pid = 9999;

    /* ========== STATE VARIABLES ========== */

    uint256 private totalShares;
    mapping(address => uint256) private _shares;
    mapping(address => uint256) private _principal;
    mapping(address => uint256) private _depositedAt;

    address private _noavaPool;

    /* ========== INITIALIZER ========== */

    receive() external payable {}

    function initialize() external initializer {
        __VaultController_init(IBEP20(NOAVA));
        __ReentrancyGuard_init();

        setMinter(0x8cB88701790F650F273c8BB2Cc4c5f439cd65219);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return totalShares;
    }

    function balance() public view override returns (uint256) {
        if (_noavaPool == address(0)) {
            return INoavaPool(NOAVA_POOL_V1).balanceOf(address(this));
        }
        return INoavaPool(_noavaPool).balanceOf(address(this));
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (totalShares == 0) return 0;
        return balance().mul(sharesOf(account)).div(totalShares);
    }

    function withdrawableBalanceOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return balanceOf(account);
    }

    function sharesOf(address account) public view override returns (uint256) {
        return _shares[account];
    }

    function principalOf(address account)
        public
        view
        override
        returns (uint256)
    {
        return _principal[account];
    }

    function earned(address account) public view override returns (uint256) {
        if (balanceOf(account) >= principalOf(account) + DUST) {
            return balanceOf(account).sub(principalOf(account));
        } else {
            return 0;
        }
    }

    function depositedAt(address account)
        external
        view
        override
        returns (uint256)
    {
        return _depositedAt[account];
    }

    function rewardsToken() external view override returns (address) {
        return NOAVA;
    }

    function priceShare() external view override returns (uint256) {
        if (totalShares == 0) return 1e18;
        return balance().mul(1e18).div(totalShares);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint256 amount) public override {
        _deposit(amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdrawAll() external override {
        require(
            _noavaPool != address(0),
            "VaultNoavaMaximizer: NoavaPool must set"
        );
        uint256 amount = balanceOf(msg.sender);
        uint256 principal = principalOf(msg.sender);
        uint256 depositTimestamp = _depositedAt[msg.sender];

        totalShares = totalShares.sub(_shares[msg.sender]);
        delete _shares[msg.sender];
        delete _principal[msg.sender];
        delete _depositedAt[msg.sender];

        INoavaPool(_noavaPool).withdraw(amount);

        uint256 withdrawalFee = _minter.withdrawalFee(
            principal,
            depositTimestamp
        );
        if (withdrawalFee > 0) {
            _stakingToken.safeTransfer(FEE_BOX, withdrawalFee);
            amount = amount.sub(withdrawalFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function harvest() public override onlyKeeper {
        require(
            _noavaPool != address(0),
            "VaultNoavaMaximizer: NoavaPool must set"
        );
        uint256 before = IBEP20(NOAVA).balanceOf(address(this));
        uint256 beforeBNB = address(this).balance;
        uint256 beforeCAKE = IBEP20(CAKE).balanceOf(address(this));

        INoavaPool(_noavaPool).getReward(); // BNB, CAKE, NOAVA

        if (address(this).balance.sub(beforeBNB) > 0) {
            zap.zapIn{value: address(this).balance.sub(beforeBNB)}(NOAVA);
        }

        if (IBEP20(CAKE).balanceOf(address(this)).sub(beforeCAKE) > 0) {
            zap.zapInToken(
                CAKE,
                IBEP20(CAKE).balanceOf(address(this)).sub(beforeCAKE),
                NOAVA
            );
        }

        uint256 harvested = IBEP20(NOAVA).balanceOf(address(this)).sub(before);
        emit Harvested(harvested);

        INoavaPool(_noavaPool).deposit(harvested);
    }

    function withdraw(uint256) external override onlyWhitelisted {
        // we don't use withdraw function.
        revert("N/A");
    }

    // @dev underlying only + withdrawal fee + no perf fee
    function withdrawUnderlying(uint256 _amount) external {
        require(
            _noavaPool != address(0),
            "VaultNoavaMaximizer: NoavaPool must set"
        );
        uint256 amount = Math.min(_amount, _principal[msg.sender]);
        uint256 shares = Math.min(
            amount.mul(totalShares).div(balance()),
            _shares[msg.sender]
        );
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _principal[msg.sender] = _principal[msg.sender].sub(amount);

        INoavaPool(_noavaPool).withdraw(amount);

        uint256 depositTimestamp = _depositedAt[msg.sender];
        uint256 withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
        if (withdrawalFee > 0) {
            _stakingToken.safeTransfer(FEE_BOX, withdrawalFee);
            amount = amount.sub(withdrawalFee);
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function getReward() public override nonReentrant {
        require(
            _noavaPool != address(0),
            "VaultNoavaMaximizer: NoavaPool must set"
        );
        uint256 amount = earned(msg.sender);
        uint256 shares = Math.min(
            amount.mul(totalShares).div(balance()),
            _shares[msg.sender]
        );
        totalShares = totalShares.sub(shares);
        _shares[msg.sender] = _shares[msg.sender].sub(shares);
        _cleanupIfDustShares();

        INoavaPool(_noavaPool).withdraw(amount);

        _stakingToken.safeTransfer(msg.sender, amount);
        emit ProfitPaid(msg.sender, amount, 0);
    }

    function _cleanupIfDustShares() private {
        uint256 shares = _shares[msg.sender];
        if (shares > 0 && shares < DUST) {
            totalShares = totalShares.sub(shares);
            delete _shares[msg.sender];
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setNoavaPool(address noavaPool) external onlyOwner {
        if (_noavaPool != address(0)) {
            _stakingToken.approve(_noavaPool, 0);
        }

        _noavaPool = noavaPool;

        _stakingToken.approve(_noavaPool, uint256(-1));
        if (IBEP20(CAKE).allowance(address(this), address(zap)) == 0) {
            IBEP20(CAKE).approve(address(zap), uint256(-1));
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _deposit(uint256 _amount, address _to)
        private
        nonReentrant
        notPaused
    {
        require(
            _noavaPool != address(0),
            "VaultNoavaMaximizer: NoavaPool must set"
        );
        uint256 _pool = balance();
        _stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 shares = totalShares == 0
            ? _amount
            : (_amount.mul(totalShares)).div(_pool);

        totalShares = totalShares.add(shares);
        _shares[_to] = _shares[_to].add(shares);
        _principal[_to] = _principal[_to].add(_amount);
        _depositedAt[_to] = block.timestamp;

        INoavaPool(_noavaPool).deposit(_amount);
        emit Deposited(_to, _amount);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address tokenAddress, uint256 tokenAmount)
        external
        override
        onlyOwner
    {
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /* ========== MIGRATION ========== */

    function migrate() external onlyOwner {
        require(
            _noavaPool != address(0),
            "VaultNoavaMaximizer: must set NoavaPool"
        );
        uint256 before = IBEP20(NOAVA).balanceOf(address(this));
        INoavaPool(NOAVA_POOL_V1).withdrawAll(); // get NOAVA, WBNB

        zap.zapInToken(WBNB, IBEP20(WBNB).balanceOf(address(this)), NOAVA);
        INoavaPool(_noavaPool).deposit(
            IBEP20(NOAVA).balanceOf(address(this)).sub(before)
        );
    }
}
