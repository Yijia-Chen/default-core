// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./states/interfaces/EpochV1.sol";
import "./states/interfaces/MembershipsV1.sol";
import "./apps/interfaces/TreasuryVaultV1.sol";
import "./apps/interfaces/DepositMiningV1.sol";

contract Operator {
   event EpochIncremented(uint16 epoch_);
   event ContributorsRewarded(uint16 epoch_, uint256 rewardsDistributed_);

    // MANAGED STATE
    STATE_Epoch private _Epoch;
    STATE_Memberships private _Memberships;
    IERC20 private _DefaultToken;

    // APP INTEGRATIONS
    APP_TreasuryVault private _DntVault;
    APP_TreasuryVault private _UsdcVault;
    APP_DepositMining private _Rewarder;

    // INTERNAL VARIABLES
    address private _contributorPurse;
    uint256 private constant _ISSUANCE = 1000000;

    constructor(
        address contributorPurse_,
        STATE_Memberships memberships_,
        STATE_Epoch epoch_,
        IERC20 defaultToken_,
        APP_TreasuryVault dntVault_,
        APP_TreasuryVault usdcVault_,
        APP_DepositMining depositMining_,
    ) {
        setContributorPurse(contributorPurse_);
        _Memberships = memberships_;
        _DefaultToken = defaultToken_;
        _Epoch = epoch_;
        _DntVault = dntVault_;
        _UsdcVault = dntVault_;
        _Rewarder = rewarder_;
    }

    function setContributorPurse(address contributorPurse_) external onlyOwner {
        require(contributorPurse_ != owner(), "Operator.sol setContributorPurse(): address _contributorPurse must be different from the contract owner");
        _contributorPurse = contributorPurse_;
    }

    function incrementEpoch() external override onlyOwner returns (bool) {
        _Epoch.incrementEpoch();

        // issue half of the shares to be minted to the rewarder based on the current share/ratio in the Dnt vault
        _DepositMining.issueRewards(ISSUANCE/_DntVault.PricePerShare());

        // transfer the other half of the shares to be minted to the contributor purse
        _DefaultToken.mint(_ISSUANCE/2);
        _DntVault.deposit(_ISSUANCE/2);
        _DntVaultShares.transfer(contributorPurse, _DntVaultShares.balanceOf(address(this)));

        emit EpochIncremented(_Epoch.currentEpoch());

        return true;
    }

    function distributeContributorRewards(address[] calldata contributors_, uint256[] calldata rewardAmounts_) external override returns (bool) {
        require(msg.sender == _contributorPurse, "Operator.sol distributeContributorRewards(): only the contributor purse can reward contributors");
        require(contributors_.length == rewardsAmounts_.length, "Operator.sol distributeContributorRewards(): input array for contributors and reward amounts must be equal");
        
        uint256 rewardsDistributed = 0;
        for (uint i = 0; i < contributors_.length; i++) {
            
            // make sure payments are only going to registered members
            require(_Memberships.isMember(contributors_[i]), "Operator.sol distributeContributorRewards(): contributor is not a member");
            _DntVaultShares.transferFrom(_contributorPurse, contributors_[i], rewardAmounts_[i]);
            rewardsDistributed += rewardAmounts_[i]
        }

        require (_DntVaultShares.balanceOf(address(this)) == 0, "Operator.sol distributeContributorRewards(): not all rewards were distributed");

        emit ContributorsRewarded(_Epoch.currentEpoch(), rewardsDistributed);

        return true;
    }

}
