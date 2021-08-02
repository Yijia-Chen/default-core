// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/AppContract.sol";
import "./interfaces/IMemberRegistry.sol";
import "../state/Memberships.sol";

/*
    * *****************************************************************************************************
    * @dao Membership Requirements=:
    
    * To get membership, you need 2 existing members to refer you
    * Existing members need to have X DNT staked to refer. --> Extend existing AppContract Library
    * Make this adjustable as a governance parameter?
    * *****************************************************************************************************
    */ 

contract MemberRegistryV1 is IMemberRegistry {
    
    // MANAGED STATE
    Memberships private _Memberships;

    constructor(Memberships memberships_) {
        _Memberships = memberships_;
    }

    function isMember(address address_) external view returns (bool) {
        return _Memberships.isMember(address_);
    }

    function grantMembership(address member_) external override returns (bool) {
        _Memberships.grantMembership(member_);

        emit MembershipGranted(member_);

        return true;
    }

    function revokeMembership(address member_) external override returns (bool) {
        _Memberships.revokeMembership(member_);

        emit MembershipRevoked(member_);

        return true;
    }
}

// go straight to referrals, no need to make an intermediary contract

    // // for V2
    // function refer(address newMember_) external returns (bool) {
    //     require(referrals[newMember_][0] != msg.sender, "referral already exists");
    //     require(memberships[newMember_] == false, "existing member cannot be referred");

    //     if (referrals[newMember_][0] == address(0)) {
    //         referrals[newMember_][0] == msg.sender;
    //     } else if (referrals[newMember_][1] == address(0)) {
    //         referrals[newMember_][1] == msg.sender;
    //         _register(newMember_);
    //     }
    // }