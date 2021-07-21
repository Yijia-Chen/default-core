// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
// + pausable

contract Membership is Ownable { // + pausable

    mapping(address => bool) private _memberships;
    address[] private _members; // THIS DOES NOT CLEANLY RETURN ALL ACTIVE MEMBERS—MEMBERS THAT ARE DEACTIVATED/REVOKED, think of a better way to manage a list of members
    
    constructor(address[] memory initialMembers_) {
        _members = initialMembers_;
        for (uint16 i = 0; i < _members.length; i++) {
            _memberships[ _members[i] ] = true; // start at 1 because 0 is the default value for missing key
        }
    }
    
    function isMember(address member_) external view returns (bool) {
        return _memberships[member_];
    }

    function getMembers() external view returns (address[] memory) {
        return _members;
    }

    function grantMembership(address member_) external onlyOwner {
        _memberships[member_] = true;
    } 

    function revokeMembership(address member_) external onlyOwner {
        _memberships[member_] = false;
    }
}