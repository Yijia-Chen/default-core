// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

import "./DefaultOSFactory.sol";

abstract contract DefaultOSModuleInstaller is Ownable {
    bytes3 public moduleKeycode;

    constructor(bytes3 moduleKeycode_) {
        for (uint256 i = 0; i < 3; i++) {
            bytes1 char = moduleKeycode_[i];
            require(
                char >= 0x41 && char <= 0x5A,
                "DefaultOS Module: Invalid Keycode"
            ); // A-Z only
        }
        moduleKeycode = moduleKeycode_;
    }

    function install(DefaultOS os_)
        external
        virtual
        returns (address moduleAddress)
    {
        // ensure only the OS owner can call install anything
        // require(false, "function install() must be implemented in the Default OS Module Installer");
    }
}

contract DefaultOSModule is Ownable {
    DefaultOS public _OS;

    constructor(DefaultOS os_) {
        _OS = os_;
    }

    modifier onlyOS() {      
      require(msg.sender == _OS.owner(), "only the os owner can make this call");
      _;
    }
}

contract DefaultOS is Ownable {
    string public organizationName;
    mapping(bytes3 => address) public MODULES;

    constructor(
        string memory organizationName_,
        string memory organizationId_,
        DefaultOSFactory factory_
    ) {
        organizationName = organizationName_;
        factory_.setDao(organizationId_, address(this));
    }

    event ModuleInstalled(bytes3 moduleKeycode, address OSAddress, address moduleAddress);

    function installModule(DefaultOSModuleInstaller installer_)
        external
        onlyOwner
    {
        bytes3 moduleKeyCode = installer_.moduleKeycode();        
        MODULES[moduleKeyCode] = installer_.install(this);

        emit ModuleInstalled(moduleKeyCode, address(this), MODULES[moduleKeyCode]);
    }

    function getModule(bytes3 moduleKeycode_) external view returns (address) {
        return MODULES[moduleKeycode_];
    }

    function transfer(
        IERC20 token_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        token_.transfer(recipient_, amount_);
    }
}
