pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract DefaultOSFactory is Ownable { 
    
  mapping(string => address) public osMap;
  address[] private osList;

  event OSCreated(address os, string id, string name);

  function getOS(string memory daoId_) public view returns (address) {
    return osMap[daoId_];
  }

  function createOS(address os_, string memory daoId_, string memory name_) public {
    require(osMap[daoId_] == address(0), "DefaultOSFactory | createOS(): Alias already taken");
    osMap[daoId_] = os_;
    osList.push(osMap[daoId_]);

    emit OSCreated(os_, daoId_, name_);
  }
}