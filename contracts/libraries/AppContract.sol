// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../state/protocols/MembershipsV1.sol";

/**
 * Application Contracts are contracts that restrict certain functions to be accesible only by DAO members (on our membership roster).
 * Things like deposit(), vote(), etc. 

 * In the future, we can extend this library to include functions like onlyThreshold(threshold_)
 * which could limit the execution of certain functions to the amount of tokens staked/owned by a 
 * certain member.
 */

abstract contract AppContract is Ownable {
    
    MembershipsV1 private _Memberships;

    constructor(MembershipsV1 memberships_) {
        _Memberships = memberships_;
    }

    modifier onlyMember() {
        require(_Memberships.isMember(msg.sender), "only DAO members can call this contract");
        _;
    }
}