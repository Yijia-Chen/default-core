// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Contract module which provides state contracts with a whitelist of application
 * (business logic) contracts that are allowed to make modifications to the state. 

 * This module is used through inheritance. It will make available the modifier
 * `onlyApplications`, which can be applied to our functions to restrict their use to
 * approved applications only.

 * approveApplication + revokeApplication should be part of the dev ops pipeline post contract deployment;
 * when a state contract and application contract are first released, the owner <dev addr> should assign
 * the proper approvals for application contracts to state contracts. If there is an application contract
 * upgrade (V2), the owner <dao multisig> should revoke the old application from modifying state (V1) and then
 * approving the new application to modify state IN THAT ORDER.
 */

abstract contract StateContract is Ownable {
    mapping(address => bool) private isApprovedApplication;
    // this keeps a list of both actively approved applications and revoked applications that were
    // historically approved. This is to keep a log of all the contracts throughout history that have
    // interacted with the state. To find a list of actively approved applications, verify each item in
    // the list to see if isApproved returns true.
    address[] private _approvedApplications;

    modifier onlyApproved() {
        require(isApprovedApplication[msg.sender], "Application is not approved to call this contract");
        _;
    }

    function approveApplication(address contract_) external virtual onlyOwner {
        isApprovedApplication[contract_] = true;
        _approvedApplications.push(contract_);
        // EMIT EVENT
    }

    function revokeApplicatoin(address contract_) external virtual onlyOwner {
        isApprovedApplication[contract_] = false;
    }
}