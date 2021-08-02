// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IContributorBudget {
    // reads
    function availableBudget() external view returns (uint256);

    // writes
    function bulkTransfer(address[] calldata contributors_, uint256[] calldata rewards_) external returns (bool);
}