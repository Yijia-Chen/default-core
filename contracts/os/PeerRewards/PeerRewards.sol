// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
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

    constructor(DefaultOS os_) DefaultOSModule(os_) {
        _Token = def_Token(_OS.getModule("TKN"));
        _Members = def_Members(_OS.getModule("MBR"));
    }


    // Emitted events for this module
    event MemberRegistered(address member, uint16 epochRegisteredFor, uint256 ptsRegistered);
    event AllocationSet(address fromMember, address toMember, uint8 allocPts);
    event AllocationGiven(address fromMember, address toMember, uint256 allocGiven, uint16 currentEpoch);
    event RewardsClaimed(address member, uint256 rewardsClaimed, uint16 epochClaimedFor);


    // amount of endorsements a member needs to have in order to participate in contributor rewards
    uint256 public PARTICIPATION_THRESHOLD = 1500000;

    // number of endorsements a user needs to have in order to receive rewards
    uint256 public REWARDS_THRESHOLD = 500000;

    // amount of tokens minted per epoch for contributor rewards
    uint256 public CONTRIBUTOR_EPOCH_REWARDS = 500000;

    // min & max percentage of a members rewards that can be given to another member
    uint8 public MIN_ALLOC_PCTG = 6; // max 16 members
    uint8 public MAX_ALLOC_PCTG = 33; // min 3 members


    // persistent allocation data for a particular member
    struct AllocData {
        address to; // the address of the member currently being allocated to
        address prev; // the address of the member
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

    // amount of rewards able to be claimed for a given epoch
    mapping(uint16 => mapping(address => uint256)) public mintableRewards;

    // boolean flag for if rewards have been claimed by a member for a given epoch
    mapping(uint16 => mapping(address => bool)) public claimedRewards;



    // **********************************************************************
    //           REGISTER FOR PEER REWARDS IN THE UPCOMING EPOCH
    // **********************************************************************

    function register() external {
        // get the current epoch for the OS
        uint16 currentEpoch = _OS.currentEpoch();

        // get the endorsements received for the member and make sure they have enough endorsements to register for the upcoming epoch
        uint256 endorsementsReceived = _Members.totalEndorsementsReceived(msg.sender);
        require (endorsementsReceived >= PARTICIPATION_THRESHOLD, "Registration | register(): not enough endorsements to participate!");

        // if member participated last epoch, increment the streak; otherwise reset the streak to 1.
        uint16 streak;

        if (participationHistory[currentEpoch - 1][msg.sender] == true) {
            streak = participationStreak[msg.sender] + 1;
        } else {
            streak = 1;
        }

        participationStreak[msg.sender] = streak; 
        
        // adjust the amount of endorsements able to register for the member based on their participation streak
        // ( +10% / epoch => 100% at 10 epochs in a row )
        uint256 adjustedScore;

        if (streak < 10) {
            adjustedScore = endorsementsReceived * streak / 10;
        } else {
            adjustedScore = endorsementsReceived;
        }

        totalPointsRegisteredForEpoch[currentEpoch + 1] += adjustedScore;
        pointsRegisteredForEpoch[currentEpoch + 1][msg.sender] += adjustedScore;

        emit MemberRegistered(msg.sender, currentEpoch + 1, adjustedScore);
    }



    // **********************************************************************
    //                     CONFIGURE THE ALLOCATION LIST
    // **********************************************************************

    // configure the allocation pts for a member
    function configureAllocation(address toMember_, uint8 newAllocPts_) external {
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
        }

        // create a reference for the new allocation
        allocList.allocData[toMember_] = AllocData(toMember_, allocList.TAIL, address(0), newAllocPts_);

        // point the tail of the list to the newly added allocation
        allocList.TAIL = toMember_;

        // increment the list of allocations
        allocList.numAllocs++;
         
        // set the highest/lowest pts in the list to the new allocation if applicable
        if (newAllocPts_ > allocList.highestPts) {
            allocList.highestPts = newAllocPts_;
        } else if (newAllocPts_ < allocList.lowestPts) {
            allocList.lowestPts = newAllocPts_;
        }
    }

    function _changeExistingAllocation(address toMember_, uint8 newAllocPts_) private {
        AllocationsList storage allocList = getAllocationsListFor[msg.sender];

        // change the allocation data to the new score
        allocList.allocData[toMember_].pts = newAllocPts_;
                        
        // set the highest/lowest pts in the list to the new allocation if applicable
        if (newAllocPts_ > allocList.highestPts) {
            allocList.highestPts = newAllocPts_;
        } else if (newAllocPts_ < allocList.lowestPts) {
            allocList.lowestPts = newAllocPts_;
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
                        
        // if the deleted allocation was the previous highest or lowest allocation, loop through the list to find the new highest/lowest alloc
        if (allocList.highestPts == curAlloc.pts || allocList.lowestPts == curAlloc.pts) {

            curAlloc = allocList.allocData[allocList.TAIL];
            uint8 newLowest = 0;
            uint8 newHighest = 0;

            // keep looping until the head
            while (curAlloc.prev != address(0)) {
                curAlloc = allocList.allocData[curAlloc.prev];
                if (curAlloc.pts > newHighest) { newHighest = curAlloc.pts; }
                if (curAlloc.pts > newLowest) { newLowest = curAlloc.pts; }
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
        uint16 currentEpoch = _OS.currentEpoch();
        
        // ensure that the member has received the minimum endorsements necessary to participate
        require (_Members.totalEndorsementsReceived(msg.sender) > PARTICIPATION_THRESHOLD, "def_PeerRewards | commitAllocation(): from member does not enough endorsements received to participate");

        // ensure that the member has registered to participate in the current epoch
        require (pointsRegisteredForEpoch[currentEpoch][msg.sender] > 0, "def_PeerRewards | commitAllocation(): from member did not register for peer rewards this epoch");

        // ensure that the member has not already participated for the current epoch
        require (participationHistory[currentEpoch][msg.sender] == false, "def_PeerRewards | commitAllocation(): cannot participate more than once per epoch");

        // ensure that the allocations comply with threshold boundaries
        uint16 highestAllocPctg = 100 * allocList.highestPts / allocList.totalPts;
        uint16 lowestAllocPctg = 100 * allocList.lowestPts / allocList.totalPts;
        require (highestAllocPctg < MAX_ALLOC_PCTG && lowestAllocPctg > MIN_ALLOC_PCTG, "def_PeerRewards | commitAllocation(): allocations do not comply with threshold boundaries");

        // get the member's share of total allocations for the epoch]
        uint256 totalRewardsToGive = CONTRIBUTOR_EPOCH_REWARDS * pointsRegisteredForEpoch[currentEpoch][msg.sender] / totalPointsRegisteredForEpoch[currentEpoch];
    
        // get the TAIL for the allocation list
        AllocData memory curAlloc = allocList.allocData[allocList.TAIL];
        while (curAlloc.prev != address(0)) {

            // ensure that the member being allocated to has recevied the minimnum endorsements necessary to receive allocations
            require (_Members.totalEndorsementsReceived(curAlloc.to) > REWARDS_THRESHOLD, "def_PeerRewards | commitAllocation(): to member does not have enough endorsements to receive allocation");

            // increment the mintable rewards for the target member by their share of the member's total rewards to give
            uint256 finalRewardToMember = totalRewardsToGive * curAlloc.pts / allocList.totalPts;
            mintableRewards[currentEpoch][curAlloc.to] += finalRewardToMember;

            emit AllocationGiven(msg.sender, curAlloc.to, finalRewardToMember, currentEpoch);
        }
        
        // mark the member as participated in allocations for the currentEpoch
        participationHistory[currentEpoch][msg.sender] = true;
    }



    // **********************************************************************
    //                CLAIM PEER REWARDS FOR GIVEN EPOCH
    // **********************************************************************

    function claimRewards(uint16 claimEpoch_) external {
        uint16 currentEpoch = _OS.currentEpoch();

        // make sure claiming epoch is within 3 epochs—-rewards expire after 4 epochs
        require (currentEpoch - claimEpoch_ <= 4 && currentEpoch - claimEpoch_ >= 1, "def_PeerRewards | claimRewards(): epoch rewards cannot be claimed (EXPIRED or TOO EARLY)");

        // make sure user can't claim twice
        require (claimedRewards[claimEpoch_][msg.sender] = false, "def_PeerRewards | claimRewards(): epoch rewards have already been claimed");
        
        // mark the epoch as claimed
        claimedRewards[claimEpoch_][msg.sender] = true;

        // mint the appropriate amount of tokens to the member
        uint256 rewardsClaimed = mintableRewards[claimEpoch_][msg.sender];
        _Token.mint(msg.sender, rewardsClaimed);

        emit RewardsClaimed(msg.sender, rewardsClaimed, claimEpoch_);
    }



    // **********************************************************************
    //                   CONTRACT VARIABLE CONFIGURATION
    // **********************************************************************
    
    function setParticipationThreshold(uint256 newThreshold_) external onlyOwner {
        PARTICIPATION_THRESHOLD = newThreshold_;
    }

    function setRewardsThreshold(uint256 newThreshold_) external onlyOwner {
        REWARDS_THRESHOLD = newThreshold_;
    }

    function setContributorEpochRewards(uint256 newEpochRewards_) external onlyOwner {
        CONTRIBUTOR_EPOCH_REWARDS = newEpochRewards_;
    }

    function setMinAllocPctg(uint8 newMinAllocPctg_) external onlyOwner {
        MIN_ALLOC_PCTG = newMinAllocPctg_;
    }   
    
    function setMaxAllocPctg(uint8 newMaxAllocPctg_) external onlyOwner {
        MAX_ALLOC_PCTG = newMaxAllocPctg_;
    }
}
