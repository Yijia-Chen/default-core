// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/AppContract.sol";
import "../state/VaultShares.sol";

contract TreasuryVaultV1 is AppContract {

    // MANAGED STATE

    IERC20Metadata public immutable vaultAsset; // vault token
    IERC20Metadata public immutable vaultShares; // claims on the tokens in the vault
    IRewarder public rewarder; // register deposits in the rewarder contract

    // CONFIGURABLE VARIABLES

    uint8 public withdrawFee; // fee charged when withdrawing assets from this vault (% of shares sent to DAO treasury wallet)
    bool public rewardableVault; // flag for whether the vault produces rewards: yes for USDC, no for DNT. This also allows us to open new incentivized vaults in the future.

    constructor(IERC20Metadata asset_, uint8 withdrawFee_, bool rewardableVault_, IMemberships memberships_) AppContract(memberships) {
        vaultAsset = asset_;
        withdrawFee = withdrawFee_;
        rewardableVault = rewardableVault_;
        
        string vaultName = string(abi.encodePacked("Default DAO Treasury Vault Share: ", vaultAsset.name()));
        string vaultSymbol = string(abi.encodePacked(vaultAsset.symbol(), "-VS"));
        string vaultDecimals = vaultAsset.decimals();

        vaultShares = new VaultShares(vaultName, vaultSymbol, vaultDecimals);

        // TODO
        // 1. assign application of VaultShares to current TreasuryVault
        // 2. Change owner of VaultShares to DAO Multisig
    }

    // Open the vault. Deposit some token. Get some shares. Members only.
    function deposit(uint256 amount_) external override onlyMember() returns (bool){
        // Gets the amount of tokens locked in the contract
        uint256 totalTokens = vaultAsset.balanceOf(address(this));
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
        vaultAsset.transferFrom(msg.sender, address(this), amount_);

        if (rewardableVault) {
            
        }

        emit Deposited(msg.sender, amount_);

        return true;
    }

    // **********************************************************************
    // TODO: CHECK VAULT FOR ROUNDING ERRORS USING THE LOWEST POSSIBLE UNIT
    // DESTROY THIS MESSAGE AFTER SUCCESSFUL TESTING
    // **********************************************************************


    // Close the vault. Claim back your vaultAsset.
    // Unlocks the tokens and burns vault shares.
    function withdraw(uint256 shares_) public override returns (bool) {
        // Gets the amount of vault shares in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of tokens the vault shares are worth
        uint256 totalTokens = shares_ * vaultAsset.balanceOf(address(this)) / totalShares;
        
        // There may be a potential rounding error issue here, please ensure there's forced synchronization.
        uint256 tokensToDisperse = totalTokens * (100 - withdrawFee);
        uint256 feeCollected = totalTokens * withdrawFee;
        
        // do the transaction
        _burn(msg.sender, shares_);
        vaultAsset.transfer(msg.sender, tokensToDisperse);
        vaultAsset.transfer(owner(), feeCollected);

        emit Withdrawn(msg.sender, tokensToDisperse);

        return true;
    }
    
    // Let the DAO take money from the vault.
    function borrow(uint256 amount_) external override onlyOwner returns (bool) {
        return vaultAsset.transfer(msg.sender, amount_);
    }
    

    function repay(uint256 amount_) external override onlyOwner returns(bool) { 
        return vaultAsset.transferFrom(msg.sender, address(this), amount_);
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