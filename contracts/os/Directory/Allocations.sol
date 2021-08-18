// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "../OS.sol";

// contract Allocations {

//     constructor(OS defaultOS_) {}

//     // number of Allocs for the user
//     uint16 public numAllocs = 0;

//     // the EARLIEST staking block to expire
//     address public FIRST = address(0);

//     // the LATEST staking block to expire
//     address public LAST = address(0);

//     // total amount of points allocated for the user
//     uint256 public totalAllocPoints = 0;

//     // getter for Allocs, using member address as unique identifier. 
//     mapping(address => Alloc) public getAlloc;

//     struct Alloc {
//         uint8 points;
//         address member;
//         address prev;
//         address next;
//     }

//     // last epoch locked
//     // epoch budget
//     // claim/mint rewards in separate contract? -> Directly in Memberships

//     function pushMemberAllocation(address member_, uint8 points_) external {
//         require (getAlloc[member_].points = 0, "only push if member doesn't exist already");
//         Alloc memory lastAlloc = getAlloc[LAST];
//         lastAlloc.next = member_;
//         getAlloc[LAST] = lastAlloc;

//         getAlloc[member_] = Alloc(points_, member_, lastAlloc.member_, 0);
//         totalAllocPoints += points_;
//         LAST = member_;
//         numAllocs++;
//     }

//     function setMemberAllocation(address member_, uint8 newPoints_) external {
//         require (newPoints_ > 0, "can't set allocation to 0...remove member allocation instead");
//         Alloc memory alloc = getAlloc[member_];
//         totalAllocPoints -= alloc.points;
//         alloc.points = newPoints_;
//         getAlloc[member_] = alloc;
//     }

//     function removeMemberAllocation(address member_) external {

//         // previous allocation
//         Alloc memory alloc = getAlloc[member_];
//         address prev = alloc.prev;
//         address next = alloc.next;

//         alloc = getAlloc[prev];
//         alloc.next = next;
//         getAlloc[prev] = alloc;

//         alloc = getAlloc[next];
//         alloc.prev = prev;
//         getAlloc[next] = alloc;

//         getAlloc[member_] = Alloc(0, address(0), address(0), address(0));
//         totalAllocPoints -= points_;

//         numAllocs--;
//     }


//     function lockEpochAllocations() external {

//         // member's share of the budget = total endorsements received out of the totalEndorsements in the protocol
//         uint256 availableBudget = _OS.contributorBudget * Member.totalEndorsementsReceived / _OS.totalEndorsements;

//         Alloc memory alloc = getAlloc[FIRST];
//         _OS.availableRewards[alloc.member_] += alloc.amount;

//         alloc = getAlloc[alloc.next];
//         while (alloc.next != address(0)) {
//             _OS.availableRewards[alloc.member_] += alloc.amount;
//         }
//     }
// }
