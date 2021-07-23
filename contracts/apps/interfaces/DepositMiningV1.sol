// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract APP_DepositMining {
    // reads
    function pendingRewards(address depositor_) public view returns (uint256) {}

    // writes
    function claimFor(address redeemer_) external returns (bool) {}
    function issueRewards(address newRewards_) external returns (bool) {}
}