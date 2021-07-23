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

    // MANAGED STATES
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
        APP_DepositMining rewarder_,
    ) {
        require(contributorPurse_ != owner(), "Operator.sol constructor(): address _contributorPurse cannot be the contract owner");
        _contributorPurse = contributorPurse_;
        _Memberships = memberships_;
        _DefaultToken = defaultToken_;
        _Epoch = epoch_;
        _DntVault = dntVault_;
        _UsdcVault = dntVault_;
        _Rewarder = rewarder_;
    }

    function incrementEpoch() external override onlyOwner returns (bool) {
        _Epoch.incrementEpoch();
        _DefaultToken.mint(_ISSUANCE);
        _DntVault.deposit(_ISSUANCE);

        // transfer half of the shares minted to the rewarder
        _DntVaultShares.transfer(_Rewarder, _DntVaultShares.balanceOf(address(this))/2);
        
        // transfer the remaining shares to the contributor purse
        _DntVaultShares.transfer(contributorPurse, _DntVaultShares.balanceOf(address(this)));

        emit EpochIncremented(_Epoch.currentEpoch());

        return true;
    }

    function bulkTransfer(address[] calldata contributors_, address[] calldata rewardAmounts_) external override returns (bool) {
        require(msg.sender == _contributorPurse, "Operator.sol bulktransfer(): only the contributor purse can reward contributors");
        require(contributors_.length == rewardsAmounts_.length, "Operator.sol bulktransfer(): input array for contributors and reward amounts must be equal");
        
        uint256 rewardsDistributed = 0;
        for (uint i = 0; i < contributors_.length; i++) {
            require(_Memberships.isMember(contributors_[i]), "Operator.sol bulktransfer(): contributor is not a member");
            _DntVaultShares.transferFrom(_contributorPurse, contributors_[i], rewardAmounts_[i]);
            rewardsDistributed += rewardAmounts_[i]
        }

        emit ContributorsRewarded(_Epoch.currentEpoch(), rewardsDistributed);

        return true;
    }
}
