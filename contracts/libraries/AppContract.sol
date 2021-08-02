// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Permissioned.sol";
import "../state/Memberships.sol";

/**
 * Application Contracts are contracts that restrict certain functions to be accesible only by DAO members (on our membership roster).
 * Things like deposit(), vote(), etc. 

 * App Contracts extend State Contracts so that App contracts can call each other as whitelisted contracts.

 * In the future, we can extend this library to include functions like onlyThreshold(threshold_)
 * which could limit the execution of certain functions to the amount of tokens staked/owned by a 
 * certain member.
 */

abstract contract AppContract is Permissioned {
    event ReceivedApprovalFor(address indexed contract_);
    event ApprovalRevokedFor(address indexed contract_);
    
    Memberships private _Memberships;
    address[] private _approvedFor;

    constructor(Memberships memberships_) {
        _Memberships = memberships_;
    }

    modifier onlyMember() {
        require(_Memberships.isMember(msg.sender), "only DAO members can call this contract");
        _;    
    }

    // return a list of contracts that the AppContract can call 
    // (both state contracts and other integrated app contracts)
    function approvedFor() external view returns (address[] memory) {
        return _approvedFor;
    }

    function approvalReceived(address contract_) external {
        _approvedFor.push(contract_);

        emit ReceivedApprovalFor(contract_);
    }

    function approvalRevoked(address contract_) external {
        for (uint i = 0; i < _approvedFor.length; i++) {
            if (_approvedFor[i] == contract_) {

                // write over the current array slot with the last item in the array, then delete the last item.
                _approvedFor[i] == _approvedFor[_approvedFor.length - 1];
                _approvedFor.pop();
            }
        }

        emit ApprovalRevokedFor(contract_);
    }
 }