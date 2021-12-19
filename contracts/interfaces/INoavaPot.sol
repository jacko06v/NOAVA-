// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import {PotConstant} from "../library/PotConstant.sol";

interface INoavaPot {
    function potInfoOf(address _account)
        external
        view
        returns (PotConstant.PotInfo memory, PotConstant.PotInfoMe memory);

    function deposit(uint256 amount) external;

    function withdrawAll(uint256 amount) external;
}
