// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/StateContract.sol";
import "./interfaces/IClaimableRewards.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// The state for claimable rewards from the Rewarder contract please see contracts/application/RewarderV1.sol.
// Calculating rewards is tricky. We are using contracts with logic derived from the OG rewards contract, Sushiswap's Masterchef.sol: 
// https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol

// Copied verbatim from the original contract:

    // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.

// Default's rewarder uses the same mechanism but with drastically simplified logic:
// 1. we have a single pool (USDC Vault), so we can remove all pool allocation logic
// 2. distribution epochs are weekly instead of per block, so 
// 3. there is no special multiplier logic for early participants
// 4. minting happens outside the contract, and reward tokens are sent in (instead of directly minted)

// note: we are also changing the "rewardDebt" variable to "ineligbleRewards" for contract clarity.

// For formal paper for this strategy, see: https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf

contract ClaimableRewards is IClaimableRewards, StateContract {

    IERC20 public override rewardToken; // DNT-VS => vault shares of the native Treasury Vault (DNT)
    IERC20 public override depositorShares; // USDC-VS => vault shares of the incentivized Treasury Vault (USDC)
    uint256 public override accRewardsPerShare = 0; // the total amount of rewardsPerShare accumulated from the start of the rewards program.
    uint256 public override reservedRewards = 0; // the amount of tokens in this address that are reserved for distribution from previous distributions.
    mapping(address => uint256) public override ineligibleRewards; // previously user.rewardDebt in the Masterchef Contract

    constructor(IERC20 depositorShares_, IERC20 rewardToken_) {
        depositorShares = depositorShares_;
        rewardToken = rewardToken_;
    }

    // reset the amount of rewards accumulated so far by the the depositor's shares
    function resetClaimableRewards(address depositor_) external override onlyApprovedApps {
        ineligibleRewards[depositor_] = depositorShares.balanceOf(depositor_) * accRewardsPerShare;
    }

    // update the amount of rewards accumulated by each incentivized share
    function distributeRewards(uint256 newRewards_) external override onlyApprovedApps {
        accRewardsPerShare += newRewards_/depositorShares.totalSupply();
    }
}