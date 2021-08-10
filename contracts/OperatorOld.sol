// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../modules/TreasuryVaultV1.sol";
import "../modules/BalanceSheetMiningV1.sol";
import "../modules/ContributorBudgetV1.sol";
import "../state/DefaultToken.sol";
import "../state/Memberships.sol";
import "../state/VaultShares.sol";

interface IERC20Mintable is IERC20 {
    function mint(uint256 amount_) external;
}

contract Operator is Ownable {
   event EpochIncrementedTo(uint16 epoch_);


    // MODULES
    TreasuryVaultV1 public DefVault;
    TreasuryVaultV1 public UsdcVault;
    BalanceSheetMiningV1 public Mining;
    ContributorBudgetV1 public Budget;

    // STATE
    Memberships public Members;
    IERC20Mintable public DefToken;
    VaultShares public DefShares;

    // INTERNAL VARIABLES
    uint16 public currentEpoch = 0;
    uint256 public constant EPOCH_REWARDS = 1000000e18;

    modifier onlyMember() {
        require(Members.isMember(msg.sender) == true, "Operator.sol onlyMember(): only members of the DAO can call this contract");
        _;
    }

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
        DefShares = DefVault.Shares();
    }

    function incrementEpoch() external onlyOwner returns (bool) {
        currentEpoch++;
        DefToken.mint(EPOCH_REWARDS);
        DefToken.approve(address(DefVault), EPOCH_REWARDS);
        uint256 newShares = DefVault.deposit(address(this), EPOCH_REWARDS);

        // transfer half of new shares to mining program
        DefShares.transfer(address(Mining), newShares/2);
        Mining.issueRewards(newShares/2);
        
        // transfer other half to contributor rewards
        DefShares.transfer(address(Budget), DefShares.balanceOf(address(this)));

        emit EpochIncrementedTo(currentEpoch);

        return true;
    }

    function depositUsdc(uint256 amount_) external onlyMember() returns (bool) {
        UsdcVault.deposit(msg.sender, amount_);
        Mining.register(msg.sender);
        return true;
    }
    
    function withdrawUsdc(uint256 sharesToRedeem_) external onlyMember() returns (bool) {
        Mining.claimRewardsFor(msg.sender);
        UsdcVault.withdraw(msg.sender, sharesToRedeem_);
        return true;
    }

    function claimRewards() external onlyMember() returns (bool) {
        Mining.claimRewardsFor(msg.sender);
        return true;
    }
}
