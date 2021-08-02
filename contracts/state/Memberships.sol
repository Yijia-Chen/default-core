// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Permissioned.sol";
import "./interfaces/IMemberships.sol";

contract Memberships is IMemberships, Permissioned {

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
    
    function grantMembership(address newMember_) external override onlyApprovedApps {
        isMember[newMember_] = true;
    } 

    function revokeMembership(address newMember_) external override onlyApprovedApps {
        isMember[newMember_] = false;
    } 
    
    function bulkGrantMemberships(address[] calldata newMembers_) external override onlyApprovedApps {
        for (uint16 i = 0; i < newMembers_.length; i++) {
            isMember[newMembers_[i]] = true;
        }
    } 

    function bulkRevokeMemberships(address[] calldata newMembers_) external override onlyApprovedApps {
        for (uint16 i = 0; i < newMembers_.length; i++) {
            isMember[newMembers_[i]] = false;
        }    
    }
}