// SPDX-License-Identifier: MIT

// Do mining as allocation on vaults. E.g. 5 alloc -> usdc, 1 alloc -> def => 5/6 rewards go to share holder;


pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "../Token/Token.sol";
import "./Treasury.sol";
import "./_Vault.sol";

contract def_MiningInstaller is DefaultOSModuleInstaller("MIN") {
    string public moduleName = "Default Balance Sheet Mining";

    function install(DefaultOS os_) external override returns (address) {
        def_Mining Mining = new def_Mining(os_);
        Mining.transferOwnership(address(os_)); 
        return address(Mining);
    }
}

contract def_Mining is DefaultOSModule {

    // Module Configuration
    def_Token private _Token;
    def_Treasury public _Treasury;

    constructor(DefaultOS os_) DefaultOSModule(os_) {
        _Token = def_Token(_OS.getModule("TKN"));
        _Treasury = def_Treasury(_OS.getModule("TSY"));
    }

    // emitted events
    // event VaultOpened(Vault vault, uint16 epochOpened);


    mapping(address => uint256) nullRewards;


    Vault private _vault;
    uint256 public accRewardsPerShare = 0;
    uint256 public lastEpochAccumulated = 1;
    uint256 public TOKEN_BONUS = 100; // governance configurable
    uint256 public constant EPOCH_MINING_REWARDS = 500000; 
    uint256 private constant MULT = 1e12;



    // **********************************************************************
    //                  START THE TREASURY MINING PROGRAM
    // **********************************************************************

    // assign the vault contract for the program to "activate" it
    function configureVault(Vault vault_) external onlyOwner {
        require (address(_vault) == address(0), "def_Mining | configureVault(): can only configure vault once");
        _vault = vault_;
    }



    // **********************************************************************
    //                 GET THE PENDING REWARDS FOR THE USER
    // **********************************************************************

    // calculate the available rewards for the caller
    function pendingRewards() public view returns (uint256) {
        uint256 totalHistoricalRewards = _vault.balanceOf(msg.sender) * accRewardsPerShare;
        uint256 finalDepositorRewards = (totalHistoricalRewards - nullRewards[msg.sender]) / MULT;

        // just in case somehow rounding error causes finalDepositorRewards to exceed the balance of the tokens in the contract
        if ( finalDepositorRewards > _Token.balanceOf(address(this)) ) {
             finalDepositorRewards = _Token.balanceOf(address(this));
        }

        return finalDepositorRewards;
    }

    // Note: this design is not entirely ideal, because someone could manipulate the system by depositing/withdrawing right before
    // calling the accumulate rewards function. There might be some issues there, not entirely sure though how severe they are 
    // but intuition is telling me it is an okay trade off to make (for now).

    function accumulateRewards() external {
        require (lastEpochAccumulated != _OS.currentEpoch(), "def_Mining | accumulateRewrds(): rewards have already been accumulated for the current Epoch");

        // set the last epoch accumulated to the current epoch
        lastEpochAccumulated = _OS.currentEpoch();

        // increment the accRewardsPerShare based on the total deposits at the time of calling this function
        accRewardsPerShare += (EPOCH_MINING_REWARDS * MULT / _vault.totalSupply());         // test to make sure this cannot work for empty vault;

        // mint the caller tokens for their service!
        _Token.mint(msg.sender, TOKEN_BONUS);
    }

    function register(address depositor_) external {
        nullRewards[msg.sender] = _vault.balanceOf(depositor_) * accRewardsPerShare;
    }


    function claimRewardsFor(address redeemer_) external {
        uint rewards = pendingRewards();
        nullRewards[msg.sender] = _vault.balanceOf(redeemer_) * accRewardsPerShare;
        _Token.transfer(redeemer_, rewards);
    }

    // reset the amount of rewards accumulated so far by the the depositor's shares
    function _resetClaimableRewards(address depositor_) internal {
        nullRewards[msg.sender] = _vault.balanceOf(depositor_) * accRewardsPerShare;
    }

    // update the amount of rewards accumulated by each incentivized share
    function _distributeRewards(uint256 newRewards_) external {
        require(_vault.totalSupply() > 0, "ClaimableRewards distributeRewards(): USDC Treasury Vault cannot be empty");
        accRewardsPerShare += newRewards_ * MULT / _vault.totalSupply();

        // @dev note:
        // There will always be some precision issues due to rounding errors. In solidity, integer
        // division always rounds towards zero, so 7.9 -> 7. This means that the rewards contract
        // will always distribute ever slightly fewer shares than it receives, so it collects some dust
        // over time.
    }
}