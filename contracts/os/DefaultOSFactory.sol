pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";
import "./DefaultOS.sol";

/// @title DAO Tracker
/// @notice Keep track of global state of full list of DAOs and the addresses these DAOs map to
contract DefaultOSFactory is Ownable { 
    
  mapping(bytes32 => address) public osMap;
  address[] private osList;

  event OSCreated(address os, bytes32 id);

  /// @notice Add a new DAO to full list of DAOs using DefaultOS. 
  /// @param name_ name of DAO
  function setOS(bytes32 name_) public {

    // ensure each name is unique and unreserved
    require(osMap[name_] == address(0), "DefaultOSFactory | setOS(): Alias already taken");
    
    // ensure OS names are alphanumeric characters or a hyphen (no spaces)
    // NOTE: unsure if this should be enforced at the contract level, discuss removal later.
    for (uint8 i = 0; i < 32; i++) {
      bytes1 char = name_[i];
      require(
        (char >= 0x30 && char <= 0x39) || //9-0
        (char >= 0x41 && char <= 0x5A) || //A-Z
        (char >= 0x61 && char <= 0x7A) || //a-z
        (char == 0x2D || char == 0x00), // hyphen or empty bits
        "OS Factory: Name must consist of alphanumeric characters or hyphen"
      );
    }

    // create the os and transfer ownership to creator, then add to list of OS's created.
    DefaultOS os = new DefaultOS(name_);
    os.transferOwnership(msg.sender);
    osMap[name_] = address(os);
    osList.push(address(os));

    emit OSCreated(address(os), name_);
  }
}