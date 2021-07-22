// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/StateContract.sol";

contract Epoch is StateContract {
    
    uint16 private _epoch; // assuming weekly epochs, 16 bytes ~ 1,260 years (2**16/52)

    constructor() {
        _epoch = 0;
    }

    // reads

    function currentEpoch() external view returns (uint16) {
        return _epoch;
    }

    // writes

    function incrementEpoch() external onlyOwner {
        _epoch++;
    }

    function resetEpoch() external onlyOwner {
        _epoch = 0;
    }

}