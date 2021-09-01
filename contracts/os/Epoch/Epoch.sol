// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "../Token/Token.sol";

contract def_EpochInstaller is DefaultOSModuleInstaller("EPC") {

  string public moduleName = "Epoch";

  function install(DefaultOS os_) external override returns (address) {
      def_Epoch epoch = new def_Epoch(os_);
      epoch.transferOwnership(address(os_)); 
      return address(epoch);
  }
}

contract def_Epoch is DefaultOSModule {
  
  // module configuration
  def_Token private _Token;

  constructor(DefaultOS os_) DefaultOSModule(os_) {
    _Token = def_Token(_OS.getModule("TKN"));
  }

  // emitted events
  event EpochIncremented(uint16 currentEpoch, uint256 epochTime);

  uint16 public current = 1;
  uint256 public epochTime = block.timestamp;
  uint256 public TOKEN_BONUS = 5000;

  function setTokenBonus(uint256 newTokenBonus_) external onlyOS {
    TOKEN_BONUS = newTokenBonus_;
  }


  function incrementEpoch() external {        
    require(block.timestamp >= epochTime + (7 days), "def_Epoch | incrementEpoch(): cannot increment epoch before deadline");
    epochTime = block.timestamp;
    current++;

    _Token.mint(msg.sender, TOKEN_BONUS);
    emit EpochIncremented(current, epochTime);
  }    
}