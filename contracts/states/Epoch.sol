// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/StateContract.sol";
import "./state/EpochV1.sol";

contract Epoch is STATE_Epoch, StateContract {
    
    uint16 public override epoch = 0; // assuming weekly epochs, 16 bytes ~ 1,260 years (2**16/52)

    function incrementEpoch() external override onlyApprovedApps {
        epoch++;
    }

    function resetEpoch() external override onlyApprovedApps {
        epoch = 0;
    }

}