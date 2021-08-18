// Quick Notes
//
// Stakes are not ERC20 tokens—they are simply locked in the contract. No ERC20/composability
// Around the staked tokens so as to not reduce the opportunity cost of the liquidity preference
// e.g. staking DEF is less of a commitment if someone can swap their sDEF for DEF/USDC immediately.
// And less confusing for the user when participating in governance/selling their tokens (see vBNT/BNT).
//
// Implementation
//
// The way we implement staking is with a sorted doubly linked list of "Stakes", or individual staking
// blocks of tokens that are locked for some amount of time. The list is sorted by FIRST expiration date 
// (basically the FIRST staking block to be unlocked). This makes it easy to insert arbitrary length stakes,
// allowing us to experiment with things like multipliers for longer stakes in future design iterations.
// (shoutout to https://curve.fi/ for the mechanism inspiration).
//
// ADDED NOTES (8/17/21): Originally we used the expiry epoch as the primary id to sort each stake, but this was changed
// due to the fact that different lock durations generate different multipliers for endorsements, so each
// individual stake needs to be recorded (even if two stakes expire on the same epoch). This creates some constraints
// because the length of total stakes increases.
// 
//
// Concerns/Improvements
//
// This contract has some issues, namely around the length of the list + traversals in staking and unstaking logic.
// There is a storage write for every stake dequeued, which can get expensive in the unstaking process.
// These inefficiencies probably create an upper bound around the max number of Stakes stored due to gas limits, so
// a top dev priority should be 1) testing the bounds of the contract for staking and 2) creating safety barriers around them.
// In the beginning I think things are okay because the only real failure points are staking with low duration after a lot of high
// duration staking (e.g. inserting a 1 year stake after 100 2 year stakes) and unstaking a large amount of tokens at once after a lot
// of stakes have expired.
//
// ADDED NOTES (8/17/21): Another potential (but slight) issue with this implementation arises when it comes to unstaking.
// In the current implementation, unstaking happens by dequeuing the first stake in the list (since it has the earliest expiry)
// However, because different stakes have different endorsement multipliers, a user may in theory want to withdraw/unstake
// a later stake in the linked list while preserving the first one (especially if it has a high multiplier). However,
// I think this is a very nuanced edge case that I cannot forsee causing major issues in the immediate future, but we'll see.
//
// - fully
//

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "hardhat/console.sol";

contract MemberStakes { // IS OWNABLE
    // number of Stakes for the user
    uint8 public numStakes = 0;

    // the FIRST stake to expire
    uint32 public FIRST = 0;

    // the LAST stake to expire
    uint32 public LAST = 0;

    // total amount of staked tokens for the user
    uint256 public totalStakedTokens = 0;

    // uint32 (expiryEpoch | lockDuration) => Stake object
    mapping(uint32 => Stake) public getStakeForId;

    // pack the struct variables--order declaration matters!
    struct Stake {

        // epoch when this batch of staked tokens expire. Calculated based on lock duration + epoch staked. 
        // used as the comparison for the list sort.
        uint16 expiryEpoch;

        // important to keep this due to endorsement logic around different lock durations 
        // (otherwise would be unnecessary, as you can use expiry epoch as the unique identifier)
        uint16 lockDuration;

        // id of prev stake to expire in linked list of staking blocks
        uint32 prevStakeId;

        // id of next stake to expire in linked list of staking blocks
        uint32 nextStakeId;

        // DEF tokens amount staked in this batch
        uint256 amountStaked;
    }

    // used to get the stake object from the mapping
    function _packStakeId(uint16 expiryEpoch_, uint16 lockDuration_) internal pure returns(uint32 stakeId) {
        return (uint32(expiryEpoch_) << 16) | uint32(lockDuration_);
    }

    function _unpackStakeId(uint32 stakeId_) internal pure returns(uint16 lockDuration, uint16 expiryEpoch) {
        expiryEpoch = uint16(stakeId_ >> 16);
        lockDuration = uint16(stakeId_);
        return (expiryEpoch, lockDuration);
    }

    // Push the stake to the end of the linked list
    function _pushStake(uint16 expiryEpoch_, uint16 lockDuration_, uint256 amount_) internal {

        // create and map new Stake
        uint32 newStakeId = _packStakeId(expiryEpoch_, lockDuration_);
        getStakeForId[newStakeId] = Stake(expiryEpoch_, lockDuration_, LAST, 0, amount_);

        // if stake is the only item in the list, make it the new FIRST as well.
        if (numStakes == 0) { 
            FIRST = newStakeId;

        // otherwise, find the last stake and set its next stake to the new stake.
        } else {
            Stake memory curLAST = getStakeForId[LAST];
            curLAST.nextStakeId = newStakeId;
            getStakeForId[LAST] = curLAST;
        }

        // set the current stake to be the new LAST item in the linked list & update the appropriate state variables
        LAST = newStakeId;
        totalStakedTokens += amount_;
        numStakes++;
    }

    function _insertStakeBefore(uint32 insertedBeforeStakeId_, uint16 expiryEpoch_, uint16 lockDuration_, uint256 amount_) internal {
        require (numStakes != 0, "Staking.sol: cannot insertStakeBefore() in empty list of Stakes");
        
        Stake memory afterNewStake = getStakeForId[insertedBeforeStakeId_];

        // create, configure, and map new Stake
        uint32 newStakeId = _packStakeId(expiryEpoch_, lockDuration_);
        getStakeForId[newStakeId] = Stake(expiryEpoch_, lockDuration_, afterNewStake.prevStakeId, insertedBeforeStakeId_, amount_);

        // If the old stake was the FIRST, make the inserted stake the new FIRST.
        if (insertedBeforeStakeId_ == FIRST) {
            FIRST = newStakeId;

        // Otherwise, adjust the nextStake pointer of the old previous Stake to the newly inserted StakeId
        } else {
            Stake memory beforeNewStake = getStakeForId[afterNewStake.prevStakeId];
            beforeNewStake.nextStakeId = newStakeId;
            getStakeForId[afterNewStake.prevStakeId] = beforeNewStake;
        }

        // Set the next stake's prev pointer to the newly inserted Stake.
        afterNewStake.prevStakeId = newStakeId;
        getStakeForId[insertedBeforeStakeId_] = afterNewStake;

        // update the appropriate state variables
        totalStakedTokens += amount_;
        numStakes++;
    }

    // When registering new stakes, do a sorted insert into the doubly linked list based on expiry epoch | lockDuration
    function registerNewStake(uint16 expiryEpoch_, uint16 lockDuration_, uint256 amount_) external {
        uint32 newStakeId = _packStakeId(expiryEpoch_, lockDuration_);
        Stake memory newStake = getStakeForId[newStakeId];
        Stake memory lastStake = getStakeForId[LAST];

        // If a stake exists for the expiryEpoch + lockDuration, then
        // user wants to re-up (so add amount to existing stake) 
        if (newStake.expiryEpoch != 0) {
            newStake.amountStaked += amount_;
            getStakeForId[newStakeId] = newStake;
            totalStakedTokens += amount_;
        
        // If no stakes exist, or if the current stake's expiry Epoch is greater than or equal to the last expiry,
        // then push the stake to the end of the list
        } else if (numStakes == 0 || expiryEpoch_ >= lastStake.expiryEpoch) { 
            _pushStake(expiryEpoch_, lockDuration_, amount_);

        // Otherwise, loop through the linked list starting from the end until the appropriate spot for the 
        // new stake is found, and insert the stake in the correct position.
        } else {
            Stake memory prevStake = getStakeForId[lastStake.prevStakeId];
            while (prevStake.expiryEpoch != 0 && prevStake.expiryEpoch > expiryEpoch_) {
                lastStake = prevStake;
                prevStake = getStakeForId[prevStake.prevStakeId];
            }

            uint32 existingStakeId = _packStakeId(lastStake.expiryEpoch, lastStake.lockDuration);
            _insertStakeBefore(existingStakeId, expiryEpoch_, lockDuration_, amount_);
        }

    }

    function dequeueStake() external returns (uint16 lockDuration_, uint256 amount_) {
        // If no stakes exist, return false and empty
        require (numStakes > 0, "cannot dequeue empty stakes list");

        Stake memory firstStake = getStakeForId[FIRST];
        
        // reset stake at FIRST stakeId
        getStakeForId[FIRST] = Stake(0, 0, 0, 0, 0);

        if (numStakes == 1) {
            FIRST = 0;
            LAST = 0;
        } else {
            // set the nextStake of the dequeued stake to be the first stake in the list        
            Stake memory nextStake = getStakeForId[firstStake.nextStakeId];
            nextStake.prevStakeId = 0;
            getStakeForId[firstStake.nextStakeId] = nextStake;
            FIRST = firstStake.nextStakeId;
        }


        // update the appropriate state variables
        totalStakedTokens -= firstStake.amountStaked;
        numStakes--;

        return (firstStake.lockDuration, firstStake.amountStaked);
    }
}