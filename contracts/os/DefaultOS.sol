// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./DefaultOSFactory.sol";

/// @title Default OS Module Installer
/// @notice Interface for a module installer - the factory contract that creates a module instance for a DAO. Each module will be associated to a unique three letter [A-Z] keycode
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

    /// @notice Install an instance of a module for a given DAO
    /// @return moduleAddress Address of module instance
    /// @dev install() is called by the DAO contract
    function install()
        external
        virtual
        returns (address moduleAddress)
    {
        // ensure only the OS owner can call install anything
        // require(false, "function install() must be implemented in the Default OS Module Installer");
    }
}

/// @title DefaultOS Module
/// @notice Instance of a Default OS Module for Default OS instance.
contract DefaultOSModule is Ownable {
    DefaultOS public _OS;

    constructor(DefaultOS os_) {
        _OS = os_;
    }

    modifier viaGovernance() {      
      require(msg.sender == _OS.owner(), "only the os owner can make this call");
      _;
    }
}

/// @title Default OS
/// @notice Instance of a Default OS
contract DefaultOS is Ownable {
    bytes32 public organizationName;
    mapping(bytes3 => address) public MODULES;
    mapping(address => bool) public isModule;    // NOT PROD IMPLEMENTATION——MUST FLIP FALSE UPON UNINSTALL (not implementated yet)

    /// @notice Set organization name and add DAO org ID to DAO tracker
    /// @param organizationName_ Name of org
    constructor(bytes32 organizationName_) {
        organizationName = organizationName_;
    }

    event ModuleInstalled(address os, address module, bytes3 moduleKeyCode);

    /// @notice Allow DAO to add module to itself
    /// @param installer_ Address of module's contract factory
    function installModule(DefaultOSModuleInstaller installer_)
        external
        onlyOwner
    {
        bytes3 moduleKeyCode = installer_.moduleKeycode();  
        address moduleAddr = installer_.install();      
        MODULES[moduleKeyCode] = moduleAddr;
        isModule[moduleAddr] = true;

        emit ModuleInstalled(address(this), MODULES[moduleKeyCode], moduleKeyCode);
    }

    /// @notice Get address of DAO's module instance
    /// @param moduleKeycode_ Three letter [A-Z] keycode  of module
    /// @return address Address of Module instance
    function getModule(bytes3 moduleKeycode_) external view returns (address) {
        return MODULES[moduleKeycode_];
    }

    /// @notice Transfer ERC20 tokens from DAO to recipient 
    /// @param token_ ERC20 token contract
    /// @param recipient_ Address of recipient
    /// @param amount_ Amount of tokens to transfer
    function transfer(
        IERC20 token_,
        address recipient_,
        uint256 amount_
    ) external onlyOwner {
        token_.transfer(recipient_, amount_);
    }
}
