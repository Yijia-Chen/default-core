// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./state/Epoch.sol";
import "./state/Memberships.sol";
import "./apps/TreasuryVault.sol";
import "./apps/DepositMining.sol";

interface IERC20Mintable {
    function mint(uint256 amount_) external;
}

contract Operator is Ownable {
   event EpochIncremented(uint16 epoch_);
   event ContributorsRewarded(uint16 epoch_, uint256 rewardsDistributed_);

    // MANAGED STATE
    Epoch private _Epoch;
    Memberships private _Memberships;
    IERC20Mintable private _DefaultToken;
    IERC20 private _DntVaultShares;

    // APP INTEGRATIONS
    TreasuryVault private _DntVault;
    DepositMining private _DepositMining;

    // INTERNAL VARIABLES
    address private _contributorPurse = address(0);
    uint256 private constant _ISSUANCE = 1000000;

    constructor(
        address contributorPurse_,
        Epoch epoch_,
        Memberships memberships_,
        IERC20Mintable defaultToken_,
        IERC20 dntVaultShares_,
        TreasuryVault dntVault_,
        DepositMining depositMining_
    ) {
        _setContributorPurse(contributorPurse_);
        _Epoch = epoch_;
        _Memberships = memberships_;
        _DefaultToken = defaultToken_;
        _DntVault = dntVault_;
        _DntVaultShares = dntVaultShares_;
        _DepositMining = depositMining_;
    }

    function changeContributorPurse(address contributorPurse_) external onlyOwner {
        _setContributorPurse(contributorPurse_);
    }

    function _setContributorPurse(address contributorPurse_) internal {
        require(contributorPurse_ != owner(), "Operator.sol setContributorPurse(): address _contributorPurse must be different from the contract owner");
        _contributorPurse = contributorPurse_;
    }

    function incrementEpoch() external onlyOwner returns (bool) {
        _Epoch.incrementEpoch();
        _DefaultToken.mint(_ISSUANCE);
        _DntVault.deposit(_ISSUANCE);

        // issue half of the shares to be minted to the rewarder based on the current share/ratio in the Dnt vault
        uint256 dntSharesForMiningRewards = _DntVaultShares.balanceOf(address(this)) / 2;
        
        _DntVaultShares.transfer(_contributorPurse, dntSharesForMiningRewards);
        _DepositMining.issueRewards(dntSharesForMiningRewards);

        // transfer the remaining half of the shares to be minted to the contributor purse
        _DntVaultShares.transfer(_contributorPurse, _DntVaultShares.balanceOf(address(this)));

        emit EpochIncremented(_Epoch.currentEpoch());

        return true;
    }

    function distributeContributorRewards(address[] calldata contributors_, uint256[] calldata rewardAmounts_) external returns (bool) {
        require(msg.sender == _contributorPurse, "Operator.sol distributeContributorRewards(): only the contributor purse can reward contributors");
        require(contributors_.length == rewardAmounts_.length, "Operator.sol distributeContributorRewards(): input array for contributors and reward amounts must be equal");
        
        uint256 rewardsDistributed = 0;
        for (uint i = 0; i < contributors_.length; i++) {
            
            // make sure payments are only going to registered members
            require(_Memberships.isMember(contributors_[i]), "Operator.sol distributeContributorRewards(): contributor is not a member");
            _DntVaultShares.transferFrom(_contributorPurse, contributors_[i], rewardAmounts_[i]);
            rewardsDistributed += rewardAmounts_[i];
        }

        require (_DntVaultShares.balanceOf(address(this)) == 0, "Operator.sol distributeContributorRewards(): not all rewards were distributed");

        emit ContributorsRewarded(_Epoch.currentEpoch(), rewardsDistributed);

        return true;
    }

}
