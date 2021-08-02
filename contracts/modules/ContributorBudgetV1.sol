// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IContributorBudget.sol";
import "../state/Memberships.sol";
import "../state/DefaultToken.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract ContributorBudgetV1 is IContributorBudget {
    event ContributorsRewarded(uint256 rewardsDistributed_);


    // MANAGED STATE
    IERC20 public DntVaultShares; // the dnt vault shares contract, our reward token.
    Memberships public Members;

    // INTERNAL VARIABLE;
    uint256 public constant EPOCH_REWARD = 500000;

    // Because the vault is a separate contract, our USDC vault registers the deposit to this rewarder
    // for eligibility. This means only members that deposit directly into the Vault have access to rewards. 
    // This also helps cleanly separate contracts handling vault logic vs rewards logic.

    constructor(IERC20 dntVaultShares_, Memberships members_) {
        DntVaultShares = dntVaultShares_;
        Members = members_;
    }

    function currentBalance() external view override returns (uint256) {
        return DntVaultShares.balanceOf(address(this));
    }

    function bulkTransfer(address[] calldata contributors_, uint256[] calldata rewardAmounts_) external override returns (bool) {
        require(contributors_.length == rewardAmounts_.length, "Operator.sol distributeContributorRewards(): input array for contributors and reward amounts must be equal");
        
        uint256 rewardsDistributed = 0;
        for (uint i = 0; i < contributors_.length; i++) {
            
            // make sure payments are only going to registered members
            require(Members.isMember(contributors_[i]), "Operator.sol distributeContributorRewards(): contributor is not a member");
            DntVaultShares.transfer(contributors_[i], rewardAmounts_[i]);
            rewardsDistributed += rewardAmounts_[i];
        }

        emit ContributorsRewarded(rewardsDistributed);

        return true;
    }
}