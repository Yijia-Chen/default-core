pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";
import "./DefaultOS.sol";

/// @title DAO Tracker
/// @notice Keep track of global state of full list of DAOs and the addresses these DAOs map to
contract DefaultOSFactory is Ownable { 
    
  mapping(bytes32 => address) public osMap;
  mapping(bytes32 => address) public osAliasMap;
  address[] private osList;

  event OSCreated(address os, bytes32 alias_, bytes32 id);

  /// @notice Add a new DAO to full list of DAOs using DefaultOS. 
  /// @param name_ name of DAO
  function setOS(bytes32 name_, bytes32 alias_) public {
    require(osAliasMap[alias_] == address(0), "DefaultOSFactory | setOS(): Alias already taken");
    DefaultOS os = new DefaultOS(name_);
    os.transferOwnership(msg.sender);
    osMap[name_] = address(os);
    osAliasMap[alias_] = address(os);
    osList.push(address(os));

    emit OSCreated(address(os), alias_, name_);
  }
}