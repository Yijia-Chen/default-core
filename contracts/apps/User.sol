// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../state/Epoch.sol";
import "../state/Memberships.sol";
import "../modules/TreasuryVaultV1.sol";
import "../modules/BalanceSheetMiningV1.sol";

// deposit() -> Deposit & Register
// withdraw() -> withdraw & Claim
// claim() -> Claim rewards


contract User {
   event EpochIncremented(uint16 epoch_);
   event ContributorsRewarded(uint16 epoch_, uint256 rewardsDistributed_);

    // MODULES
    Memberships public _memberships;
    TreasuryVaultV1 public UsdcVault;
    TreasuryVaultV1 public DntVault;
    BalanceSheetMiningV1 public BalanceSheetMining;    

    // INTERNAL VARIABLES

    modifier onlyMember() {
        require(_memberships.isMember(msg.sender) == true, "User.sol onlyMember(): only members of the DAO can call this contract");
        _;
    }

    // INTERFACE

    constructor(
        Memberships memberships_,
        TreasuryVaultV1 dntVault_,
        TreasuryVaultV1 usdcVault_,
        BalanceSheetMiningV1 balanceSheetMining_
    ) {
        _memberships = memberships_;
        DntVault = dntVault_;
        UsdcVault = usdcVault_;
        BalanceSheetMining = balanceSheetMining_;
    }

    function depositUsdc(uint256 amount_) external onlyMember() returns (bool) {
        UsdcVault.deposit(msg.sender, amount_);
        BalanceSheetMining.register(msg.sender);
        return true;
    }
    
    function withdrawUsdc(uint256 sharesToRedeem_) external onlyMember() returns (bool) {
        BalanceSheetMining.claimRewardsFor(msg.sender);
        UsdcVault.withdraw(msg.sender, sharesToRedeem_);
        return true;
    }

    function claimRewards() external onlyMember() returns (bool) {
        BalanceSheetMining.claimRewardsFor(msg.sender);
        return true;
    }
}