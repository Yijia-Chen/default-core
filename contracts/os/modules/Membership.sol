// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "../Directory/MemberContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract DefaultMembershipsInstaller is DefaultOSModuleInstaller("MBR") {
    string public moduleName = "DefaultOS Memberships Module";

    function install(DefaultOS os_) external override returns (address) {
        DefaultMemberships memberships = new DefaultMemberships(os_);

        // give ownership to the OS for transfer/upgrade stuff in the future
        memberships.transferOwnership(address(os_)); 

        return address(memberships);
    }
}

contract DefaultMemberships is DefaultOSModule {
    event MemberRegistered(address member, uint16 currentEpoch);
    event TokensStaked(address member, uint256 amount, uint16 lockDuration, uint16 currentEpoch);
    event TokensUnstaked(address member, uint256 amount, uint16 lockDuration, uint16 currentEpoch);
    event EndorsementGiven(address fromMember, address toMember, uint256 endorsementsGiven, uint16 currentEpoch);
    event EndorsementWithdrawn(address fromMember, address toMember, uint256 endorsementsWithdrawn, uint16 currentEpoch);

    modifier requireMembership() {
        // ensure the calling address has an existing contract with the DAO
        require(address(getMemberStakes[msg.sender]) != address(0), "Membership required to call this function");
        _;
    }

    // alias stuff -> set alias
    mapping(bytes32 => address) public getMemberForAlias;
    mapping(address => bytes32) public getAliasForMember;

    // membership contract
    mapping(address => MemberStakes) public getMemberStakes;

    // qualifying members/participation in the DAO
    mapping(address => uint256) public totalEndorsementsAvailableToGive; // replace with staking amount
    mapping(address => uint256) public totalEndorsementsGiven;
    mapping(address => uint256) public totalEndorsementsReceived;

    // GIVER => mapping (RECEIVER => AMOUNT)
    mapping(address => mapping(address => uint256)) public endorsementsGiven;

    // RECEIVER => mapping (GIVER => AMOUNT)
    mapping(address => mapping(address => uint256)) public endorsementsReceived;


    IERC20 private _defToken;

    constructor(DefaultOS os_) DefaultOSModule(os_) {
        _defToken = IERC20(_OS.getModule("TKN"));
    }

    function register() external {
        // ensure that the user does not have an existing member contract
        require(address(getMemberStakes[msg.sender]) == address(0), "Member already exists"); // && getAliasForMember[msg.sender] == "0x0000000000000000000000000000000000000000000000000000000000000000"); // empty 32 bytes = 64 hex 0s.
        getMemberStakes[msg.sender] = new MemberStakes();
        emit MemberRegistered(msg.sender, _OS.currentEpoch());
    }

    function _getMultiplierForStakingDuration(uint16 lockDuration_) private pure returns (uint256) {
        if (lockDuration_ < 50 ) { return 0; }
        else if (lockDuration_ >= 50  && lockDuration_ < 100) { return 1; }
        else if (lockDuration_ >= 100 && lockDuration_ < 150) { return 3; }
        else if (lockDuration_ >= 150 && lockDuration_ < 200) { return 6; }
        else if (lockDuration_ >= 200) { return 10; }
    }

    function stakeTokens(uint16 lockDuration_, uint256 amount_) external requireMembership {
        require (amount_ > 0, "Member must stake more than 0 tokens");
        require (lockDuration_ >= 50, "Minimum stake duration is 50 epochs");
        
        uint16 expiryEpoch = _OS.currentEpoch() + lockDuration_;

        MemberStakes memberStakes = MemberStakes(getMemberStakes[msg.sender]);

        totalEndorsementsAvailableToGive[msg.sender] += amount_ * _getMultiplierForStakingDuration(lockDuration_);
        memberStakes.registerNewStake(expiryEpoch, lockDuration_, amount_);

        _defToken.transferFrom(msg.sender, address(this), amount_);

        // record the event for dapps
        emit TokensStaked(msg.sender, amount_, lockDuration_, _OS.currentEpoch());
    }

    // This is for just one stake, in case stakes get unweildy and gas costs prevent batch unstaking
    function unstakeTokens() external requireMembership {
        // get the memberStakes for the caller
        MemberStakes memberStakes = MemberStakes(getMemberStakes[msg.sender]);
        (uint16 lockDuration, uint16 expiryEpoch, uint256 amountStaked) = memberStakes.dequeueStake();

        // User should withdraw the necessary endorsements prior to unstaking
        require (totalEndorsementsAvailableToGive[msg.sender] - amountStaked >= totalEndorsementsGiven[msg.sender], "Not enough endorsements remaining after unstaking");

        // The current Epoch should be higher than the expiry epoch
        require (_OS.currentEpoch() >= expiryEpoch, "No expired stakes available for withdraw");

        totalEndorsementsAvailableToGive[msg.sender] -= amountStaked * _getMultiplierForStakingDuration(lockDuration);
        _defToken.transfer(msg.sender, amountStaked);

        // record the event for dapps
        emit TokensUnstaked(msg.sender, amountStaked, lockDuration, _OS.currentEpoch());
    }

    function endorseMember(address targetMember_, uint256 amount_) external requireMembership {
        // ensure the endorsed member has an existing contract with the DAO
        require (address(getMemberStakes[targetMember_]) != address(0), "Target member is not registered");

        // ensure that the member has enough endorsements available
        require (totalEndorsementsGiven[msg.sender] + amount_ <= totalEndorsementsAvailableToGive[msg.sender], "Member does not have available endorsements to give");

        totalEndorsementsGiven[msg.sender] += amount_;
        totalEndorsementsReceived[targetMember_] += amount_;

        endorsementsGiven[msg.sender][targetMember_] += amount_;
        endorsementsReceived[targetMember_][msg.sender] += amount_;

        emit EndorsementGiven(msg.sender, targetMember_, amount_, _OS.currentEpoch());
    }

    function withdrawEndorsementFrom(address targetMember_, uint256 amount_) external requireMembership {
        // ensure that the member has enough endorsements to withdraw
        require(endorsementsGiven[msg.sender][targetMember_] >= amount_, "Not enough endorsements to withdraw");

        totalEndorsementsGiven[msg.sender] -= amount_;
        totalEndorsementsReceived[targetMember_] -= amount_;

        endorsementsGiven[msg.sender][targetMember_] -= amount_;
        endorsementsReceived[targetMember_][msg.sender ] -= amount_;

        emit EndorsementWithdrawn(msg.sender, targetMember_, amount_, _OS.currentEpoch());
    }
}