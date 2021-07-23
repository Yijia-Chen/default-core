// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface EpochV1 {
    // properties (reads)
    function epoch() external view returns (uint16);
    
    // state changes (writes)
    function incrementEpoch() external;
    function resetEpoch() external;
}