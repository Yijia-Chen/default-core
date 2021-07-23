// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface APP_MemberRegistry {
    // writes
    function grantMembership(address member_) external returns (bool);
    function revokeMembership(address member_) external returns (bool);

    // events
    event MembershipGranted(address indexed member_);
    event MembershipRevoked(address indexed member_);

}