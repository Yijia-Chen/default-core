// SPDX-License-Identifier: MIT

// Do mining as allocation on vaults. E.g. 5 alloc -> usdc, 1 alloc -> def => 5/6 rewards go to share holder;


pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "../DefaultOS.sol";
import "../Token/Token.sol";
import "../Epoch/Epoch.sol";
import "./Treasury.sol";
import "./_Vault.sol";

contract def_MiningInstaller is DefaultOSModuleInstaller("MNG") {
    string public moduleName = "Default Treasury Mining";

    function install(DefaultOS os_) external override returns (address) {
        def_Mining Mining = new def_Mining(os_);
        Mining.transferOwnership(address(os_)); 
        return address(Mining);
    }
}

contract def_Mining is DefaultOSModule {

    // Module Configuration
    def_Token private _Token;
    def_Epoch private _Epoch;
    def_Treasury private _Treasury;
    Vault private _vault;


    constructor(DefaultOS os_) DefaultOSModule(os_) {
        _Token = def_Token(_OS.getModule("TKN"));
        _Epoch = def_Epoch(_OS.getModule("EPC"));
        _Treasury = def_Treasury(_OS.getModule("TSY"));
    }

    // emitted events
    event RewardsIssued(uint16 currentEpoch, uint256 newRewardsPerShare);
    event RewardsClaimed(uint16 epochClaimed, address member, uint256 totalRewardsClaimed);
    event Registered(uint16 currentEpoch, address member);


    mapping(address => uint256) unclaimableRewards;
    mapping(address => bool) registered;


    uint256 public accRewardsPerShare = 0;
    uint256 public lastEpochIssued = 1;
    uint256 public constant EPOCH_MINING_REWARDS = 500000; 
    uint256 private constant MULT = 1e12;


    // **********************************************************************
    //                   GOVERNANCE CONTROLLED VARIABLES
    // **********************************************************************

    // weekly rewards to the caller of the issueRewards() function
    uint256 public TOKEN_BONUS = 5000; 

    function setTokenBonus(uint256 newTokenBonus_) external onlyOS {
        TOKEN_BONUS = newTokenBonus_;
    }



    // **********************************************************************
    //                 GET THE PENDING REWARDS FOR THE USER
    // **********************************************************************

    // calculate the available rewards for the caller
    function pendingRewards() public view returns (uint256) {
        uint256 totalHistoricalRewards = _vault.balanceOf(msg.sender) * accRewardsPerShare;                
        uint256 finalDepositorRewards = (totalHistoricalRewards - unclaimableRewards[msg.sender]) / MULT;
        
        // console.log(_vault.balanceOf(msg.sender));
        // console.log(accRewardsPerShare);
        // console.log(totalHistoricalRewards);
        // console.log(unclaimableRewards[msg.sender]);
        // console.log(address(this));
        // console.log(_Token.balanceOf(address(this)));
        // console.log(finalDepositorRewards);

        // just in case somehow rounding error causes finalDepositorRewards to exceed the balance of the tokens in the contract
        if ( finalDepositorRewards > _Token.balanceOf(address(this)) ) {
             finalDepositorRewards = _Token.balanceOf(address(this));
        }        

        return finalDepositorRewards;
    }

    
    
    // **********************************************************************
    //                  START THE TREASURY MINING PROGRAM
    // **********************************************************************

    // assign the vault contract for the program to "activate" it
    function assignVault(address token_) external onlyOS {        
        require (address(_vault) == address(0), "can only assign vault once");        
        _vault = _Treasury.getVault(token_);
    }

    // **********************************************************************
    //                 ISSUE EPOCH REWARDS TO SHAREHOLDERS
    // **********************************************************************

    // Note: this design is not entirely ideal, because someone could manipulate the system by depositing/withdrawing right before
    // calling the accumulate rewards function. There might be some issues there, not entirely sure though how severe they are 
    // but intuition is telling me it is an okay trade off to make (for now).
    function issueRewards() external {

        // issue only once per epoch
        require (lastEpochIssued != _Epoch.current(), "rewards have already been accumulated for the current epoch");
        require (address(_vault) != address(0), "vault is not configured!");
        require (_vault.totalSupply() > 0, "vault supply has to exist");

        // record that rewards have been issued for the current epoch
        lastEpochIssued = _Epoch.current();

        // rewards per share for this epoch
        uint256 newRewardsPerShare = EPOCH_MINING_REWARDS * MULT / _vault.totalSupply();        
        // increment the accRewardsPerShare based on the total deposits at the time of calling this function
        accRewardsPerShare += newRewardsPerShare;        
        // mint the caller tokens for their service!

        _Token.mint(address(this), EPOCH_MINING_REWARDS);
        _Token.mint(msg.sender, TOKEN_BONUS);

        emit RewardsIssued(_Epoch.current(), newRewardsPerShare);
    }

    // **********************************************************************
    //                 RESET MINING REWARDS COUNTER FOR USER
    // **********************************************************************

    function register() external {
        // reset the unclaimable rewards to the latest amount.
        unclaimableRewards[msg.sender] = _vault.balanceOf(msg.sender) * accRewardsPerShare;
        registered[msg.sender] = true;

        emit Registered(_Epoch.current(), msg.sender);
    }



    // **********************************************************************
    //                       CLAIM AVAILABLE REWARDS
    // **********************************************************************

    function claimRewards() external {
        require (registered[msg.sender], "member is not registered for mining program");
        
        // save the pending rewards available to user
        uint256 rewards = pendingRewards();

        // reset the unclaimable rewards to the latest amount.
        unclaimableRewards[msg.sender] = _vault.balanceOf(msg.sender) * accRewardsPerShare;

        // mint the pending rewards to the user
        _Token.mint(msg.sender, rewards);

        emit RewardsClaimed(_Epoch.current(), msg.sender, rewards);
    }
}