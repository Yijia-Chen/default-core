// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DefaultOS.sol";
import "../Token/Token.sol";
import "./_Vault.sol";

contract def_MiningInstaller is DefaultOSModuleInstaller("BSM") {
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

    constructor(DefaultOS os_) DefaultOSModule(os_) {
        _Token = def_Token(_OS.getModule("TKN"));
    }

    // emitted events
    // event VaultOpened(Vault vault, uint16 epochOpened);


    // token contract => vault contract; ensures only one vault per token
    mapping(address => uint256) public ineligibleRewards;
    uint256 public constant mult = 1e12;
    uint256 public accRewardsPerShare = 0;
    Vault public vaultShares;



    // **********************************************************************
    //                   OPEN NEW VAULT (GOVERNANCE ONLY)
    // **********************************************************************

    function pendingRewards(address depositor_) public view returns (uint256) {
        uint256 totalHistoricalRewards = vaultShares.balanceOf(depositor_) * accRewardsPerShare;
        uint256 finalDepositorRewards = (totalHistoricalRewards - ineligibleRewards[depositor_]) / mult;

        // just in case somehow rounding error causes finalDepositorRewards to exceed the balance of the tokens in the contract
        if ( finalDepositorRewards > _Token.balanceOf(address(this)) ) {
             finalDepositorRewards = _Token.balanceOf(address(this));
        }

        return finalDepositorRewards;
    }

    function register(address depositor_) external {
        ineligibleRewards[msg.sender] = vaultShares.balanceOf(depositor_) * accRewardsPerShare;
    }

    function claimRewardsFor(address redeemer_) external {
        uint rewards = pendingRewards(redeemer_);
        ineligibleRewards[msg.sender] = vaultShares.balanceOf(redeemer_) * accRewardsPerShare;
        _Token.transfer(redeemer_, rewards);
    }

    // reset the amount of rewards accumulated so far by the the depositor's shares
    function _resetClaimableRewards(address depositor_) internal {
        ineligibleRewards[msg.sender] = vaultShares.balanceOf(depositor_) * accRewardsPerShare;
    }

    // update the amount of rewards accumulated by each incentivized share
    function _distributeRewards(uint256 newRewards_) external {
        require(vaultShares.totalSupply() > 0, "ClaimableRewards distributeRewards(): USDC Treasury Vault cannot be empty");
        accRewardsPerShare += newRewards_ * mult / vaultShares.totalSupply();

        // @dev note:
        // There will always be some precision issues due to rounding errors. In solidity, integer
        // division always rounds towards zero, so 7.9 -> 7. This means that the rewards contract
        // will always distribute ever slightly fewer shares than it receives, so it collects some dust
        // over time.
    }
}