// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewarderV1 {
    function register(address depositor_) external returns (bool);
    function pendingRewards(address depositor_) external view returns (uint256);
    function claim() external returns (bool);
    function updateRewards() external returns (bool);
}