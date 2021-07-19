// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Membership is Ownable {

    // primary state: memberships
    mapping(address => bool) private _memberships;

    constructor() {}


    function isMember(address member_) external view returns (bool) {
        return _memberships[member_];
    }

    function grantMembership(address member_) external onlyOwner {
        _memberships[member_] = true;
    } 

    function revokeMembership(address member_) external onlyOwner {
        _memberships[member_] = false;
    }
}