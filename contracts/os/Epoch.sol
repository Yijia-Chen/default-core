// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./DefaultOS.sol";

contract def_EpochInstaller is DefaultOSModuleInstaller("EPC") {

  string public moduleName = "Epoch";

  function install(DefaultOS os_) external override returns (address) {
      def_Epoch epoch = new def_Epoch(os_);
      epoch.transferOwnership(address(os_)); 
      return address(epoch);
  }
}

contract def_Epoch is DefaultOSModule {
  
  uint16 public currentEpoch = 1;
  uint256 public epochTime;

  constructor(DefaultOS os_) DefaultOSModule(os_) {
    epochTime = block.timestamp;
  }

  // emitted events
  event EpochIncremented(uint16 currentEpoch, uint256 epochTime);

  function incrementEpoch() external {        
    require(block.timestamp >= epochTime + (7 days), "Epoch.sol: cannot incrementEpoch() before deadline");
    epochTime = block.timestamp;
    currentEpoch++;
    emit EpochIncremented(currentEpoch, epochTime);
  }    
}