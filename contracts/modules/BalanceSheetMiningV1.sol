// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/AppContract.sol";
import "./interfaces/IBalanceSheetMining.sol";
import "../state/ClaimableRewards.sol";
import "../state/Memberships.sol";
import "../state/DefaultToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "hardhat/console.sol";

// The Default version of the Masterchef contract. We distribute mining rewards using the same principle.
// Here's our very first balance sheet mining contract. In the words of a notorious chef:

    // Have fun reading it. Hopefully it's bug-free. God bless.

contract BalanceSheetMiningV1 is IBalanceSheetMining, Permissioned {

    // MANAGED STATE
    ClaimableRewards public Rewards; // the balance sheet mining contract, our rewards program for depositors.
    IERC20 public UsdcVaultShares; // the usdc vault shares contract, we give owners of these some dnt vault share rewards too!
    IERC20 public DefVaultShares; // the dnt vault shares contract, our reward token.

    // INTERNAL VARIABLE;
    uint256 public constant EPOCH_REWARD = 500000;

    // Because the vault is a separate contract, our USDC vault registers the deposit to this rewarder
    // for eligibility. This means only members that deposit directly into the Vault have access to rewards. 
    // This also helps cleanly separate contracts handling vault logic vs rewards logic.

    constructor(IERC20 usdcVaultShares_, IERC20 defVaultShares_) {
        UsdcVaultShares = usdcVaultShares_;
        DefVaultShares = defVaultShares_;
        Rewards = new ClaimableRewards(UsdcVaultShares, DefVaultShares);
        Rewards.approveApplication(address(this));
    }

    function pendingRewards(address depositor_) public view override onlyApprovedApps returns (uint256) {
        uint256 totalHistoricalRewards = UsdcVaultShares.balanceOf(depositor_) * Rewards.accRewardsPerShare();
        uint256 finalDepositorRewards = (totalHistoricalRewards - Rewards.ineligibleRewards(depositor_)) / Rewards.decimalMultiplier();

        // just in case somehow rounding error causes finalDepositorRewards to exceed the balance of the tokens in the contract
        if ( finalDepositorRewards > DefVaultShares.balanceOf(address(this)) ) {
             finalDepositorRewards = DefVaultShares.balanceOf(address(this));
        }

        return finalDepositorRewards;
    }

    function register(address depositor_) external override onlyApprovedApps returns (bool) {
        Rewards.resetClaimableRewards(depositor_);
        return true;
    }

    function claimRewardsFor(address redeemer_) external override onlyApprovedApps returns (bool) {
        uint rewards = pendingRewards(redeemer_);
        Rewards.resetClaimableRewards(redeemer_);
        DefVaultShares.transfer(redeemer_, rewards);
        return true;
    }

    function issueRewards(uint256 newShares_) external override onlyApprovedApps returns (bool) {
        Rewards.distributeRewards(newShares_);
        return true;
    }
}