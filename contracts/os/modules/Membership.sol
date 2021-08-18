// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "../DefaultOS.sol";
// import "../Directory/MemberContract.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";

// import "hardhat/console.sol";

// contract DefaultMembershipsInstaller is DefaultOSModuleInstaller("MBR") {
//     string public moduleName = "DefaultOS Memberships Module";

//     function install(DefaultOS os_) external override returns (address) {
//         DefaultMemberships memberships = new DefaultMemberships(os_);

//         // give ownership to the OS for transfer/upgrade stuff in the future
//         memberships.transferOwnership(address(os_)); 

//         return address(memberships);
//     }
// }

// contract DefaultMemberships is DefaultOSModule {
//     event TokensStaked(address member_, uint256 amount_, uint16 lockDuration_, uint16 currentEpoch);
//     event TokensWithdrawn(address member_, uint256 amount_);

//     modifier requireMembership() {
//         // ensure the calling address has an existing contract with the DAO
//         require(getMemberStakes[msg.sender] != address(0), "Membership does not exist for caller");
//         _;
//     }

//     // alias stuff -> set alias
//     mapping(bytes32 => address) public getMemberForAlias;
//     mapping(address => bytes32) public getAliasForMember;

//     // membership contract
//     mapping(address => address) public getMemberStakes;

//     // qualifying members/participation in the DAO
//     mapping(address => uint256) public totalEndorsementsAvailableToGive; // replace with staking amount

//     // based on staking
//     mapping(address => mapping(address => uint256)) public endorsementsGiven;
//     mapping(address => uint256) public totalEndorsementsGiven;

//     constructor(DefaultOS os_) DefaultOSModule(os_) {}

//     // function _getContract() external view returns (address) {
//     //     return MemberContract;
//     // }

//     function register() external {
//         // ensure that the user does not have an existing member contract
//         require(getMemberStakes[msg.sender] == address(0) && getAliasForMember[msg.sender] == "0x0000000000000000000000000000000000000000000000000000000000000000"); // empty 32 bytes = 64 hex 0s.
//         getMemberStakes[msg.sender] = new MemberStakes();
//     }

//     function _getMultiplierForStakingDuration(uint16 lockDuration_) private view returns (uint256) {
//         if (lockDuration_ < 50 ) { return 0; }
//         else if (lockDuration_ >= 50  && lockDuration_ < 100) { return 1; }
//         else if (lockDuration_ >= 100 && lockDuration_ < 150) { return 3; }
//         else if (lockDuration_ >= 150 && lockDuration_ < 200) { return 6; }
//         else if (lockDuration_ >= 200) { return 10; }
//     }

//     function stakeTokens(uint256 amount_, uint16 lockDuration_) external requireMembership {
//         require (amount_ > 0 && lockDuration_ >= 50, "Member must stake more than 0 tokens and for longer than 50 epochs");
//         uint16 expiryEpoch = _OS.currentEpoch() + lockDuration_;

//         MemberStakes stakes = MemberStakes(getMemberStakes[msg.sender]);

//         totalEndorsementsAvailableToGive[msg.sender] += amount_ * _getMultiplierForStakingDuration(lockDuration_);
//         stakingContract.registerNewStake(amount_, lockDuration_, expiryEpoch);

//         // IERC20 token = IERC20(_OS.getModule("TKN"));
//         // Get the token to stake

//         token.transferFrom(msg.sender, address(this), amount_);

//         // record the event for dapps
//         emit TokensStaked(member_, amount_, lockDuration_, _OS.currentEpoch());
//     }

//     // This is for just one stake, in case stakes get unweildy and gas costs prevent batch unstaking
//     function unstakeTokens() external requireMembership returns (bool) {
//         require(totalEndorsementsAvailableToGive[msg.sender] - amount_ >= totalEndorsementsGiven, "Not enough endorsements remaining after unstaking");

//         MemberStakes stakes = MemberStakes(getMemberStakes[msg.sender]);
        
//         if (stakes.getStakeAt[FIRST].expiryEpoch >= _OS.currentEpoch()) {
//             totalEndorsementsAvailableToGive[msg.sender] -= amount_;
//             dequeueStake(address(this), amount_, duration);
//             return true;
//         } else {
//             return false;
//         }
//     }

//     // This is to unstake everything available (this is the main function members should call)
//     function unstakeAll() external requireMembership {
//         bool successfullyUnstaked = dequeueStake();
//         while (successfullyUnstaked) {
//             successfullyUnstaked = dequeueStake();
//         }
//     }

//     function endorse(address targetMember_, uint256 amount_) external requireMembership {
//         // ensure the endorsed member has an existing contract with the DAO
//         require (getMemberStakes(targetMember_) != address(0), "Target member does not exist");

//         // get the contract for the member being endorsed
//         Membership targetMembership = Membership(getMemberStakes[targetMember_]);

//         // ensure that the member has enough endorsements available
//         require (totalEndorsementsGiven + amount_ <= totalEndorsementsAvailableToGive, "Member does not have available endorsements to give");

//         // REVIEW: STORE MSG.SENDER ADDRESS TO CONTRACT, OR STORE MEMBERCONTRACT?
//         totalEndorsementsGiven[msg.sender] += amount_;
//         targetMemberContract.endorsedBy(msg.sender, amount_);
//     }

//     function withdrawEndorsementFrom(address targetMember_, uint256 amount_) external requireMembership {
//         // get the member contract of the member being endorsed
//         MemberContract targetMemberContract = getMemberStakes[targetMember_];

//         // ensure the endorsed member has an existing contract with the DAO
//         require (address(targetMemberContract) != address(0), "Target member does not exist");
        
//         require(targetMemberContract.endorsementsReceived(msg.sender) >= amount_, "Not enough endorsements to withdraw");

//         endorsementsGiven[targetMember_] -= amount_;
//         totalEndorsementsGiven -= amount_;

//         _OS.removeEndorsement(address(this), targetMember_, amount_);
//     }
// }