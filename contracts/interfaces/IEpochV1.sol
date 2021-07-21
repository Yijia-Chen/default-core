// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEpochV1 {
    // reads
    function currentEpoch() external view returns (uint16);

    // writes
    function incrementEpoch() external;
    function resetEpoch() external;
}