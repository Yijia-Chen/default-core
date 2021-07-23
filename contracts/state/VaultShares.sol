// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/StateContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./protocols/VaultSharesV1.sol";

// This is a generic contract that manages ownership claims for assets on the DAO balance sheet
// (inside the Treasury Vaults). To start, there will only be two vaults: USDC and DNT. 

contract VaultShares is ERC20, VaultSharesV1, StateContract { 

    // the primary state (inherited from the ERC20 contract) looks like this: mapping(address => uint256) _balances;
    uint8 private _decimals; // OZ's current ERC20 doesn't allow setting decimals except through function override....

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    } 

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    // only mint to the dao
    function issueShares(address depositor_, uint256 amount_) external override onlyApprovedApps {
        _mint(depositor_, amount_);
    }

    // by only allowing the vault to transfer shares, we prevent the creation of a secondary market for 
    // vault shares that gives vault depositors the ability to exit vaults without paying the withdraw fee.
    function transfer(address recipient_, uint256 amount_) public override onlyApprovedApps returns (bool) {
        return super.transfer(recipient_, amount_);
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public override onlyApprovedApps returns (bool) {
        return super.transferFrom(sender_, recipient_, amount_);
    }
}