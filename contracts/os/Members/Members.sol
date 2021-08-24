// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "../Members/_Staking.sol";
import "../Token/Token.sol";
import "hardhat/console.sol";

contract def_MembersInstaller is DefaultOSModuleInstaller("MBR") {
    string public moduleName = "Default Members";

    function install(DefaultOS os_) external override returns (address) {
        def_Members members = new def_Members(os_);
        members.transferOwnership(address(os_)); 
        return address(members);
    }
}

contract def_Members is Staking, DefaultOSModule {

    // Module Configuration
    def_Token private _Token;

    constructor(DefaultOS os_) DefaultOSModule(os_) {
        _Token = def_Token(_OS.getModule("TKN"));
    }
    

    // Emitted events for this module
    event MemberRegistered(address member, uint16 currentEpoch);
    event TokensStaked(address member, uint256 amount, uint16 lockDuration, uint16 currentEpoch);
    event TokensUnstaked(address member, uint256 amount, uint16 lockDuration, uint16 currentEpoch);
    event EndorsementGiven(address fromMember, address toMember, uint256 endorsementsGiven, uint16 currentEpoch);
    event EndorsementWithdrawn(address fromMember, address toMember, uint256 endorsementsWithdrawn, uint16 currentEpoch);


    // alias stuff
    mapping(bytes32 => address) public getMemberForAlias;
    mapping(address => bytes32) public getAliasForMember;

    // endorsement logic for users
    mapping(address => uint256) public totalEndorsementsAvailableToGive;
    mapping(address => uint256) public totalEndorsementsGiven;
    mapping(address => uint256) public totalEndorsementsReceived;
    mapping(address => mapping(address => uint256)) public endorsementsGiven; // GIVER => mapping (RECEIVER => AMOUNT)
    mapping(address => mapping(address => uint256)) public endorsementsReceived; // RECEIVER => mapping (GIVER => AMOUNT)


    // endorsement multipliers for staking, based on duration. Increase scale quadratically to incentivize long term holder
    function _getMultiplierForStakingDuration(uint16 lockDuration_) private pure returns (uint256 multiplier) {
        if (lockDuration_ < 50 ) { return 0; }
        else if (lockDuration_ >= 50  && lockDuration_ < 100) { return 1; }
        else if (lockDuration_ >= 100 && lockDuration_ < 150) { return 3; }
        else if (lockDuration_ >= 150 && lockDuration_ < 200) { return 6; }
        else if (lockDuration_ >= 200) { return 10; }
    }



    // **********************************************************************
    //                     SET THE ALIAS FOR THE MEMBER
    // **********************************************************************

    function setAlias(bytes32 alias_) external {
        // make sure the alias space is empty 
        require (getMemberForAlias[alias_] == address(0), "def_Members | (): Members | setAlias(): alias is already taken");
        getAliasForMember[msg.sender] = alias_;
        getMemberForAlias[alias_] = msg.sender;
    }



    // **********************************************************************
    //                     MINT ENDORSEMENTS TO GIVE
    // **********************************************************************

    function mintEndorsements(uint16 lockDuration_, uint256 tokensStaked_) external {
        require (tokensStaked_ > 0, "def_Members | (): def_Members | mintEndorsements() : member must stake more than 0 tokens");
        require (lockDuration_ >= 50, "def_Members | (): def_Members | mintEndorsements(): member must stake for at least 50 epochs");
        
        uint16 expiryEpoch = _OS.currentEpoch() + lockDuration_;

        // get the adjusted amount of endorsements based on staking duration
        totalEndorsementsAvailableToGive[msg.sender] += tokensStaked_ * _getMultiplierForStakingDuration(lockDuration_);

        // register the stake and transfer tokens
        _registerNewStake(expiryEpoch, lockDuration_, tokensStaked_);
        _Token.transferFrom(msg.sender, address(this), tokensStaked_);

        emit TokensStaked(msg.sender, tokensStaked_, lockDuration_, _OS.currentEpoch());
    }



    // **********************************************************************
    //                  RECLAIM TOKENS FROM EXPIRED STAKES
    // **********************************************************************

    function reclaimTokens() external {

        // get the stakes for the caller
        (uint16 lockDuration, uint16 expiryEpoch, uint256 amountStaked) = _dequeueStake();

        // User should withdraw the necessary endorsements prior to unstaking
        require (totalEndorsementsAvailableToGive[msg.sender] - amountStaked >= totalEndorsementsGiven[msg.sender], "def_Members | reclaimTokens(): Not enough endorsements remaining after unstaking");

        // The current Epoch should be higher than the expiry epoch
        require (_OS.currentEpoch() >= expiryEpoch, "def_Members | reclaimTokens(): No expired stakes available for withdraw");

        // get the adjusted tokens to reclaim based on the lock duration and transfer the tokens back to the member
        totalEndorsementsAvailableToGive[msg.sender] -= amountStaked * _getMultiplierForStakingDuration(lockDuration);
        _Token.transfer(msg.sender, amountStaked);

        emit TokensUnstaked(msg.sender, amountStaked, lockDuration, _OS.currentEpoch());
    }

    

    // **********************************************************************
    //                        ENDORSE ANOTHER MEMBER
    // **********************************************************************

    function endorseMember(address targetMember_, uint256 tokensStaked_) external {

        // ensure that the member has enough endorsements available
        require (totalEndorsementsGiven[msg.sender] + tokensStaked_ <= totalEndorsementsAvailableToGive[msg.sender], "def_Members | endorseMember(): Member does not have available endorsements to give");

        // increment the applicable states for the giver
        totalEndorsementsGiven[msg.sender] += tokensStaked_;
        endorsementsGiven[msg.sender][targetMember_] += tokensStaked_;

        // increment the applicable states for the receiver
        totalEndorsementsReceived[targetMember_] += tokensStaked_;
        endorsementsReceived[targetMember_][msg.sender] += tokensStaked_;

        emit EndorsementGiven(msg.sender, targetMember_, tokensStaked_, _OS.currentEpoch());
    }



    // **********************************************************************
    //               WITHDRAW ENDORSEMENTS FROM ANOTHER MEMBER
    // **********************************************************************

    function withdrawEndorsementFrom(address targetMember_, uint256 tokensStaked_) external {

        // ensure that the member has enough endorsements to withdraw
        require(endorsementsGiven[msg.sender][targetMember_] >= tokensStaked_, "def_Members | withdrawEndorsementFrom(): Not enough endorsements to withdraw");

        // decrement the applicable states for the giver
        totalEndorsementsGiven[msg.sender] -= tokensStaked_;
        totalEndorsementsReceived[targetMember_] -= tokensStaked_;

        // decrement the applicable states for the giver
        endorsementsGiven[msg.sender][targetMember_] -= tokensStaked_;
        endorsementsReceived[targetMember_][msg.sender ] -= tokensStaked_;

        emit EndorsementWithdrawn(msg.sender, targetMember_, tokensStaked_, _OS.currentEpoch());
    }
}