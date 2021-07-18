// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMemberRegistry.sol";

contract MemberOwnable is Ownable {
    
    IMemberRegistry private registry;

    constructor() {}

    modifier onlyMember(uint256 tokenThreshold_) {
        // if user has X staked tokens, they can execute the function
        require(registry.getVotingPower(msg.sender) > votingThreshold_, "not enough votes to execute function");
        _;
    }
}