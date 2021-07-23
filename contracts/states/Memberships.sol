// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/StateContract.sol";
import "./interfaces/MembershipsV1.sol";

contract Memberships is STATE_Memberships, StateContract {

    // primary state: checking if an address belongs to a member of the DAO.
    mapping(address => bool) public override isMember;

    // **BEWARE** This does NOT return only active members — it includes members that have been revoked!!
    // This is just a way to keep track of all historical memberships. You can create a list of active members
    // off chain by querying each item in the list for membership status.
    address[] private _members;
    
    constructor(address[] memory initialMembers_) {
        _members = initialMembers_;

        for (uint16 i = 0; i < _members.length; i++) {
            isMember[ _members[i] ] = true;
        }
    }

    function getMembers() external override view returns (address[] memory) {
        return _members;
    }

    function grantMembership(address member_) external override onlyApprovedApps {
        isMember[member_] = true;
    } 

    function revokeMembership(address member_) external override onlyApprovedApps {
        isMember[member_] = false;
    }
}