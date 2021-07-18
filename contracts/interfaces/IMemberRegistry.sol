// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMemberRegistry {
    function getVotingPower(address member_) external view returns (uint256);
}