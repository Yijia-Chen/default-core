// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/AppContract.sol";
import "../state/protocols/MembershipsV1.sol";
import "../state/protocols/DepositorRewardsV1.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IDepositMining.sol";

// The Default version of the Masterchef contract. We distribute rewards using the same principle.
// Here's our very first balance sheet mining contract. In the words of a notorious chef:

    // Have fun reading it. Hopefully it's bug-free. God bless.

contract DepositMining is IDepositMining, AppContract {

    IERC20 private _UsdcVaultShares; // the usdc vault shares contract, we give owners of these some dnt vault share rewards too!
    IERC20 private _DntVaultShares; // the dnt vault shares contract, our reward token.
    DepositorRewardsV1 private _Rewards; // the balance sheet mining contract, our rewards program for depositors.

    // Because the vault is a separate contract, our USDC vault registers the deposit to this rewarder
    // for eligibility. This means only members that deposit directly into the Vault have access to rewards. 
    // This also helps cleanly separate contracts handling vault logic vs rewards logic.

    constructor(IERC20 usdcVaultShares_, IERC20 dntVaultShares_, MembershipsV1 memberships_) AppContract(memberships_) {
        _UsdcVaultShares = usdcVaultShares_;
        _DntVaultShares = dntVaultShares_;
    }

    function pendingRewards(address depositor_) public view override returns (uint256) {
        uint256 totalAccumulatedRewards = _UsdcVaultShares.balanceOf(depositor_) * _Rewards.accRewardsPerShare();
        return totalAccumulatedRewards - _Rewards.ineligibleRewards[depositor_];
    }

    // changes _Rewards.ineligibleRewards ONLY
    function claim() external override onlyMember returns (bool) {
        _DntVaultShares.transfer(msg.sender, pendingRewards);
        _Rewards.resetClaimableRewards(msg.sender);
        return true;
    }

    // changes _Rewards.accDntPerShare ONLY
    function updateRewards() external override returns (bool) {
    }
}