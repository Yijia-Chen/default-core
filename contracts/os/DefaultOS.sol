// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

// The DefaultOS is a single contract that gives various modules access to each others' states.
// Pair of Supervisor/Factory contract is called a MODULE.
// -> TREASURY MODULE: Treasury (Supervisor), Vault (Factory)
// -> DIRECTORY MODULE: Directory (Supervisor), Member (Factory)
// -> (Future) GOVERNANCE MODULE: Governance (Supervisor), Proposal (Factory)

// We can use a monolithic OS contract architecture to start, but eventually the main OS
// should be some kind of proxy. This design severely limits the flexibility/extensibility modules per OS
// due to eth's gas limit. The proxy OS contract could act as a router to multiple individual state contracts, 
// and making it easy to upgrade/change out existing modules.

// The operator contract is the interface/authentication contract that allows the operator/executor 
// (EOA, multisig, or on-chain governance) to call other modules, link other modules to each
// other, and grant modules access to each others' state. This way, we can have an ecosystem
// of contracts that can expect and modify state at the target for full permissionless
// interactions in the blockchain ecosystem.

// MODULES: Token, Treasury, Directory


    // KeyCodeMapping: {
    //     TKN = IDefaultERC20
    
    //     MBR = IDefaultMemberships
    //     CBR = IDefaultContributorRewards

    //     TSY = IDefaultTreasury
    //     BSM = IDefaultBalanceSheetMining
    // }

contract DefaultOSModuleInstaller is Ownable {
    bytes3 public moduleKeycode;

    constructor(bytes3 moduleKeycode_) {
        for (uint i = 0; i < 3; i++) {
            bytes1 char = moduleKeycode_[i];
            require (char >= 0x41 && char <= 0x5A, "DefaultOS Module: Invalid Keycode");  // A-Z only
        }
        moduleKeycode = moduleKeycode_;
    }

    function install(DefaultOS os_) external virtual returns (address) {
        require(false, "function install() must be implemented in the Default OS Installer");
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