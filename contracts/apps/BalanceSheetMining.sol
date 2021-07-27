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
    ClaimableRewards private _Rewards; // the balance sheet mining contract, our rewards program for depositors.
    IERC20 private _UsdcVaultShares; // the usdc vault shares contract, we give owners of these some dnt vault share rewards too!
    IERC20 private _DntVaultShares; // the dnt vault shares contract, our reward token.

    // Because the vault is a separate contract, our USDC vault registers the deposit to this rewarder
    // for eligibility. This means only members that deposit directly into the Vault have access to rewards. 
    // This also helps cleanly separate contracts handling vault logic vs rewards logic.

    constructor(IERC20 usdcVaultShares_, IERC20 dntVaultShares_, ClaimableRewards rewards_, Memberships memberships_) AppContract(memberships_) {
        _UsdcVaultShares = usdcVaultShares_;
        _DntVaultShares = dntVaultShares_;
        _Rewards = rewards_;
    }

    function pendingRewards(address depositor_) public view override returns (uint256) {
        uint256 historicallyAccumulatedRewards = _UsdcVaultShares.balanceOf(depositor_) * _Rewards.accRewardsPerShare();
        uint256 rewardsToDistribute = historicallyAccumulatedRewards - _Rewards.ineligibleRewards(depositor_);

        // just in case somehow rounding error causes rewardsToDistribute to exceed the balance of the tokens in the contract
        if ( rewardsToDistribute > _DntVaultShares.balanceOf(address(this)) ) {
             rewardsToDistribute = _DntVaultShares.balanceOf(address(this));
        }
        return rewardsToDistribute;
    }

    function register(address depositor_) external override onlyApprovedApps returns (bool) {
        _Rewards.resetClaimableRewards(depositor_);
        return true;
    }

    function claimRewardsFor(address redeemer_) external override returns (bool) {
        uint rewards = pendingRewards(redeemer_);
        _Rewards.resetClaimableRewards(redeemer_);
        _DntVaultShares.transfer(redeemer_, rewards);
        return true;
    }

    function issueRewards(uint256 newRewards_) external override onlyApprovedApps returns (bool) {
        _Rewards.distributeRewards(newRewards_);
        return true;
    }
}