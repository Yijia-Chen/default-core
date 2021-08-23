// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract DefaultOSModuleInstaller is Ownable {
    bytes3 public moduleKeycode;

    constructor(bytes3 moduleKeycode_) {
        for (uint i = 0; i < 3; i++) {
            bytes1 char = moduleKeycode_[i];
            require (char >= 0x41 && char <= 0x5A, "DefaultOS Module: Invalid Keycode");  // A-Z only
        }
        moduleKeycode = moduleKeycode_;
    }

    function install(DefaultOS os_) external virtual returns (address moduleAddress) { // ensure only the OS owner can call install anything
        require(false, "function install() must be implemented in the Default OS Module Installer");
    }
}

contract DefaultOSModule is Ownable {
    DefaultOS public _OS;

    constructor(DefaultOS os_) {
        _OS = os_;
    }
}

contract DefaultOS is Ownable {

    string public organizationName;
    uint16 public currentEpoch = 0;
    mapping(bytes3 => address) public MODULES;

    constructor(string memory organizationName_) {
        organizationName = organizationName_;
    }

    function installModule(DefaultOSModuleInstaller installer_) external onlyOwner {
        MODULES[installer_.moduleKeycode()] = installer_.install(this);
    }

    function getModule(bytes3 moduleKeycode_) external view returns (address) {
        return MODULES[moduleKeycode_];
    }

    function incrementEpoch() external onlyOwner {
        currentEpoch++;
    }    
    
}