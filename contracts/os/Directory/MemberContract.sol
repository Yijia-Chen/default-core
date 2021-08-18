// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// import "../DefaultOS.sol";
import "./MemberStakes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MemberContract is Ownable { // add Staking

    mapping(address => uint256) public endorsementsGiven;
    mapping(address => uint256) public endorsementsReceived;

    // called by the OS

    function endorsedBy(address member_, uint256 amount_) external onlyOwner {
        endorsementsReceived[member_] += amount_;
    }

    function unendorsedBy(address member_, uint256 amount_) external onlyOwner {
        endorsementsReceived[member_] -= amount_;
    }
}
