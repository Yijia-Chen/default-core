//SPDX-identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/IVault.sol";
// TODO: Implement reentrancy guard?

contract TreasuryVault is IVault, ERC20, Ownable {
    // implement safe 
    using SafeERC20 for IERC20Metadata;

    // token contract + data (use the same decimals)
    IERC20Metadata public token;
    
    // fee to withdraw assets from this vault (sent to DAO multisig)
    uint8 public withdrawFee;
    
    // OZ's current ERC20 doesn't allow setting decimals except through function override....
    uint8 private _decimals;

    // Define the token contract
    constructor(string memory name_, string memory symbol_, IERC20Metadata token_, uint8 withdrawFee_) ERC20(name_, symbol_) {
        token = token_;
        withdrawFee = withdrawFee_;
        _decimals = token.decimals();
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // Open the vault. Deposit some token. Earn some shares.
    // Locks token and mints vault shares
    function deposit(uint256 amount_) external override returns (bool){
        // Gets the amount of tokens locked in the contract
        uint256 totalTokens = token.balanceOf(address(this));
        // Gets the amount of vault shares in existence
        uint256 totalShares = totalSupply();
        // If no shares exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalTokens == 0) {
            _mint(msg.sender, amount_);
        } 
        // Calculate and mint the amount of shares the token is worth. The ratio will change overtime, 
        // as token is borrowed/repaid by the DAO
        else {
            uint256 sharesToMint = amount_ * totalShares / totalTokens;
            _mint(msg.sender, sharesToMint);
        }
        // Lock the token in the contract
        token.transferFrom(msg.sender, address(this), amount_);

        emit Deposited(msg.sender, amount_);

        return true;
    }

    // Close the vault. Claim back your token.
    // Unlocks the tokens and burns vault shares.
    function withdraw(uint256 shares_) public override returns (bool) {
        // Gets the amount of vault shares in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of tokens the vault shares are worth
        uint256 totalTokens = shares_ * token.balanceOf(address(this)) / totalShares;
        
        // There may be a potential rounding error issue here, please ensure there's forced synchronization.
        uint256 tokensToDisperse = totalTokens * (100 - withdrawFee);
        uint256 feeCollected = totalTokens * withdrawFee;
        
        // do the transaction
        _burn(msg.sender, shares_);
        token.transfer(msg.sender, tokensToDisperse);
        token.transfer(owner(), feeCollected);

        emit Withdrawn(msg.sender, tokensToDisperse);

        return true;
    }
    
    // Let the DAO take money from the vault.
    function borrow(uint256 amount_) external override onlyOwner returns (bool) {
        return token.transfer(msg.sender, amount_);
    }
    

    function repay(uint256 amount_) external override onlyOwner returns(bool) { 
        return token.transferFrom(msg.sender, address(this), amount_);
    }
    
    function setFee(uint8 _percentage) external override onlyOwner returns(bool) {
        withdrawFee = _percentage;   
        
        emit FeeChanged(_percentage);
        return true;
    }
}