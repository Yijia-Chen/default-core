// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/AppContract.sol";
import "./interfaces/TreasuryVaultV1.sol";
import "./DepositMining.sol";
import "../states/Memberships.sol";
import "../states/VaultShares.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract TreasuryVault is APP_TreasuryVault, AppContract {

    // MANAGED STATE
    IERC20Metadata private _VaultAsset; // vault token
    VaultShares private _VaultShares; // use VaultShares instead of STATE_VaultShares because we need to change ownership of the contract.

    // APP INTEGRATIONS
    DepositMining private _DepositMining; // register deposits in the rewarder contract

    // INTERNAL VARIABLES
    uint8 private _withdrawFee; // fee charged when withdrawing assets from this vault (% of shares sent to DAO treasury wallet)
    bool private _rewardableVault; // flag for whether the vault produces rewards: yes for USDC, no for DNT. This also allows us to open new incentivized vaults in the future.

    constructor(IERC20Metadata asset_, uint8 withdrawFee_, bool rewardableVault_, Memberships memberships_) AppContract(memberships_) {
        _VaultAsset = asset_;
        _withdrawFee = withdrawFee_;
        _rewardableVault = rewardableVault_;
        _openVault();
    }

    function _openVault() internal {

        // ensure the Vault Shares have a standard naming format
        string memory vaultName = string(abi.encodePacked("Default DAO Treasury Vault Share: ", _VaultAsset.symbol()));
        string memory vaultSymbol = string(abi.encodePacked(_VaultAsset.symbol(), "-VS"));
        uint8 vaultDecimals = _VaultAsset.decimals();

        // create the token contract for this vault
        _VaultShares = VaultShares(new VaultShares(vaultName, vaultSymbol, vaultDecimals));

        // make the owner of the _VaultShares contract the same owner as this contract (dev addr)
        // *** make sure you transfer the ownership of the share contract to the DAO multisig as well
        _VaultShares.transferOwnership(owner());

        // register this contract as an approved application of the _VaultShares contract
        _VaultShares.approveApplication(address(this));
    }

    // how many tokens you get back for each share you own in the vault
    function pricePerShare() public view override returns (uint256) {
        return _VaultAsset.balanceOf(address(this))/_VaultShares.totalSupply();
    }

    // Open the vault. Deposit some token. Get some shares. Members only.
    function deposit(uint256 depositAmount_) external override onlyMember returns (bool){
        uint256 totalAssets = _VaultAsset.balanceOf(address(this));
        uint256 totalShares = _VaultShares.totalSupply();

        // If there are no shares in existence or no assets in the vault, then issue the same number of shares as assets deposited.
        if (totalShares == 0 || totalAssets == 0) {
            _VaultShares.issueShares(msg.sender, depositAmount_);
        } 

        // Calculate and mint the amount of shares the token is worth. The ratio will change overtime, 
        // as token is borrowed/repaid by the DAO. Vault shares decay w/ borrows.
        else {

            // notice we do not use pricePerShare(). This is because we want to perform divisions last
            // in order to to minimize the effects of rounding errors.
            uint256 sharesToMint = depositAmount_ * totalShares / totalAssets;
            _VaultShares.issueShares(msg.sender, sharesToMint);
        }

        // Lock the token in the contract
        _VaultAsset.transferFrom(msg.sender, address(this), depositAmount_);

        // If this vault gives rewards for deposits, register the depositor with the rewards contract
        if (_rewardableVault) {
            _DepositMining.register(msg.sender);
        }

        emit Deposited(msg.sender, depositAmount_);

        return true;
    }

    // Open the vault. Give depositors tokens and burn the vault shares they used to redeem them.
    function withdraw(uint256 vaultSharesRedeemed_) external override onlyMember returns (bool) {
        uint256 totalAssetsInVault = _VaultAsset.balanceOf(address(this));
        uint256 amountToWithdraw = totalAssetsInVault * vaultSharesRedeemed_ / _VaultShares.totalSupply();

        // Ensure withdraw can succeed just in case rounding error somehow causes vault to not have enough assets
        if (amountToWithdraw > totalAssetsInVault) { 
            amountToWithdraw = totalAssetsInVault; 
        }
        uint256 netTokensRedeemed = amountToWithdraw * (100 - _withdrawFee);
        
        // This should be the same as: uint256 feeCollected = amountToWithdraw * _withdrawFee
        // but we use this method to mitigate potential issues due to rounding errors
        uint256 feeCollected = amountToWithdraw - netTokensRedeemed;
        
        // Ensure that the redeemed shares are burned
        _VaultShares.burnShares(vaultSharesRedeemed_);

        // Claim all rewards before completing withdraw prior to making transfers
        _DepositMining.claimRewardsFor(msg.sender);
        _VaultAsset.transfer(msg.sender, netTokensRedeemed);
        _VaultAsset.transfer(owner(), feeCollected);

        emit Withdrawn(msg.sender, netTokensRedeemed);

        return true;
    }
    
    // Let the DAO take assets from the vault.
    function borrow(uint256 amount_) external override onlyOwner returns (bool) {
        return _VaultAsset.transfer(msg.sender, amount_);
    }
    
    // Repays assets to the vault. Any assets acquired by the DAO goes to the vault.
    function repay(uint256 amount_) external override onlyOwner returns(bool) { 
        return _VaultAsset.transferFrom(msg.sender, address(this), amount_);
    }
    
    // Change the fee charged by the DAO upon withdraw from this vault.
    function setFee(uint8 percentage_) external override onlyOwner returns(bool) {
        _withdrawFee = percentage_;   
        
        emit FeeChanged(percentage_);
        
        return true;
    }
}