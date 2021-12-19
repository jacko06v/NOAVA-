// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface INoavaMinter {
    function isMinter(address) external view returns (bool);

    function amountNoavaToMint(uint256 bnbProfit)
        external
        view
        returns (uint256);

    function amountNoavaToMintForNoavaBNB(uint256 amount, uint256 duration)
        external
        view
        returns (uint256);

    function withdrawalFee(uint256 amount, uint256 depositedAt)
        external
        view
        returns (uint256);

    function performanceFee(uint256 profit) external view returns (uint256);

    function mintFor(
        address flip,
        uint256 _withdrawalFee,
        uint256 _performanceFee,
        address to,
        uint256 depositedAt
    ) external;

    function mintForNoavaBNB(
        uint256 amount,
        uint256 duration,
        address to
    ) external;

    function noavaPerProfitBNB() external view returns (uint256);

    function WITHDRAWAL_FEE_FREE_PERIOD() external view returns (uint256);

    function WITHDRAWAL_FEE() external view returns (uint256);

    function setMinter(address minter, bool canMint) external;
}
