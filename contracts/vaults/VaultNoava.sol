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

import "../interfaces/IStrategy.sol";
import "../interfaces/INoavaMinter.sol";
import "../interfaces/INoavaChef.sol";
import "./VaultController.sol";
import {PoolConstant} from "../library/PoolConstant.sol";

contract VaultNoava is VaultController, IStrategy, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    /* ========== CONSTANTS ============= */

    address private NOAVA;
    PoolConstant.PoolTypes public constant override poolType =
        PoolConstant.PoolTypes.Noava;

    /* ========== STATE VARIABLES ========== */

    uint256 public override pid;
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) private _depositedAt;

    /* ========== INITIALIZER ========== */

    function initialize(address _noava) external initializer {
        NOAVA = _noava;
        __VaultController_initi(IBEP20(NOAVA), NOAVA);
        __ReentrancyGuard_init();
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
        return NOAVA;
    }

    function priceShare() external view override returns (uint256) {
        return 1e18;
    }

    function earned(address) public view override returns (uint256) {
        return 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function deposit(uint256 amount) public override {
        _deposit(amount, msg.sender);
    }

    function depositAll() external override {
        deposit(_stakingToken.balanceOf(msg.sender));
    }

    function withdraw(uint256 amount) public override nonReentrant {
        require(amount > 0, "VaultNoava: amount must be greater than zero");
        _noavaChef.notifyWithdrawn(msg.sender, amount);

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);

        uint256 withdrawalFee;
        if (canMint()) {
            uint256 depositTimestamp = _depositedAt[msg.sender];
            withdrawalFee = _minter.withdrawalFee(amount, depositTimestamp);
            if (withdrawalFee > 0) {
                _minter.mintFor(
                    address(_stakingToken),
                    withdrawalFee,
                    0,
                    msg.sender,
                    depositTimestamp
                );
                amount = amount.sub(withdrawalFee);
            }
        }

        _stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount, withdrawalFee);
    }

    function withdrawAll() external override {
        uint256 _withdraw = withdrawableBalanceOf(msg.sender);
        if (_withdraw > 0) {
            withdraw(_withdraw);
        }
        getReward();
    }

    function getReward() public override nonReentrant {
        uint256 noavaAmount = _noavaChef.safeNoavaTransfer(msg.sender);
        emit NoavaPaid(msg.sender, noavaAmount, 0);
    }

    function harvest() public override {}

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setMinter(address newMinter) public override onlyOwner {
        VaultController.setMinter(newMinter);
    }

    function setNoavaChef(INoavaChef _chef) public override onlyOwner {
        require(
            address(_noavaChef) == address(0),
            "VaultNoava: setNoavaChef only once"
        );
        VaultController.setNoavaChef(INoavaChef(_chef));
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _deposit(uint256 amount, address _to)
        private
        nonReentrant
        notPaused
    {
        require(amount > 0, "VaultNoava: amount must be greater than zero");
        _noavaChef.updateRewardsOf(address(this));

        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        _depositedAt[_to] = block.timestamp;
        _stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        _noavaChef.notifyDeposited(msg.sender, amount);
        emit Deposited(_to, amount);
    }

    /* ========== SALVAGE PURPOSE ONLY ========== */

    function recoverToken(address tokenAddress, uint256 tokenAmount)
        external
        override
        onlyOwner
    {
        require(
            tokenAddress != address(_stakingToken),
            "VaultNoava: cannot recover underlying token"
        );
        IBEP20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}
