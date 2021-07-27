// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/AppContract.sol";
import "./interfaces/ITreasuryVault.sol";
import "./BalanceSheetMining.sol";
import "../state/Memberships.sol";
import "../state/VaultShares.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract TreasuryVault is ITreasuryVault, AppContract {

    // MANAGED STATE
    IERC20Metadata public Assets; // vault token/ assets
    VaultShares public Shares; // vault shares/ liabilities

    // APP INTEGRATIONS
    BalanceSheetMining public Rewarder; // register deposits in the rewarder contract

    // INTERNAL VARIABLES
    uint8 private _withdrawFeePctg; // fee charged when withdrawing assets from this vault as a percentage (% of shares sent to DAO treasury wallet)
    bool private _rewardableVault; // flag for whether the vault produces rewards: yes for USDC, no for DNT. This also allows us to open new incentivized vaults in the future.

    constructor(IERC20Metadata asset_, uint8 withdrawFeePctg_, bool rewardableVault_, Memberships memberships_) AppContract(memberships_) {
        Assets = asset_;
        _withdrawFeePctg = withdrawFeePctg_;
        _rewardableVault = rewardableVault_;
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
    function deposit(uint256 depositAmount_) external override onlyMember returns (bool){
        uint256 totalAssets = Assets.balanceOf(address(this));
        uint256 totalShares = Shares.totalSupply();

        // If there are no shares in existence or no assets in the vault, then issue the same number of shares as assets deposited.
        if (totalShares == 0 || totalAssets == 0) {
            Shares.issueShares(msg.sender, depositAmount_);
        } 

        // Calculate and mint the amount of shares the token is worth. The ratio will change overtime, 
        // as token is borrowed/repaid by the DAO. Vault shares decay w/ borrows.
        else {

            // notice we do not use pricePerShare(). This is because we want to perform divisions last
            // in order to to minimize the effects of rounding errors.
            uint256 sharesToMint = depositAmount_ * totalShares / totalAssets;
            Shares.issueShares(msg.sender, sharesToMint);
        }

        // Lock the token in the contract
        Assets.transferFrom(msg.sender, address(this), depositAmount_);

        // If this vault gives rewards for deposits, register the depositor with the rewards contract
        if (_rewardableVault) {
            Rewarder.register(msg.sender);
        }

        emit Deposited(msg.sender, depositAmount_);

        return true;
    }

    // Open the vault. Give depositors tokens and burn the vault shares they used to redeem them.
    function withdraw(uint256 sharesRedeemed_) external override onlyMember returns (bool) {
        uint256 totalAssetsInVault = Assets.balanceOf(address(this));
        uint256 amountToWithdraw = totalAssetsInVault * sharesRedeemed_ / Shares.totalSupply();

        // Ensure withdraw can succeed just in case rounding error somehow causes vault to not have enough assets
        if (amountToWithdraw > totalAssetsInVault) { 
            amountToWithdraw = totalAssetsInVault; 
        }
        uint256 netTokensRedeemed = amountToWithdraw * (100 - _withdrawFeePctg);
        
        // This should be the same as: uint256 feeCollected = amountToWithdraw * _withdrawFeePctg
        // but we use this method to mitigate potential issues due to rounding errors
        uint256 feeCollected = amountToWithdraw - netTokensRedeemed;
        
        // Ensure that the redeemed shares are burned
        Shares.burnShares(msg.sender, sharesRedeemed_);

        // Claim all rewards before completing withdraw prior to making transfers
        Rewarder.claimRewardsFor(msg.sender);
        Assets.transfer(msg.sender, netTokensRedeemed);
        Assets.transfer(owner(), feeCollected);

        emit Withdrawn(msg.sender, netTokensRedeemed);

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
        _withdrawFeePctg = percentage_;   
        
        emit FeeChanged(percentage_);
        
        return true;
    }
}