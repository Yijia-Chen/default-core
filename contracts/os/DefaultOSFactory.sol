pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

/// @title DAO Tracker
/// @notice Keep track of global state of full list of DAOs and the addresses these DAOs map to
contract DefaultOSFactory is Ownable { 
    
  mapping(string => address) public osMap;
  address[] private osList;

  event OSCreated(address os, string id);


  /// @notice Get the address associated with a DAO's string ID
  /// @param daoId ID of DAO
  /// @return address Address associated with the the DAO
  function getOS(string memory daoId) public view returns (address) {
    return osMap[daoId];
  }

  /// @notice Add a new DAO to full list of DAOs using DefaultOS. 
  /// @param daoId ID of DAO
  function setOS(string memory daoId, address os) public {
    require(osMap[daoId] == address(0), "DefaultOSFactory | setOS(): Alias already taken");
    osMap[daoId] = os;
    osList.push(osMap[daoId]);

    emit OSCreated(os, daoId);
  }
}