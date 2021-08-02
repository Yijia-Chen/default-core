// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBalanceSheetMining {
    // reads
    function pendingRewards(address depositor_) external view returns (uint256);

    // writes
    function register(address redeemer_) external returns (bool);
    function claimRewardsFor(address redeemer_) external returns (bool);
    function issueRewards(uint256 newRewards_) external returns (bool);
}