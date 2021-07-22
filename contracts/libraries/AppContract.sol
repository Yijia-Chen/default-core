// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../state/interfaces/IMemberships.sol";

/**
 * @dev Contract module which provides app contracts with a whitelist of DAO members
 * that are allowed to interact with your application contracts. 

 * This module is used through inheritance. It will make available the modifier
 * `onlyMember`, which can be applied to our functions to restrict their use to
 * approved DAO members only.

 * In the future, we can extend this library to include functions like onlyThreshold(threshold_)
 * which could limit the execution of certain functions to the amount of tokens staked/owned by a 
 * certain member.
 */

abstract contract AppContract is Ownable {
    
    IMemberships private _memberships;

    constructor(IMemberships memberships_) {
        _memberships = memberships_;
    }

    modifier onlyMember() {
        require(_memberships.isMember(msg.sender), "only DAO members can call this contract");
        _;
    }
}