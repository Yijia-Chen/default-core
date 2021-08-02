// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * State Contracts are contracts that restrict certain functions to be accesible only by Application Contracts.
 * This makes it so that only pre-approved contracts managed by the DAO multisig can change/affect state of the DAO
 * e.g. Operator -> memberships + epoch, Treasury Vault -> shares, etc.

 * approveApplication() + revokeApplication() should be part of the dev ops pipeline/contract deployment cycle;
 * when a state contract and application contract are first released, the owner <dev addr> should assign
 * the proper approvals for application contracts to state contracts. If there is an application contract
 * upgrade (V2), the owner <dao multisig> should revoke the old application from modifying state (V1) and then
 * approving the new application to modify state IN THAT ORDER, so that there is no overlap with two contracts managing state.

 * isApproved is a mapping because in the future we may have third party applications/multiple internal applications
 * managing state. 
 */

abstract contract Permissioned is Ownable {
    event ApprovedApplication(address indexed contract_);
    event RevokedApplication(address indexed contract_);

    mapping(address => bool) public isApproved;
    
    // this keeps a list of both actively approved applications and revoked applications that were
    // historically approved. This is to keep a log of all the contracts throughout history that have
    // interacted with the state. To find a list of actively approved applications, verify each item in
    // the list to see if isApproved returns true.
    address[] private _approvedApplications;

    modifier onlyApprovedApps() {
        require(isApproved[msg.sender], "Permissioned onlyApprovedApps(): Application is not approved to call this contract");
        _;
    }

    function approveApplication(address appContract_) external virtual onlyOwner {
        isApproved[appContract_] = true;
        _approvedApplications.push(appContract_);

        emit ApprovedApplication(appContract_);
    }

    function revokeApplication(address appContract_) external virtual onlyOwner {
        isApproved[appContract_] = false;

        // ****************************** NOTE ***********************************
        // if you call this, make sure you also call "approvalRevoked(this address)"
        // on the corresponding application contract.
        // ***********************************************************************

        emit RevokedApplication(appContract_);
    }
}