// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

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

library PoolConstant {
    enum PoolTypes {
        NoavaStake_deprecated, // no perf fee
        NoavaFlip_deprecated, // deprecated
        CakeStake,
        FlipToFlip,
        FlipToCake,
        Noava, // no perf fee
        NoavaBNB,
        Venus,
        Collateral,
        NoavaToNoava,
        FlipToReward,
        NoavaV2,
        Qubit,
        bQBT,
        flipToQBT
    }

    struct PoolInfo {
        address pool;
        uint256 balance;
        uint256 principal;
        uint256 available;
        uint256 tvl;
        uint256 utilized;
        uint256 liquidity;
        uint256 pBASE;
        uint256 pNOAVA;
        uint256 depositedAt;
        uint256 feeDuration;
        uint256 feePercentage;
        uint256 portfolio;
    }

    struct RelayInfo {
        address pool;
        uint256 balanceInUSD;
        uint256 debtInUSD;
        uint256 earnedInUSD;
    }

    struct RelayWithdrawn {
        address pool;
        address account;
        uint256 profitInETH;
        uint256 lossInETH;
    }
}
