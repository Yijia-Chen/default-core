// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract IDepositMining {
    // reads
    function pendingRewards(address depositor_) public view returns (uint256) {}

    // writes
    function claim() external returns (bool) {}
    function updateRewards() external returns (bool) {}
}