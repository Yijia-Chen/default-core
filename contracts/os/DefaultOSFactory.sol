pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract DefaultOSFactory is Ownable { 
    
  mapping(string => address) public daoMap;
  address[] private daoList;

  event DaoCreated(address os, string id);

  function getDao(string memory daoId) public view returns (address) {
    return daoMap[daoId];
  }

  function setDao(string memory daoId, address os) public {
    require(daoMap[daoId] == address(0), "DefaultOSFactory | setDao(): Alias already taken");
    daoMap[daoId] = os;
    daoList.push(daoMap[daoId]);

    emit DaoCreated(os, daoId);
  }
}