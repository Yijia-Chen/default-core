// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface STATE_Memberships {
    // properties (reads)
    function isMember(address) external view returns (bool);
    function getMembers() external view returns (address[] memory);

    // state changes (writes)
    function grantMembership(address) external;
    function revokeMembership(address) external;
}