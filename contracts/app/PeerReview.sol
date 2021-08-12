// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "./interfaces/IContributorBudget.sol";
// import "../state/Memberships.sol";
// import "../state/DefaultToken.sol";
// import "../libraries/Permissioned.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// contract ContributorBudgetV1 is IContributorBudget, Permissioned {
//     event ContributorsRewarded(uint256 rewardsDistributed_);

//     // MANAGED STATE
//     IERC20 public DefVaultShares; // the dnt vault shares contract, our reward token.
//     Memberships public Members;

//     // Because the vault is a separate contract, our USDC vault registers the deposit to this rewarder
//     // for eligibility. This means only members that deposit directly into the Vault have access to rewards. 
//     // This also helps cleanly separate contracts handling vault logic vs rewards logic.

//     constructor(IERC20 defVaultShares, Memberships members_) {
//         DefVaultShares = defVaultShares;
//         Members = members_;
//     }

//     function availableBudget() external view override returns (uint256) {
//         return DefVaultShares.balanceOf(address(this));
//     }

//     function bulkTransfer(address[] calldata contributors_, uint256[] calldata rewardAmounts_) external override onlyApprovedApps returns (bool) {
//         require(contributors_.length == rewardAmounts_.length, "Operator.sol bulkTransfer(): input array for contributors and reward amounts must be equal");
    
//         uint256 rewardsDistributed = 0;
//         for (uint i = 0; i < contributors_.length; i++) {
            
//             // make sure payments are only going to registered members
//             require(Members.isMember(contributors_[i]), "Operator.sol bulkTransfer(): contributor is not a member");
//             DefVaultShares.transfer(contributors_[i], rewardAmounts_[i]);
//             rewardsDistributed += rewardAmounts_[i];
//         }

//         emit ContributorsRewarded(rewardsDistributed);

//         return true;
//     }
// }


// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "../libraries/Permissioned.sol";
// import "./interfaces/IClaimableRewards.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// // The state for claimable rewards from the Rewarder contract please see contracts/application/RewarderV1.sol.
// // Calculating rewards is tricky. We are using contracts with logic derived from the OG rewards contract, Sushiswap's Masterchef.sol: 
// // https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol

// // Copied verbatim from the original contract:

//     // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
//     // entitled to a user but is pending to be distributed is:
//     //
//     //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
//     //
//     // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
//     //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
//     //   2. User receives the pending reward sent to his/her address.
//     //   3. User's `amount` gets updated.
//     //   4. User's `rewardDebt` gets updated.

// // Default's rewarder uses the same mechanism but with drastically simplified logic:
// // 1. we have a single pool (USDC Vault), so we can remove all pool allocation logic
// // 2. distribution epochs are weekly instead of per block, so 
// // 3. there is no special multiplier logic for early participants
// // 4. minting happens outside the contract, and reward tokens are sent in (instead of directly minted)

// // note: we are also changing the "rewardDebt" variable to "ineligbleRewards" for contract clarity.

// // For formal paper for this strategy, see: https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf

// contract ClaimableRewards is IClaimableRewards, Permissioned {

//     IERC20 public override rewardToken; // DNT-VS => vault shares of the native Treasury Vault (DNT)
//     IERC20 public override depositorShares; // USDC-VS => vault shares of the incentivized Treasury Vault (USDC)
//     uint256 public override accRewardsPerShare = 0; // the total amount of rewardsPerShare accumulated from the start of the rewards program, times 1e12
//     mapping(address => uint256) public override ineligibleRewards; // previously user.rewardDebt in the Masterchef Contract
//     uint256 public constant override decimalMultiplier = 1e12; // decimal offset on the accRewardsPerShare, since there's no floats in eth.

//     constructor(IERC20 depositorShares_, IERC20 rewardToken_) {
//         depositorShares = depositorShares_;
//         rewardToken = rewardToken_;
//     }

//     // reset the amount of rewards accumulated so far by the the depositor's shares
//     function resetClaimableRewards(address depositor_) external override onlyApprovedApps {
//         ineligibleRewards[depositor_] = depositorShares.balanceOf(depositor_) * accRewardsPerShare;
//     }

//     // update the amount of rewards accumulated by each incentivized share
//     function distributeRewards(uint256 newRewards_) external override onlyApprovedApps {
//         require(depositorShares.totalSupply() > 0, "ClaimableRewards distributeRewards(): USDC Treasury Vault cannot be empty");
//         accRewardsPerShare += newRewards_ * decimalMultiplier / depositorShares.totalSupply();

//         // @dev note:
//         // There will always be some precision issues due to rounding errors. In solidity, integer
//         // division always rounds towards zero, so 7.9 -> 7. This means that the rewards contract
//         // will always distribute ever slightly fewer shares than it receives, so it collects some dust
//         // over time.
//     }
// }