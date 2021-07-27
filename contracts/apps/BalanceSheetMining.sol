// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/AppContract.sol";
import "./interfaces/IBalanceSheetMining.sol";
import "../state/ClaimableRewards.sol";
import "../state/Memberships.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// The Default version of the Masterchef contract. We distribute mining rewards using the same principle.
// Here's our very first balance sheet mining contract. In the words of a notorious chef:

    // Have fun reading it. Hopefully it's bug-free. God bless.

contract BalanceSheetMining is IBalanceSheetMining, AppContract {

    // MANAGED STATE
    ClaimableRewards public Rewards; // the balance sheet mining contract, our rewards program for depositors.
    IERC20 public UsdcVaultShares; // the usdc vault shares contract, we give owners of these some dnt vault share rewards too!
    IERC20 public DntVaultShares; // the dnt vault shares contract, our reward token.

    // Because the vault is a separate contract, our USDC vault registers the deposit to this rewarder
    // for eligibility. This means only members that deposit directly into the Vault have access to rewards. 
    // This also helps cleanly separate contracts handling vault logic vs rewards logic.

    constructor(IERC20 usdcVaultShares_, IERC20 dntVaultShares_, ClaimableRewards rewards_, Memberships memberships_) AppContract(memberships_) {
        UsdcVaultShares = usdcVaultShares_;
        DntVaultShares = dntVaultShares_;
        Rewards = rewards_;
    }

    function pendingRewards(address depositor_) public view override returns (uint256) {
        uint256 totalHistoricalRewards = UsdcVaultShares.balanceOf(depositor_) * Rewards.accRewardsPerShare();
        uint256 finalDepositorRewards = (totalHistoricalRewards - Rewards.ineligibleRewards(depositor_)) / Rewards.decimalMultiplier();

        // just in case somehow rounding error causes finalDepositorRewards to exceed the balance of the tokens in the contract
        if ( finalDepositorRewards > DntVaultShares.balanceOf(address(this)) ) {
             finalDepositorRewards = DntVaultShares.balanceOf(address(this));
        }
        return finalDepositorRewards;
    }

    function register(address depositor_) external override onlyApprovedApps returns (bool) {
        Rewards.resetClaimableRewards(depositor_);
        return true;
    }

    function claimRewardsFor(address redeemer_) external override returns (bool) {
        uint rewards = pendingRewards(redeemer_);
        Rewards.resetClaimableRewards(redeemer_);
        DntVaultShares.transfer(redeemer_, rewards);
        return true;
    }

    function issueRewards(uint256 newRewards_) external override onlyApprovedApps returns (bool) {
        Rewards.distributeRewards(newRewards_);
        return true;
    }
}