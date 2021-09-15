pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

/// @title DAO Tracker
/// @notice Keep track of global state of full list of DAOs and the addresses these DAOs map to
contract DefaultOSFactory is Ownable { 
    
  mapping(string => address) public osMap;
  address[] private osList;

  event OSCreated(address os, string id, string name);


  /// @notice Get the address associated with a DAO's string ID
  /// @param daoId ID of DAO
  /// @return address Address associated with the the DAO
  function getDao(string memory daoId) public view returns (address) {
    return daoMap[daoId];
  }

  /// @notice Add a new DAO to full list of DAOs using DefaultOS. 
  /// @param daoId ID of DAO
  function setDao(string memory daoId, address os) public {
    require(daoMap[daoId] == address(0), "DefaultOSFactory | setDao(): Alias already taken");
    daoMap[daoId] = os;
    daoList.push(daoMap[daoId]);

    emit OSCreated(os_, daoId_, name_);
  }
}