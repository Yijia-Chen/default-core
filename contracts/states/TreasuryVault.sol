// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TreasuryVault is ERC20, Ownable {

    // primary state: _balances (inherited from the ERC20 contract)
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
    } 

    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    function mint(uint256 _amount) external onlyOwner returns (bool) {
        // only mint to the vault
        _mint(owner(), _amount);
        return true;
    }
}