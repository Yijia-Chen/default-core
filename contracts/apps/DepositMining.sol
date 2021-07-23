// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/AppContract.sol";
import "./interfaces/DepositMiningV1.sol";
import "../states/interfaces/DepositRewardsV1.sol";
import "../states/interfaces/MembershipsV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


// The Default version of the Masterchef contract. We distribute rewards using the same principle.
// Here's our very first balance sheet mining contract. In the words of a notorious chef:

    // Have fun reading it. Hopefully it's bug-free. God bless.

contract DepositMining is APP_DepositMining, AppContract {

    // MANAGED STATE
    STATE_DepositRewards private _Rewards; // the balance sheet mining contract, our rewards program for depositors.
    IERC20 private _UsdcVaultShares; // the usdc vault shares contract, we give owners of these some dnt vault share rewards too!
    IERC20 private _DntVaultShares; // the dnt vault shares contract, our reward token.

    // Because the vault is a separate contract, our USDC vault registers the deposit to this rewarder
    // for eligibility. This means only members that deposit directly into the Vault have access to rewards. 
    // This also helps cleanly separate contracts handling vault logic vs rewards logic.

    constructor(IERC20 usdcVaultShares_, IERC20 dntVaultShares_, MembershipsV1 memberships_) AppContract(memberships_) {
        _UsdcVaultShares = usdcVaultShares_;
        _DntVaultShares = dntVaultShares_;
    }

    function pendingRewards(address depositor_) public view override returns (uint256) {
        uint256 historicallyAccumulatedRewards = _UsdcVaultShares.balanceOf(depositor_) * _Rewards.accRewardsPerShare();
        uint256 pendingRewards = historicallyAccumulatedRewards - _Rewards.ineligibleRewards(depositor_);

        // just in case somehow rounding error causes pendingRewards to exceed the balance of the tokens in the contract
        if ( pendingRewards > _DntVaultShares.balanceOf(address(this)) ) {
             pendingRewards = _DntVaultShares.balanceOf(address(this));
        }
        return pendingRewards;
    }

    function register(address depositor_) external override onlyApprovedApps returns (bool) {
        _Rewards.resetClaimableRewards(depositor_);
        return true;
    }

    function claimFor(address redeemer_) external override returns (bool) {

        // make sure to reset rewards before transfering shares to prevent reEntrancy attacks
        uint rewards = pendingRewards(redeemer_);
        _Rewards.resetClaimableRewards(redeemer_);
        _DntVaultShares.transfer(redeemer_, rewards);
        return true;
    }

    // ensure only 
    function issueRewards(uint256 newRewards_) external override onlyApprovedApps returns (bool) {
        _Rewards.updateIssuedRewards(newRewards_);
        return true;
    }
}