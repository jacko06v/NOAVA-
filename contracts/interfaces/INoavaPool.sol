// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface INoavaPool {
    function balanceOf(address account) external view returns (uint256);

    function earned(address account) external view returns (uint256[] memory);

    function rewardTokens() external view returns (address[] memory);

    function deposit(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function withdrawAll() external;

    function getReward() external;

    function depositOnBehalf(uint256 _amount, address _to) external;

    function notifyRewardAmounts(uint256[] memory amounts) external;
}
