// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// contract DirectoryOS {
//     event MemberCreated(address member_, address membershipContract_);

//     // member wallet address => membership contract; each member has their own contract as their protocol interface.
//     mapping(address => address) private _membershipContracts;

//     function addMember(address member_, bytes32 alias_) public returns (address) {
//         // create the membership contract for this user
//         address newMembership = address(new MembershipV1(member_, alias_));

//         // save the membership 
//         _membershipContracts[member_] = newMembership;

//         // record for frontend
//         emit MemberCreated(member_,membershipContract_);

//         // return contract address for plugins
//         return newMembership;
//     }

//     // Permanently and irrevocably destroy the membership contract. Use responsibly.
//     function removeMember(address member_) internal onlyOperator () {
//         // get the membership contract to destroy
//         Membership membership = _membershipContracts[member_];

//         // prevent the user from interacting with their membership
//         membership.pause();

//         // give ownership to the burn address
//         membership.renounceOwnership();

//         // reset membership => contract mapping
//         _membershipContracts[member_] = address(0);

//         // record event for frontend
//         emit MemberPermanentlyRemoved(membership, member_);
//     }

//     // do later
//     function upgradeMembership() internal {}

//     function disableMembership() internal {
//         Membership membership = _membershipContracts[member_];
//         membership.pause();
//     }

//     function reenableMembership() internal {
//         Membership membership = _membershipContracts[member_];
//         membership.unpause();
//     }

// }
