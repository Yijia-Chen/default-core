// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMembership.sol";


/*
    * *****************************************************************************************************
    * @dao Membership Requirements for future:
    
    * To get membership, you need 2 existing members to refer you
    * Existing members need to have X DNT staked to refer. --> Extend existing AppContract Library
    * Make this adjustable as a governance parameter?
    * *****************************************************************************************************
    */ 

contract Registry is AppContract {
    
    IMembership private _memberships;

    constructor(IMembership memberships_) AppContract(memberships_) {}

    // writes
    function grantMembership(address member_) external onlyOwner {
        _memberships.grantMembership(address member_);
    }

    function revokeMembership(address member_) external onlyOwner {
        _memberships.revokeMembership(address member_);
    }
}

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
