pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract DaoTracker is Ownable {  
  event DaoCreated(address indexed os, string indexed id, string name);

  mapping(string => address) public daoMap;
  mapping(string => bool) public daoActive;
  address[] private daoList;

  function getDao(string memory daoId) public view returns (address) {
    return daoMap[daoId];
  }

  function setDao(string memory daoId, address os) public {
    require(!daoActive[daoId]);
    daoMap[daoId] = os;
    daoActive[daoId] = true;
    daoList.push(daoMap[daoId]);
  }
}