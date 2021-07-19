// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Epoch is Ownable {
    
    // primary state: _epoch
    // assuming 1 week = 1 epoch, 16 bytes = 1,260 years
    uint16 private _epoch = 0;

    constructor() {}

    function currentEpoch() external view returns (uint16) {
        return _epoch;
    }

    function incrementEpoch() external onlyOwner {
        _epoch++;
    }

    function resetEpoch() external onlyOwner {
        _epoch = 0;
    }

}