// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MembershipRegistry is Ownable {
    
    /*
     * *****************************************************************************************************
     * @dao Membership Requirements:
      
     * Rule: To get membership, you need 2 existing members to refer you
     * Existing members need to have X DNT staked to refer. --> Create "MemberOwnable" library for this
     * Make this adjustable as a governance parameter?
     * *****************************************************************************************************
     */ 
    
    // members of the DAO 
    mapping(address => bool) public memberships;

    // 2 referrals are needed for the DAO
    mapping(address => address[2]) referrals;

    // list of members
    address[] public members;

    // **********************************************************************
    // TODO: CREATE MODIFIER onlyMember(_threshold) FOR CERTAIN DAO FUNCTIONS
    // DESTROY THIS MESSAGE AFTER SUCCESSFUL TESTING
    // **********************************************************************

    function refer(address newMember_) external returns (bool) {
        require(referrals[newMember_][0] != msg.sender, "you have already referred this member");


        if (referrals[newMember_][0] == address(0)) {
            referrals[newMember_][0] == msg.sender;
        } else if (referrals[newMember_][1] == address(0)) {
            referrals[newMember_][1] == msg.sender;
            _register(newMember_);
        }
    }

    // add their address to the member mapping and list
    function _register(address newMember_) internal {
        memberships[newMember_] = true;
        members.push(newMember_);
    }

}