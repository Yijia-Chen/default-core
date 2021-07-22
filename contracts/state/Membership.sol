// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libraries/StateContract.sol";


contract Membership is StateContract {

    // primary state: checking if an address belongs to a member of the DAO.
    mapping(address => bool) private _memberships;

    // THIS DOES NOT CLEANLY RETURN ALL ACTIVE MEMBERS—MEMBERS THAT ARE DEACTIVATED/REVOKED.
    // This is just a way to keep track of all historical memberships. You can create a list of active members
    // off chain by querying each item in the list for membership status.
    address[] private _members;
    
    constructor(address[] memory initialMembers_) {
        _members = initialMembers_;
        for (uint16 i = 0; i < _members.length; i++) {
            _memberships[ _members[i] ] = true; // start at 1 because 0 is the default value for missing key
        }
    }

    // reads
    
    function isMember(address member_) external view returns (bool) {
        return _memberships[member_];
    }

    function getMembers() external view returns (address[] memory) {
        return _members;
    }

    // writes

    function grantMembership(address member_) external onlyOwner {
        _memberships[member_] = true;
    } 

    function revokeMembership(address member_) external onlyOwner {
        _memberships[member_] = false;
    }
}