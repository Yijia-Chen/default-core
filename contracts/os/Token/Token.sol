// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract def_TokenInstaller is DefaultOSModuleInstaller("TKN") {
    string public moduleName = "DefaultOS ERC20 Token";

    function install(DefaultOS os_) external override returns (address) {
        def_Token token = new def_Token(os_);
        token.transferOwnership(address(os_)); 
        return address(token);
    }
}

contract def_Token is DefaultOSModule, ERC20("Default Token", "DEF") {

    // 3 decimals
    uint8 private _decimals = 3;

    constructor(DefaultOS os_) DefaultOSModule(os_) {}

    function mint(address member_, uint256 amount_) external { // onlyOS("MINTER") -> an OS-whitelist of all the tokens that have the ability to call this function
        _mint(member_, amount_);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}