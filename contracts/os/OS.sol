// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// The DefaultOS is just a collection of States & Logic Contracts, bundled into a single contract.
// Pair of Supervisor/Factory contract is called a MODULE.
// -> TREASURY MODULE: Treasury (Supervisor), Vault (Factory)
// -> DIRECTORY MODULE: Directory (Supervisor), Member (Factory)
// -> (Future) GOVERNANCE MODULE: Governance (Supervisor), Proposal (Factory)

// We can use a monolithic OS contract architecture to start, but eventually the main OS
// should be some kind of proxy. This design severely limits the flexibility/extensibility modules per OS
// due to eth's gas limit. The proxy OS contract could act as a router to multiple individual state contracts, 
// and making it easy to upgrade/change out existing modules.


// MODULES: Token, Treasury, Directory
contract OS is ERC20("Default Token", "DEF"), Ownable { // is Treasury, Directory {

    bytes32 public Name;
    uint16 public currentEpoch = 0;

    function incrementEpoch() external onlyOwner {
        currentEpoch++;
    }

    function mint(uint256 amount_) external onlyOwner {
        _mint(msg.sender, amount_);
    }
    
    // function installModule(OSModule module_) external onlyOwner {

    // }
}

abstract contract ConfigureOS is Ownable {
    OS internal _OS;

    constructor(OS defaultOS_) {
        _OS = defaultOS_;
    }
}