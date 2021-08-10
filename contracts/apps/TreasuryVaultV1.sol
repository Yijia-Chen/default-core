// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// A generic contract that manages ownership claims for assets on the DAO balance sheet
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TreasuryVaultV1 is ERC20 { // + Pausable, Ownable, AppRegistry

    uint8 public decimals;
    address public Treasury; // the treasury contract of the operating Default DAO
    IERC20 public Asset; // the token that the vault can custody

    constructor(IERC20 asset_, string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        Treasury = msg.sender;
        decimals = decimals_;
    } 

    // Deposit assets at the DAO. Get shares in the vaults.
    function deposit(address depositor_, uint256 depositAmount_) external override whenNotPaused onlyApprovedApps returns (uint256) {
        uint256 totalAssetsInVault = Asset.balanceOf(address(this));
        uint256 totalSharesOutstanding = totalSupply();
        uint256 sharesToMint;

        // If there are no shares in existence or no assets in the vault, then issue the same number of shares as assets deposited.
        if (totalSharesOutstanding == 0 || totalAssetsInVault == 0) {
            sharesToMint = depositAmount_;
        } 

        // Calculate and mint the amount of shares the token is worth. The ratio will change overtime, 
        // as token is borrowed/repaid by the DAO. Vault shares decay with the borrow -> deposit -> borrow cycle, so don't
        // expect short term parity between share <-> asset in the vault.
        else {

            // do not use pricePerShare(). This is because we want to perform divisions last
            // in order to to minimize the effects of rounding errors.
            sharesToMint = depositAmount_ * totalSharesOutstanding / totalAssetsInVault;
        }

        // Mint shares to depositor
        _mint(depositor_, sharesToMint);

        // Lock the tokens in the vault
        Asset.transferFrom(depositor_, address(this), depositAmount_);

        // Record the event for frontend indexing
        emit TreasuryVaultDeposit(Asset, depositor_, depositAmount_);

        // Return the amount of minted shares to the calling contract, in case they want to use it for additional logic.
        return sharesToMint;
    }

    // Open the vault. Return assets to the user and burn their shares of the vault.
    function withdraw(address depositor_, uint256 totalSharesRedeemed_) external override whenNotPaused onlyApprovedApps returns (bool) {

        // Integer rounding here should create very slight share surpluses over time (in solidity, int division always rounds down) 
        // e.g. 1 * 1 / 2 = 0
        uint256 amountToWithdraw = Asset.balanceOf(address(this)) * totalSharesRedeemed_ / totalSupply();

        // Ensure withdraw can succeed just in case rounding error somehow causes vault to not have enough assets
        if (amountToWithdraw > totalAssetsInVault) { 
            amountToWithdraw = totalAssetsInVault; 
        }

        // Burn the shares redeemed by the user
        _burnShares(depositor_, totalSharesRedeemed_);

        // Return the tokens from the vault to the user
        Asset.transfer(depositor_, amountToWithdraw);

        // Record the event for frontend indexing
        emit Withdrawn(depositor_, amountToWithdraw);

        return true;
    }
    
    // Let the DAO take assets from the vault.
    function borrow(uint256 amount_) external override onlyOwner returns (bool) {
        return Asset.transfer(msg.sender, amount_);
    }
    
    // Repays assets to the vault. Any assets acquired by the DAO goes to the vault.
    function repay(uint256 amount_) external override onlyOwner returns(bool) { 
        return Asset.transferFrom(msg.sender, address(this), amount_);
    }

    // restrict share transfers to the OS to prevent secondary markets for vault shares, e.g.
    // letting vault depositors exit without paying the withdraw fee, or borrowing against the shares in lending protocols
    function transfer(address recipient_, uint256 amount_) public override onlyApprovedApps returns (bool) {
        return super.transfer(recipient_, amount._);
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public override onlyApprovedApps returns (bool) {
        return super.transferFrom(sender_, recipient_, amount_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}