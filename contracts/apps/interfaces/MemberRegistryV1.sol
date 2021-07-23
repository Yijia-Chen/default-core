// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface APP_MemberRegistry {
    // reads
    function isMember(address member_) external view returns (bool);
    function getMembers() external view returns (address[] memory);

    // writes
    function grantMembership(address member_) external returns (bool);
    function revokeMembership(address member_) external returns (bool);

    // events
    Event MembershipGranted(address indexed member_);
    Event MembershipRevoked(address indexed member_);

}