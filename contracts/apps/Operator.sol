// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../state/Memberships.sol";
import "../modules/TreasuryVaultV1.sol";
import "../modules/BalanceSheetMiningV1.sol";
import "../modules/ContributorBudgetV1.sol";
import "../state/DefaultToken.sol";


interface IERC20Mintable is IERC20 {
    function mint(uint256 amount_) external;
}

contract Operator is Ownable {
   event EpochIncrementedTo(uint16 epoch_);

    // MODULES
    Memberships public Members;
    IERC20Mintable public DefToken;
    TreasuryVaultV1 public DefVault;
    TreasuryVaultV1 public UsdcVault;
    BalanceSheetMiningV1 public Mining;
    ContributorBudgetV1 public Budget;

    // INTERNAL VARIABLES
    uint16 public currentEpoch = 0;
    uint256 public constant MINING_EPOCH_REWARDS = 500000 * 1e18;
    uint256 public constant CONTRIBUTOR_EPOCH_REWARDS = 500000 * 1e18;

    constructor(
        Memberships members_,
        IERC20Mintable defToken_,
        TreasuryVaultV1 usdcVault_,
        TreasuryVaultV1 defVault_,
        BalanceSheetMiningV1 mining_,
        ContributorBudgetV1 budget_
    ) {
        Members = members_;
        DefToken = defToken_;
        DefVault = defVault_;
        UsdcVault = usdcVault_;
        Mining = mining_;
        Budget = budget_;

    }

    function incrementEpoch() external onlyOwner returns (bool) {
        currentEpoch++;

        // Balance Sheet Mining Program
        DefToken.mint(MINING_EPOCH_REWARDS);
        DefToken.transfer(address(Mining), MINING_EPOCH_REWARDS);
        uint256 newShares = DefVault.deposit(address(Mining), MINING_EPOCH_REWARDS);
        Mining.issueRewards(newShares);

        // Contributor Rewards
        DefToken.mint(500000 * 1e18);
        DefToken.transfer(address(Budget), CONTRIBUTOR_EPOCH_REWARDS);
        DefVault.deposit(address(Budget), CONTRIBUTOR_EPOCH_REWARDS);

        emit EpochIncrementedTo(currentEpoch);

        return true;
    }
}
