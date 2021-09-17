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
    require(osMap[name_] == address(0), "DefaultOSFactory | setOS(): Alias already taken");
    address os = address(new DefaultOS(name_));
    osMap[name_] = os;
    osList.push(os);

    emit OSCreated(os, name_);
  }
}