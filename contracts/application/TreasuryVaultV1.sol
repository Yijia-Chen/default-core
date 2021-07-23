// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/AppContract.sol";
import "../state/_VaultShares.sol";

contract TreasuryVaultV1 is AppContract {

    // MANAGED STATE
    IERC20Metadata private immutable _VaultAsset; // vault token
    IERC20Metadata private immutable _VaultShares; // claims on the tokens in the vault
    IDepositMining private _Rewarder; // register deposits in the rewarder contract

    // INSTANCE VARIABLES
    uint8 private _withdrawFee; // fee charged when withdrawing assets from this vault (% of shares sent to DAO treasury wallet)
    bool private _rewardableVault; // flag for whether the vault produces rewards: yes for USDC, no for DNT. This also allows us to open new incentivized vaults in the future.

    constructor(IERC20Metadata asset_, uint8 withdrawFee_, bool rewardableVault_, IMemberships memberships_) AppContract(memberships_) {
        _VaultAsset = asset_;
        _withdrawFee = withdrawFee_;
        _rewardableVault = rewardableVault_;
        
        string vaultName = string(abi.encodePacked("Default DAO Treasury Vault Share: ", _VaultAsset.symbol()));
        string vaultSymbol = string(abi.encodePacked(_VaultAsset.symbol(), "-VS"));
        string vaultDecimals = _VaultAsset.decimals();

        _VaultShares = new _VaultShares(vaultName, vaultSymbol, vaultDecimals);
        // make the owner of the _VaultShares contract the same owner as this contract
        _VaultShares.transferOwnership(owner());
        // register this contract as an approved application of the _VaultShares contract
        _VaultShares.approveApplication(address(this));
    }

    // Open the vault. Deposit some token. Get some shares. Members only.
    function deposit(uint256 amount_) external override onlyMember() returns (bool){
        // Gets the amount of tokens locked in the contract
        uint256 totalTokens = _VaultAsset.balanceOf(address(this));
        // Gets the amount of vault shares in existence
        uint256 totalShares = totalSupply();
        // If no shares exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalTokens == 0) {
            _VaultShares.issue(msg.sender, amount_);
        } 
        // Calculate and mint the amount of shares the token is worth. The ratio will change overtime, 
        // as token is borrowed/repaid by the DAO. Vault shares decay w/ borrows.
        else {
            uint256 sharesToMint = amount_ * totalShares / totalTokens;
            _VaultShares.issue(msg.sender, sharesToMint);
        }
        // Lock the token in the contract
        _VaultAsset.transferFrom(msg.sender, address(this), amount_);
        // If depositing in this vault gives rewards, register the depositor with the rewarder contract
        if (rewardableVault) {
            rewarder.register()
        }

        emit Deposited(msg.sender, amount_);

        return true;
    }

    // **********************************************************************
    // TODO: CHECK VAULT FOR ROUNDING ERRORS USING THE LOWEST POSSIBLE UNIT
    // DESTROY THIS MESSAGE AFTER SUCCESSFUL TESTING
    // **********************************************************************


    // Close the vault. Claim back your _VaultAsset.
    // Unlocks the tokens and burns vault shares.
    function withdraw(uint256 shares_) private override returns (bool) {

        // Gets the amount of vault shares in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of tokens the vault shares are worth
        uint256 totalTokens = shares_ * _VaultAsset.balanceOf(address(this)) / totalShares;
        
        // There may be a potential rounding error issue here, please ensure there's forced synchronization.
        uint256 amountToWithdraw = totalTokens * (100 - withdrawFee);
        uint256 feeCollected = totalTokens * withdrawFee;
        
        // do the transaction
        _burn(msg.sender, shares_);
        _VaultAsset.transfer(msg.sender, amountToWithdraw);
        _VaultAsset.transfer(owner(), feeCollected);

        emit Withdrawn(msg.sender, amountToWithdraw);

        return true;
    }
    
    // Let the DAO take money from the vault.
    function borrow(uint256 amount_) external override onlyOwner returns (bool) {
        return _VaultAsset.transfer(msg.sender, amount_);
    }
    

    function repay(uint256 amount_) external override onlyOwner returns(bool) { 
        return _VaultAsset.transferFrom(msg.sender, address(this), amount_);
    }
    
    function setFee(uint8 percentage_) external override onlyOwner returns(bool) {
        _withdrawFee = percentage_;   
        
        emit FeeChanged(percentage_);
        return true;
    }

    function transferShares(address recipient_, uint256 amount_) external returns (bool) {
        return transfer(recipient_, amount_);
    }
}