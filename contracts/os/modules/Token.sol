// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract DefaultERC20Installer is DefaultOSModuleInstaller("TKN") {
    string public moduleName = "DefaultOS ERC20 Token Module";

    function install(DefaultOS os_) external override returns (address) {
        DefaultERC20 token = new DefaultERC20(os_);

        // give ownership to the OS for transfer/upgrade stuff in the future
        token.transferOwnership(address(os_)); 

        return address(token);
    }
}

contract DefaultERC20 is DefaultOSModule, ERC20("Default Token", "DEF") {

    constructor(DefaultOS os_) DefaultOSModule(os_) {}

    function mint(address member_, uint256 amount_) external { // onlyOS("MINTER") -> an OS-whitelist of all the tokens that have the ability to call this function
        _mint(member_, amount_);
    }
}