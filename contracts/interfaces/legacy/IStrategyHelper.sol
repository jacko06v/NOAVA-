// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/*

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

import "../INoavaMinterV2.sol";

interface IStrategyHelper {
    function tokenPriceInBNB(address _token) external view returns (uint256);

    function cakePriceInBNB() external view returns (uint256);

    function bnbPriceInUSD() external view returns (uint256);

    function profitOf(
        INoavaMinterV2 minter,
        address _flip,
        uint256 amount
    )
        external
        view
        returns (
            uint256 _usd,
            uint256 _noava,
            uint256 _bnb
        );

    function tvl(address _flip, uint256 amount) external view returns (uint256); // in USD

    function tvlInBNB(address _flip, uint256 amount)
        external
        view
        returns (uint256); // in BNB

    function apy(INoavaMinterV2 minter, uint256 pid)
        external
        view
        returns (
            uint256 _usd,
            uint256 _noava,
            uint256 _bnb
        );

    function compoundingAPY(uint256 pid, uint256 compoundUnit)
        external
        view
        returns (uint256);
}
