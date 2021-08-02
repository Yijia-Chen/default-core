// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Permissioned.sol";
import "./interfaces/ITreasuryVault.sol";
import "../state/Memberships.sol";
import "../state/VaultShares.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "hardhat/console.sol";

contract TreasuryVaultV1 is ITreasuryVault, Permissioned {

    // MANAGED STATE
    IERC20Metadata public Assets; // vault token/ assets
    VaultShares public Shares; // vault shares/ liabilities

    // INTERNAL VARIABLES
    uint8 public withdrawFeePctg; // fee charged when withdrawing assets from this vault as a percentage (% of shares sent to DAO treasury wallet)

    constructor(IERC20Metadata asset_, uint8 withdrawFeePctg_) {
        Assets = asset_;
        withdrawFeePctg = withdrawFeePctg_;
        _openVault();
    }

    function _openVault() internal {

        // ensure the Vault Shares have a standard naming format
        string memory vaultName = string(abi.encodePacked("Default DAO Treasury Vault Share: ", Assets.symbol()));
        string memory vaultSymbol = string(abi.encodePacked(Assets.symbol(), "-VS"));
        uint8 vaultDecimals = Assets.decimals();

        // create the token contract for this vault
        Shares = VaultShares(new VaultShares(vaultName, vaultSymbol, vaultDecimals));

        // register this contract as an approved application of the VaultShares contract
        Shares.approveApplication(address(this));
        
        // make the owner of the Shares contract the same owner as this contract (dev addr)
        // *** make sure you transfer the ownership of the share contract to the DAO multisig as well
        Shares.transferOwnership(owner());
    }

    // how many tokens you get back for each share you own in the vault
    function pricePerShare() public view override returns (uint256) {
        return Assets.balanceOf(address(this))/Shares.totalSupply();
    }

    // Open the vault. Deposit some token. Get some shares. Members only.
    function deposit(address depositor_, uint256 depositAmount_) external override onlyApprovedApps returns (uint256){
        uint256 totalAssets = Assets.balanceOf(address(this));
        uint256 totalShares = Shares.totalSupply();
        uint256 sharesToMint;

        // If there are no shares in existence or no assets in the vault, then issue the same number of shares as assets deposited.
        if (totalShares == 0 || totalAssets == 0) {
            sharesToMint = depositAmount_;
        } 

        // Calculate and mint the amount of shares the token is worth. The ratio will change overtime, 
        // as token is borrowed/repaid by the DAO. Vault shares decay w/ borrows.
        else {

            // notice we do not use pricePerShare(). This is because we want to perform divisions last
            // in order to to minimize the effects of rounding errors.
            sharesToMint = depositAmount_ * totalShares / totalAssets;
        }

        Shares.issueShares(depositor_, sharesToMint);

        // Lock the token in the contract
        Assets.transferFrom(depositor_, address(this), depositAmount_);

        emit Deposited(depositor_, depositAmount_);

        return sharesToMint;
    }

    // Open the vault. Give depositors tokens and burn the vault shares they used to redeem them.
    function withdraw(address depositor_, uint256 totalSharesRedeemed_) external override onlyApprovedApps returns (bool) {
        
        // the amount of shares that the user redeems for assets, after the fee is applied
        uint256 netSharesRedeemed = totalSharesRedeemed_ * (100 - withdrawFeePctg) / 100;

        // This should be the same as: uint256 shareFeeClaimed = totalSharesRedeemed_ * withdrawFeePctg
        // but we use this method to mitigate potential issues due to rounding errors
        uint256 shareFeeClaimed = totalSharesRedeemed_ - netSharesRedeemed;

        // only apply withdraw amount to the shares redeemed after fee.
        uint256 totalAssetsInVault = Assets.balanceOf(address(this));
        uint256 amountToWithdraw = totalAssetsInVault * netSharesRedeemed / Shares.totalSupply();

        // Ensure withdraw can succeed just in case rounding error somehow causes vault to not have enough assets
        if (amountToWithdraw > totalAssetsInVault) { 
            amountToWithdraw = totalAssetsInVault; 
        }

        // Ensure that all the redeemed shares are burned... although it should be that the 90% of shares are burned
        // and 10% of shares are transferred, we collect the fee through burn/mint to avoid having the user needing 
        // to approve shares for withdrawls.
        Shares.burnShares(depositor_, totalSharesRedeemed_);
        Shares.issueShares(this.owner(), shareFeeClaimed);

        // Claim all rewards before completing withdraw prior to making transfers
        Assets.transfer(depositor_, amountToWithdraw);

        emit Withdrawn(depositor_, amountToWithdraw);

        return true;
    }
    
    // Let the DAO take assets from the vault.
    function borrow(uint256 amount_) external override onlyOwner returns (bool) {
        return Assets.transfer(msg.sender, amount_);
    }
    
    // Repays assets to the vault. Any assets acquired by the DAO goes to the vault.
    function repay(uint256 amount_) external override onlyOwner returns(bool) { 
        return Assets.transferFrom(msg.sender, address(this), amount_);
    }
    
    // Change the fee charged by the DAO upon withdraw from this vault.
    function setFee(uint8 percentage_) external override onlyOwner returns(bool) {
        require(percentage_ >= 0 && percentage_ <= 100, "TreasuryVault setfee(): fee must be between 0-100 (inclusive)");
        withdrawFeePctg = percentage_;   
        
        emit FeeChanged(percentage_);
        
        return true;
    }
}