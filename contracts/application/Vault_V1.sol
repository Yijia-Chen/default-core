// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IVaultV1.sol";

contract TreasuryVault is Ownable {

    // MANAGED STATE

    IERC20Metadata public immutable vaultAssets; // vault token
    IERC20Metadata public immutable vaultShares; // claims on the tokens in the vault

    // CONFIGURABLE VARIABLES

    uint8 public withdrawFee; // fee charged when withdrawing assets from this vault (% of shares sent to DAO treasury wallet)

    constructor(IERC20Metadata asset_, uint8 withdrawFee_) {
        vaultAsset = asset_;
        withdrawFee = withdrawFee_;
        
        vaultName = string(abi.encodePacked("Default DAO Treasury Vault Share: ", vaultAsset.name()));
        vaultSymbol = string(abi.encodePacked(vaultAsset.symbol(), "-VS"));
        vaultDecimals = vaultAsset.decimals();

        vaultShares = new VaultShares(vaultName, vaultSymbol, vaultDecimals);
    }

    // Open the vault. Deposit some vaultAssets. Earn some shares.
    // Locks token and mints vault shares
    function deposit(uint256 amount_) external override returns (bool){
        // Gets the amount of tokens locked in the contract
        uint256 totalTokens = vaultAssets.balanceOf(address(this));
        // Gets the amount of vault shares in existence
        uint256 totalShares = totalSupply();
        // If no shares exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalTokens == 0) {
            vaultShares.issue(msg.sender, amount_);
        } 

        // Calculate and mint the amount of shares the token is worth. The ratio will change overtime, 
        // as token is borrowed/repaid by the DAO. Vault shares decay w/ borrows.

        else {
            uint256 sharesToMint = amount_ * totalShares / totalTokens;
            vaultShares.issue(msg.sender, sharesToMint);
        }
        // Lock the token in the contract
        vaultAssets.transferFrom(msg.sender, address(this), amount_);

        emit Deposited(msg.sender, amount_);

        return true;
    }

    // **********************************************************************
    // TODO: CHECK VAULT FOR ROUNDING ERRORS USING THE LOWEST POSSIBLE UNIT
    // DESTROY THIS MESSAGE AFTER SUCCESSFUL TESTING
    // **********************************************************************


    // Close the vault. Claim back your vaultAssets.
    // Unlocks the tokens and burns vault shares.
    function withdraw(uint256 shares_) public override returns (bool) {
        // Gets the amount of vault shares in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of tokens the vault shares are worth
        uint256 totalTokens = shares_ * vaultAssets.balanceOf(address(this)) / totalShares;
        
        // There may be a potential rounding error issue here, please ensure there's forced synchronization.
        uint256 tokensToDisperse = totalTokens * (100 - withdrawFee);
        uint256 feeCollected = totalTokens * withdrawFee;
        
        // do the transaction
        _burn(msg.sender, shares_);
        vaultAssets.transfer(msg.sender, tokensToDisperse);
        vaultAssets.transfer(owner(), feeCollected);

        emit Withdrawn(msg.sender, tokensToDisperse);

        return true;
    }
    
    // Let the DAO take money from the vault.
    function borrow(uint256 amount_) external override onlyOwner returns (bool) {
        return vaultAssets.transfer(msg.sender, amount_);
    }
    

    function repay(uint256 amount_) external override onlyOwner returns(bool) { 
        return vaultAssets.transferFrom(msg.sender, address(this), amount_);
    }
    
    function setFee(uint8 percentage_) external override onlyOwner returns(bool) {
        withdrawFee = percentage_;   
        
        emit FeeChanged(percentage_);
        return true;
    }

    function transferShares(address recipient_, uint256 amount_) external returns (bool) {
        return transfer(recipient_, amount_);
    }
}