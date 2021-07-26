// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEpoch {
    // properties (reads)
    function currentEpoch() external view returns (uint16);
    
    // state changes (writes)
    function incrementEpoch() external;
    function resetEpoch() external;
}