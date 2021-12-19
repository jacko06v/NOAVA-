// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
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

interface INoavaChef {
    struct UserInfo {
        uint256 balance;
        uint256 pending;
        uint256 rewardPaid;
    }

    struct VaultInfo {
        address token;
        uint256 allocPoint; // How many allocation points assigned to this pool. NOAVAs to distribute per block.
        uint256 lastRewardBlock; // Last block number that NOAVAs distribution occurs.
        uint256 accNoavaPerShare; // Accumulated NOAVAs per share, times 1e12. See below.
    }

    function noavaPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function vaultInfoOf(address vault)
        external
        view
        returns (VaultInfo memory);

    function vaultUserInfoOf(address vault, address user)
        external
        view
        returns (UserInfo memory);

    function pendingNoava(address vault, address user)
        external
        view
        returns (uint256);

    function notifyDeposited(address user, uint256 amount) external;

    function notifyWithdrawn(address user, uint256 amount) external;

    function safeNoavaTransfer(address user) external returns (uint256);

    function updateRewardsOf(address vault) external;
}