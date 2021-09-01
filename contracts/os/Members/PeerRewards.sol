// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "../Epoch/Epoch.sol";
import "../Members/Members.sol";
import "../Token/Token.sol";

import "hardhat/console.sol";

contract def_PeerRewardsInstaller is DefaultOSModuleInstaller("PAY") {
    string public moduleName = "Default Peer Rewards";

    function install(DefaultOS os_) external override returns (address) {
        def_PeerRewards peerRewards = new def_PeerRewards(os_);
        peerRewards.transferOwnership(address(os_)); 
        return address(peerRewards);
    }
}

contract def_PeerRewards is DefaultOSModule{

    // Module Configuration
    def_Token private _Token;
    def_Members private _Members;
    def_Epoch private _Epoch;

    constructor(DefaultOS os_) DefaultOSModule(os_) {
        _Token = def_Token(_OS.getModule("TKN"));
        _Members = def_Members(_OS.getModule("MBR"));
        _Epoch = def_Epoch(_OS.getModule("EPC"));
    }


    // Emitted events for this module
    event MemberRegistered(address member, uint16 epochRegisteredFor, uint256 ptsRegistered);
    event AllocationSet(address fromMember, address toMember, uint8 allocPts);
    event AllocationGiven(address fromMember, address toMember, uint256 allocGiven, uint16 currentEpoch);
    event RewardsClaimed(address member, uint256 totalRewardsClaimed, uint16 epochClaimed);


    // persistent allocation data for a particular member
    struct AllocData {
        address to; // the address of the member currently being allocated to
        address prev; // the address of the prev member in the list
        address next; // the address of the next member in the list
        uint8 pts; // points allocated to the current member
    }

    // a linked list of individual Allocations for a given member
    struct AllocationsList {
        uint8 numAllocs; // number of allocations for the member
        uint8 highestPts; // the highest allocation pts in their list
        uint8 lowestPts; // the lowest allocation pts in their list
        uint16 totalPts; // total points allocated to other members in the org
        address TAIL; // last member of their list
        mapping(address => AllocData) allocData; // get the details of an allocation to another member
    }


    // days that the contributor has consecutively participated in the rewards program
    mapping(address => uint16) public participationStreak;

    // the amount of endorsements each member registered for a given epoch
    mapping(uint16 => mapping(address => uint256)) public pointsRegisteredForEpoch;

    // the total amount of endorsements registered for a given epoch
    mapping(uint16 => uint256) public totalPointsRegisteredForEpoch;

    // track allocations participation for each user (by epoch) 
    mapping(uint16 => mapping(address => bool)) public participationHistory; //  mapping( epoch => mapping( allocator => participated ))

    // the allocations list for a given member
    mapping(address => AllocationsList) public getAllocationsListFor;

    // boolean flag for if a user is eligible for rewards for the epoch (rewards is opt in as well)
    mapping(uint16 => mapping(address => bool)) public eligibleForRewards;

    // amount of rewards able to be claimed for a given epoch
    mapping(uint16 => mapping(address => uint256)) public mintableRewards;

    // boolean flag for if rewards have been claimed by a member for a given epoch
    mapping(address => uint16) public lastEpochClaimed;



    // **********************************************************************
    //                   GOVERNANCE CONTROLLED VARIABLES
    // **********************************************************************

    // amount of endorsements a member needs to have in order to participate in contributor rewards
    uint256 public PARTICIPATION_THRESHOLD = 900000;

    // number of endorsements a user needs to have in order to receive rewards
    uint256 public REWARDS_THRESHOLD = 400000;

    // amount of tokens minted per epoch for contributor rewards
    uint256 public CONTRIBUTOR_EPOCH_REWARDS = 500000;

    // min & max percentage of a members rewards that can be given to another member
    uint8 public MIN_ALLOC_PCTG = 5; // max 20 members
    uint8 public MAX_ALLOC_PCTG = 40; // min 3 members

    
    function setParticipationThreshold(uint256 newThreshold_) external onlyOS {
        PARTICIPATION_THRESHOLD = newThreshold_;
    }

    function setRewardsThreshold(uint256 newThreshold_) external onlyOS {
        REWARDS_THRESHOLD = newThreshold_;
    }

    function setContributorEpochRewards(uint256 newEpochRewards_) external onlyOS {
        CONTRIBUTOR_EPOCH_REWARDS = newEpochRewards_;
    }

    function setMinAllocPctg(uint8 newMinAllocPctg_) external onlyOS {
        MIN_ALLOC_PCTG = newMinAllocPctg_;
    }   
    
    function setMaxAllocPctg(uint8 newMaxAllocPctg_) external onlyOS {
        MAX_ALLOC_PCTG = newMaxAllocPctg_;
    }



    // **********************************************************************
    //           REGISTER FOR PEER REWARDS IN THE UPCOMING EPOCH
    // **********************************************************************

    function register() external {
        // get the current epoch for the OS
        uint16 currentEpoch = _Epoch.current();

        // make sure member has at least enough endorsements to register for rewards in the upcoming epoch
        uint256 endorsementsReceived = _Members.totalEndorsementsReceived(msg.sender);
        require (endorsementsReceived >= REWARDS_THRESHOLD, "def_PeerRewards | register(): not enough endorsements to participate!");
        
        eligibleForRewards[current + 1][msg.sender] = true;

        // used to calculate net allocation power for a member based on their participation streak
        uint256 adjustedScore;

        // if member has enough to participate, also register them for allocations
        if (endorsementsReceived >= PARTICIPATION_THRESHOLD) {

            // get the current participation streak for the member
            uint16 streak;
            if (participationHistory[current - 1][msg.sender] == true) {
                streak = participationStreak[msg.sender] + 1;
            } else {
                streak = 1;
            }
            participationStreak[msg.sender] = streak; 
            
            // adjust endorsements based on participation streak: ( +10% / epoch => 100% at 10 epochs in a row )
            if (streak < 10) {
                adjustedScore = endorsementsReceived * streak / 10;
            } else {
                adjustedScore = endorsementsReceived;
            }

            // record the adjusted score in the individual and total registrations for the upcoming epoch
            pointsRegisteredForEpoch[current + 1][msg.sender] += adjustedScore;
            totalPointsRegisteredForEpoch[current + 1] += adjustedScore;

        }

        emit MemberRegistered(msg.sender, current + 1, adjustedScore);
    }



    // **********************************************************************
    //                     CONFIGURE THE ALLOCATION LIST
    // **********************************************************************

    // configure the allocation pts for a member
    function configureAllocation(address toMember_, uint8 newAllocPts_) external {
        require (toMember_ != msg.sender, "def_PeerRewards | configureAllocation(): cannot allocate to self!");
        AllocationsList storage allocList = getAllocationsListFor[msg.sender];

        // remove the allocation if the member sets their pts to 0
        if (newAllocPts_ == 0) {
            _deleteAllocation(toMember_);

        // otherwise, set the member's allocation to the new score.
        } else {

            uint8 allocPts = allocList.allocData[toMember_].pts;

            // if a score doesn't exist for the member, append a new allocation data object to the end of the list.
            if (allocPts == 0) {
                _addNewAllocation(toMember_, newAllocPts_);

            // otherwise, a score exists already, so just set the pts of the existing allocation to the new value
            } else {
                _changeExistingAllocation(toMember_, newAllocPts_);
            }
        }

        emit AllocationSet(msg.sender, toMember_, newAllocPts_);
    }

    // add a new allocation to the list
    function _addNewAllocation(address toMember_, uint8 newAllocPts_) private {
        AllocationsList storage allocList = getAllocationsListFor[msg.sender];

        // if the list isn't empty, adjust the "next" pointer of the previous allocData to this newly created one.
        if (allocList.numAllocs != 0) {
            AllocData storage lastAlloc = allocList.allocData[allocList.TAIL];
            lastAlloc.next = toMember_;

            // set the highest/lowest pts in the list to the new allocation if applicable
            if (newAllocPts_ > allocList.highestPts) { 
                allocList.highestPts = newAllocPts_; 
            } else if (newAllocPts_ < allocList.lowestPts) { 
                allocList.lowestPts = newAllocPts_; 
            }
        
        // otherwise, set the lowest and highest pts to the new list
        } else {
            allocList.highestPts = newAllocPts_;
            allocList.lowestPts = newAllocPts_;
        }

        // create a reference for the new allocation
        allocList.allocData[toMember_] = AllocData(toMember_, allocList.TAIL, address(0), newAllocPts_);

        // point the tail of the list to the newly added allocation
        allocList.TAIL = toMember_;

        // increment the list of allocations
        allocList.numAllocs++;

        // add to the total points allocated by the user
        allocList.totalPts += newAllocPts_;
    }

    function _changeExistingAllocation(address toMember_, uint8 newAllocPts_) private {
        AllocationsList storage allocList = getAllocationsListFor[msg.sender];
        AllocData memory curAlloc = allocList.allocData[toMember_];

        // change the allocation data to the new score
        uint16 oldPts = allocList.allocData[toMember_].pts;
        allocList.allocData[toMember_].pts = newAllocPts_;

        // adjust the total pts allocated
        allocList.totalPts -= oldPts;
        allocList.totalPts += newAllocPts_;
                        
        // if the changed allocation was the previous highest or lowest allocation, loop through the list to find the new highest/lowest alloc
        if (allocList.highestPts == curAlloc.pts || allocList.lowestPts == curAlloc.pts) {

            curAlloc = allocList.allocData[allocList.TAIL];
            uint8 newLowest = curAlloc.pts;
            uint8 newHighest = curAlloc.pts;

            // keep looping until the head
            while (curAlloc.pts != 0) {
                if (curAlloc.pts > newHighest) { newHighest = curAlloc.pts; }
                if (curAlloc.pts < newLowest) { newLowest = curAlloc.pts; }
                curAlloc = allocList.allocData[curAlloc.prev];
            }

            allocList.highestPts = newHighest;
            allocList.lowestPts = newLowest;
        }
    }

    function _deleteAllocation(address toMember_) private {
        AllocationsList storage allocList = getAllocationsListFor[msg.sender];
        AllocData memory curAlloc = allocList.allocData[toMember_];

        // set the prev and next alloc's pointers to each other
        AllocData storage prevAlloc = allocList.allocData[curAlloc.prev];
        prevAlloc.next = curAlloc.next;
        AllocData storage nextAlloc = allocList.allocData[curAlloc.next];
        nextAlloc.next = curAlloc.prev;

        // delete the allocation data (set to default struct) and adjust the state variables
        allocList.allocData[toMember_] = AllocData(address(0), address(0), address(0), 0);
        allocList.totalPts -= curAlloc.pts;
        allocList.numAllocs--;

        // if the member was the tail of the list, set the new tail to the previous allocation
        if (allocList.TAIL == toMember_) {
            allocList.TAIL = curAlloc.prev;
        }
                        
        // if the deleted allocation was the previous highest or lowest allocation, loop through the list to find the new highest/lowest alloc
        if (allocList.highestPts == curAlloc.pts || allocList.lowestPts == curAlloc.pts) {

            curAlloc = allocList.allocData[allocList.TAIL];
            uint8 newLowest = curAlloc.pts;
            uint8 newHighest = curAlloc.pts;

            // keep looping until the head
            while (curAlloc.pts != 0) {
                if (curAlloc.pts > newHighest) { newHighest = curAlloc.pts; }
                if (curAlloc.pts < newLowest) { newLowest = curAlloc.pts; }
                curAlloc = allocList.allocData[curAlloc.prev];
            }

            allocList.highestPts = newHighest;
            allocList.lowestPts = newLowest;
        }
    }



    // **********************************************************************
    //                COMMIT ALLOCATION FOR CURRENT EPOCH
    // **********************************************************************

    function commitAllocation() external {
        AllocationsList storage allocList = getAllocationsListFor[msg.sender];
        uint16 currentEpoch = _Epoch.current();

        // ensure that the member has registered to participate in the current epoch
        require (pointsRegisteredForEpoch[current][msg.sender] > 0, "def_PeerRewards | commitAllocation(): from member did not register for peer rewards this epoch");
        
        // ensure that the member has received the minimum endorsements necessary to participate
        require (_Members.totalEndorsementsReceived(msg.sender) >= PARTICIPATION_THRESHOLD, "def_PeerRewards | commitAllocation(): from member does not enough endorsements received to participate");

        // ensure that the member has not already allocated for the current epoch
        require (participationHistory[current][msg.sender] == false, "def_PeerRewards | commitAllocation(): cannot participate more than once per epoch");

        // ensure that the allocations comply with threshold boundaries
        uint16 highestAllocPctg = 100 * uint16(allocList.highestPts) / allocList.totalPts;
        uint16 lowestAllocPctg = 100 * uint16(allocList.lowestPts) / allocList.totalPts;

        require (highestAllocPctg <= MAX_ALLOC_PCTG && lowestAllocPctg >= MIN_ALLOC_PCTG, "def_PeerRewards | commitAllocation(): allocations do not comply with threshold boundaries");

        // get the member's share of total allocations for the epoch]
        uint256 totalRewardsToGive = CONTRIBUTOR_EPOCH_REWARDS * pointsRegisteredForEpoch[current][msg.sender] / totalPointsRegisteredForEpoch[current];

        // starting from the end, loop through the allocation list and give allocations to each member
        AllocData memory curAlloc = allocList.allocData[allocList.TAIL];
        while (curAlloc.to != address(0)) {

            // ensure that the allocated member has registered for this epoch and meets the minimum endorsements requirement
            require (_Members.totalEndorsementsReceived(curAlloc.to) >= REWARDS_THRESHOLD, "def_PeerRewards | commitAllocation(): to member does not have enough endorsements to receive allocation");
            require (eligibleForRewards[current][curAlloc.to], "def_PeerRewards | commitAllocation(): member did not register for rewards this epoch");

            // increment the mintable rewards for the target member by their share of the member's total rewards to give
            uint256 finalRewardToMember = totalRewardsToGive * curAlloc.pts / allocList.totalPts;
            mintableRewards[current][curAlloc.to] += finalRewardToMember;

            // emit an event for each allocation
            emit AllocationGiven(msg.sender, curAlloc.to, finalRewardToMember, current);

            // get the next allocation in the list
            curAlloc = allocList.allocData[curAlloc.prev];
        }

        // mark the member as participated in allocations for the current
        participationHistory[current][msg.sender] = true;
    }



    // **********************************************************************
    //                CLAIM PEER REWARDS FOR GIVEN EPOCH
    // **********************************************************************

    function claimRewards() external {
        uint16 currentEpoch = _Epoch.current();

        uint256 totalRewardsClaimed;
        
        // loop through the last 4 epochs to claim rewards
        // unclaimed rewards that last more than 4 epochs are expired
        for (uint8 pastEpochs = 1; pastEpochs <= 4; pastEpochs ++ ) {

            uint16 claimEpoch = current - pastEpochs;
            if (claimedRewards[claimEpoch][msg.sender] == false) {
                totalRewardsClaimed += mintableRewards[claimEpoch][msg.sender];

                // mark the epoch as claimed
                claimedRewards[claimEpoch][msg.sender] = true;
            }
        }

        require (totalRewardsClaimed > 0, "def_PeerRewards | claimRewards(): rewards claimed cannot be empty");

        // mint the appropriate amount of tokens to the member
        _Token.mint(msg.sender, totalRewardsClaimed);

        emit RewardsClaimed(msg.sender, totalRewardsClaimed, current);
    }
}
