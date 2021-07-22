// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/StateContract.sol";

// This is a generic contract that manages ownership claims for assets on the DAO balance sheet
// (inside the Treasury Vaults). To start, there will only be two vaults: USDC and DNT. 

contract VaultShares is ERC20, StateContract { 

    // the primary state (inherited from the ERC20 contract) looks like this: mapping(address => uint256) _balances;
    uint8 private _decimals; // OZ's current ERC20 doesn't allow setting decimals except through function override....

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    } 

    // reads

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    // writes

    // only mint to the dao
    function issueShares(address depositor_, uint256 amount_) external onlyApplications returns (bool) {
        _mint(depositor_, amount_);
        return true;
    }

    // only allow the vault to transfer shares.. this accomplishes a few things:
    // 1. prevent the creation of a secondary market for vault shares that gives
    //    vault depositors the ability to exit vaults without paying the withdraw fee.
    // 2. requires DAO approval for third party protocol integrations (lending, trading, etc.)
    //    that all go directly from the vault.
    // 3. enable the Rewarder.sol contract to trust that share amounts won't change across registrations
    
    function transfer(address recipient_, uint256 amount_) public override onlyApplications returns (bool) {
        return super.transfer(recipient_, amount_);
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public override onlyApplications returns (bool) {
        return super.transferFrom(sender_, recipient_, amount_);
    }
}