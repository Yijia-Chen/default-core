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
// blocks of tokens that are locked for some amount of time. The list is sorted by earliest expiration date 
// (basically the EARLIEST staking block to be unlocked). This makes it easy to insert arbitrary length stakes,
// allowing us to experiment with things like multipliers for longer stakes in future design iterations.
// (shoutout to https://curve.fi/ for the mechanism inspiration).
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
// - fully
//

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "hardhat/console.sol";

contract Staking is DefaultOS {

    event TokensStaked(address member_, uint256 amount_, uint16 lockDuration_);
    event TokensWithdrawn(address member_, uint256 amount_);

    constructor(OS defaultOS_) DefaultOS(defaultOS_) {}

    // number of Stakes for the user
    uint16 public numStakes = 0;

    // the EARLIEST staking block to expire
    uint16 public EARLIEST = 0;

    // the LATEST staking block to expire
    uint16 public LATEST = 0;

    // total amount of staked tokens for the user
    uint256 public totalStakedTokens = 0;

    // getter for Stakes, using expiry epoch as unique identifier. 
    // NOTE: adding stakes to an existing stake for expiry epoch increments the existing amount.
    mapping(uint16 => Stake) public getStakeAt;

    Stake private _nullStake = Stake(0,0,0,0);

    // pack the struct variables--order declaration matters!
    struct Stake {

        // Expiry epoch for a block of staked tokens. Calculated based on stake duration + epoch staked.
        // Used as the comparison for the list sort, and unique id for linked list.
        uint16 expiryEpoch;

        // prev node in linked list of staking blocks
        uint16 prevStakeExpiry;

        // next node in linked list of staking blocks
        uint16 nextStakeExpiry;

        // DEF tokens staked
        uint256 amountStaked;
    }

    function _setEARLIEST(uint16 expiryEpoch_) internal {
        EARLIEST = expiryEpoch_;
        Stake storage stake = getStakeAt[expiryEpoch_];
        stake.prevStakeExpiry = 0;
    }

    function _wipeStake(uint16 expiryEpoch_) internal {
        getStakeAt[expiryEpoch_] = _nullStake;
    }

    function _getPrevExpiry(uint16 expiryEpoch_) internal view returns (uint16) {
        Stake memory stake = getStakeAt[expiryEpoch_];
        return stake.prevStakeExpiry;
    }

    function _stakeExistsForExpiry(uint16 expiryEpoch_) internal view returns (bool) {
        Stake memory stake = getStakeAt[expiryEpoch_];
        return stake.expiryEpoch != 0 && stake.amountStaked != 0;
    }

    // get EARLIEST item in the list. return true + object if something dequeued, otherwise return false and empty stake.
    function _dequeueStake() internal returns (bool) {
        if (numStakes == 0) {
            return false;
        } else {
            assert (EARLIEST != 0);
            Stake memory dequeuedStake = getStakeAt[EARLIEST];

            _setEARLIEST(dequeuedStake.nextStakeExpiry);
            _wipeStake(dequeuedStake.expiryEpoch);
            totalStakedTokens -= dequeuedStake.amountStaked;
            numStakes--;

            if (dequeuedStake.expiryEpoch == LATEST) { LATEST = 0; }

            return true;
        }
    }

    function _pushStake( uint16 expiryEpoch_, uint256 amount_) internal {
        Stake storage oldLATEST = getStakeAt[LATEST];

        // create and map new Stake
        getStakeAt[expiryEpoch_] = Stake(expiryEpoch_, oldLATEST.expiryEpoch, 0, amount_);
        totalStakedTokens += amount_;
        numStakes++;
        LATEST = expiryEpoch_;

        // if stake is the only item in the list, make it the new EARLIEST as well.
        if (numStakes == 1) { 
            _setEARLIEST(expiryEpoch_); 
        } else {
            oldLATEST.nextStakeExpiry = expiryEpoch_;
        }
    }

    function _insertStakeBefore(uint16 existingStakeExpiry_, uint16 newExpiryEpoch_, uint256 amount_) internal {
        require (numStakes != 0, "Staking.sol: cannot insertStakeBefore() in empty list of Stakes");
        
        Stake storage oldStake = getStakeAt[existingStakeExpiry_];

        // create and map new Stake
        getStakeAt[newExpiryEpoch_] = Stake(newExpiryEpoch_, oldStake.prevStakeExpiry, oldStake.expiryEpoch, amount_);
        totalStakedTokens += amount_;
        numStakes++;

        // If the old stake was the EARLIEST, make the inserted stake the new EARLIEST.
        if (oldStake.expiryEpoch == EARLIEST) {
            _setEARLIEST(newExpiryEpoch_); 

        // Otherwise, adjust the next pointer of the prev Stake to the newly inserted Stake
        } else {
            Stake storage prevStake = getStakeAt[oldStake.prevStakeExpiry];
            prevStake.nextStakeExpiry = newExpiryEpoch_;
        }

        // Set the next stake's prev pointer to the newly inserted Stake.
        oldStake.prevStakeExpiry = newExpiryEpoch_;
    }

    // amount of tokens + duration of stake
    function stakeTokens(address member_, uint256 amount_, uint16 lockDuration_) external {
        require (amount_ > 0, "must stake more than 0 tokens");
        
        uint16 expiryEpoch = _OS.currentEpoch() + lockDuration_;
        require (expiryEpoch > _OS.currentEpoch(), "stake expiry must be after current Epoch");

        if (_stakeExistsForExpiry(expiryEpoch)) {
            Stake storage existingStake = getStakeAt[expiryEpoch];
            existingStake.amountStaked += amount_;

        } else {
            
            if (numStakes == 0 || expiryEpoch > getStakeAt[LATEST].expiryEpoch) {
                _pushStake(expiryEpoch, amount_);

            } else {

                uint16 currentExpiry = LATEST;
                uint16 prevExpiry = _getPrevExpiry(currentExpiry);
                
                while (currentExpiry != 0 && prevExpiry > expiryEpoch) {
                    currentExpiry = prevExpiry;
                    prevExpiry = _getPrevExpiry(currentExpiry);
                }

                _insertStakeBefore(currentExpiry, expiryEpoch, amount_);
            }
        }

        // transfer Def Tokens to the contract
        _OS.transferFrom(member_, address(this), amount_);

        // record the event for dapps
        emit TokensStaked(member_, amount_, lockDuration_);
    }

    function withdrawAvailableTokens(address member_) external {
        // very important to keep this condition, protect against a 0 case from happening.
        require(numStakes != 0, "There is nothing to unstake!");

        uint256 totalTokensToWithdraw = 0;
        while (numStakes > 0 && _OS.currentEpoch() >= getStakeAt[EARLIEST].expiryEpoch) {
            totalTokensToWithdraw += getStakeAt[EARLIEST].amountStaked;
            _dequeueStake();
        }
        // transfer dao Tokens back to user
        _OS.transfer(member_, totalTokensToWithdraw);

        emit TokensWithdrawn(member_, totalTokensToWithdraw);
    }
}