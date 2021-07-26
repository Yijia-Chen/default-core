// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/StateContract.sol";
import "./interfaces/IEpochV1.sol";

contract Epoch is IEpoch, StateContract {
    
    uint16 public override currentEpoch = 0; // assuming weekly epochs, 16 bytes ~ 1,260 years (2**16/52)

    function incrementEpoch() external override onlyApprovedApps {
        currentEpoch++;
    }

    function resetEpoch() external override onlyApprovedApps {
        currentEpoch = 0;
    }

}