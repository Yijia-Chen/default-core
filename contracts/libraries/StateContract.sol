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

abstract contract StateContract is Ownable {
    event ApprovedApplication(address indexed contract_);
    event RevokedApplication(address indexed contract_);

    mapping(address => bool) public isApproved;
    
    // this keeps a list of both actively approved applications and revoked applications that were
    // historically approved. This is to keep a log of all the contracts throughout history that have
    // interacted with the state. To find a list of actively approved applications, verify each item in
    // the list to see if isApproved returns true.
    address[] private _approvedApplications;

    modifier onlyApprovedApps() {
        require(isApproved[msg.sender], "Application is not approved to call this contract");
        _;
    }

    function approveApplication(address appContract_) external virtual onlyOwner {
        // require the approved address to be a contract and not an EOA
        uint32 size;
        assembly { size := extcodesize(appContract_) }
        require(size > 0, "application must be a contract");

        // ****************************** NOTE ***********************************
        // Do not use the same logic for the inverse validation i.e. ensuring that an
        // address is NOT a contract "(require size = 0)" because contracts can trick
        // the validation by calling methods in the constructor (before the contract)
        // is loaded into the Blockchain. For more information, please review:
        // https://ethereum.stackexchange.com/questions/15641/how-does-a-contract-find-out-if-another-address-is-a-contract
        // ***********************************************************************

        isApproved[appContract_] = true;
        _approvedApplications.push(appContract_);

        // ****************************** NOTE ***********************************
        // if you call this, make sure you also call "approvalReceived(this address)" 
        // on the corresponding application contract.
        // ***********************************************************************

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