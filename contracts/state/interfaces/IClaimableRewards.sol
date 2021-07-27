// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IClaimableRewards {
    // properties (reads)
    function rewardToken() external view returns (IERC20);
    function depositorShares() external view returns (IERC20);
    function accRewardsPerShare() external view returns (uint256);
    function ineligibleRewards(address depositor_) external view returns (uint256);
    function decimalMultiplier() external view returns (uint256);

    // state changes (writes)
    function resetClaimableRewards(address depositor_) external;
    function distributeRewards(uint256 newRewards_) external;
}