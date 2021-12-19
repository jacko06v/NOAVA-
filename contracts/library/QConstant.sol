// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*


          _____                   _______                   _____                    _____                    _____          
         /\    \                 /::\    \                 /\    \                  /\    \                  /\    \         
        /::\____\               /::::\    \               /::\    \                /::\____\                /::\    \        
       /::::|   |              /::::::\    \             /::::\    \              /:::/    /               /::::\    \       
      /:::::|   |             /::::::::\    \           /::::::\    \            /:::/    /               /::::::\    \      
     /::::::|   |            /:::/~~\:::\    \         /:::/\:::\    \          /:::/    /               /:::/\:::\    \     
    /:::/|::|   |           /:::/    \:::\    \       /:::/__\:::\    \        /:::/____/               /:::/__\:::\    \    
   /:::/ |::|   |          /:::/    / \:::\    \     /::::\   \:::\    \       |::|    |               /::::\   \:::\    \   
  /:::/  |::|   | _____   /:::/____/   \:::\____\   /::::::\   \:::\    \      |::|    |     _____    /::::::\   \:::\    \  
 /:::/   |::|   |/\    \ |:::|    |     |:::|    | /:::/\:::\   \:::\    \     |::|    |    /\    \  /:::/\:::\   \:::\    \ 
/:: /    |::|   /::\____\|:::|____|     |:::|    |/:::/  \:::\   \:::\____\    |::|    |   /::\____\/:::/  \:::\   \:::\____\
\::/    /|::|  /:::/    / \:::\    \   /:::/    / \::/    \:::\  /:::/    /    |::|    |  /:::/    /\::/    \:::\  /:::/    /
 \/____/ |::| /:::/    /   \:::\    \ /:::/    /   \/____/ \:::\/:::/    /     |::|    | /:::/    /  \/____/ \:::\/:::/    / 
         |::|/:::/    /     \:::\    /:::/    /             \::::::/    /      |::|____|/:::/    /            \::::::/    /  
         |::::::/    /       \:::\__/:::/    /               \::::/    /       |:::::::::::/    /              \::::/    /   
         |:::::/    /         \::::::::/    /                /:::/    /        \::::::::::/____/               /:::/    /    
         |::::/    /           \::::::/    /                /:::/    /          ~~~~~~~~~~                    /:::/    /     
         /:::/    /             \::::/    /                /:::/    /                                        /:::/    /      
        /:::/    /               \::/____/                /:::/    /                                        /:::/    /       
        \::/    /                 ~~                      \::/    /                                         \::/    /        
         \/____/                                           \/____/                                           \/____/         
                                                                                                                             


*
* MIT License
* ===========
*
* Copyright (c) 2021 QubitFinance
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

library QConstant {
    uint256 public constant CLOSE_FACTOR_MIN = 5e16;
    uint256 public constant CLOSE_FACTOR_MAX = 9e17;
    uint256 public constant COLLATERAL_FACTOR_MAX = 9e17;

    struct MarketInfo {
        bool isListed;
        uint256 borrowCap;
        uint256 collateralFactor;
    }

    struct BorrowInfo {
        uint256 borrow;
        uint256 interestIndex;
    }

    struct AccountSnapshot {
        uint256 qTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRate;
    }

    struct AccrueSnapshot {
        uint256 totalBorrow;
        uint256 totalReserve;
        uint256 accInterestIndex;
    }

    struct DistributionInfo {
        uint256 supplySpeed;
        uint256 borrowSpeed;
        uint256 totalBoostedSupply;
        uint256 totalBoostedBorrow;
        uint256 accPerShareSupply;
        uint256 accPerShareBorrow;
        uint256 accruedAt;
    }

    struct DistributionAccountInfo {
        uint256 accruedQubit;
        uint256 boostedSupply; // effective(boosted) supply balance of user  (since last_action)
        uint256 boostedBorrow; // effective(boosted) borrow balance of user  (since last_action)
        uint256 accPerShareSupply; // Last integral value of Qubit rewards per share. ∫(qubitRate(t) / totalShare(t) dt) from 0 till (last_action)
        uint256 accPerShareBorrow; // Last integral value of Qubit rewards per share. ∫(qubitRate(t) / totalShare(t) dt) from 0 till (last_action)
    }

    struct DistributionAPY {
        uint256 apySupplyQBT;
        uint256 apyBorrowQBT;
        uint256 apyAccountSupplyQBT;
        uint256 apyAccountBorrowQBT;
    }
}
