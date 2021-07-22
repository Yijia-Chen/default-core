// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/AppContract.sol";
import "./interfaces/IRewarder.sol";

// The Default version of the Masterchef contract. We distribute rewards using the same principle.
// For formal paper for this strategy, see: https://uploads-ssl.webflow.com/5ad71ffeb79acc67c8bcdaba/5ad8d1193a40977462982470_scalable-reward-distribution-paper.pdf
// Calculating rewards is tricky. We are using a contract with logic derived from the OG rewards contract,Sushiswap's Masterchef.sol: 
// https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol

// Copied verbatim from the original contract:

    // We do some fancy math here. Basically, any point in time, the amount of SUSHIs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.

// Default's rewarder uses the same mechanism but with drastically simplified logic:
// 1. we have a single pool (USDC Vault), so we can remove all pool allocation logic
// 2. distribution epochs are weekly instead of per block, so 
// 3. there is no special multiplier logic for early participants
// 4. minting happens outside the contract, and reward tokens are sent in (instead of directly minted)

// note: we are also changing the "rewardDebt" variable to "ineligbleRewards" for contract clarity.

// Here's our very first balance sheet mining contract. In the words of a notorious chef:

    // Have fun reading it. Hopefully it's bug-free. God bless.

contract DepositRewarderV1 is IRewarder, AppContract {

    IERC20 private _usdcVaultShares; // the usdc vault shares contract, we give owners of these some dnt vault share rewards too!
    IERC20 private _dntVaultShares; // the dnt vault shares contract, our reward token.
    uint256 private _accDntPerShare; // the total amount of DntPerShare accumulated from the beginning.
    uint256 private _reservedRewardShares; // the total amount of shares currently held in the contract reserved for claimable rewards
    mapping(address => uint256) private _ineligibleRewards; // previously user.rewardDebt

    // because the vault is a separate contract, the USDC vault has to register the deposit to the rewarder
    // for eligibility. This makes it so that only direct vault depositors have access to rewards, but also helps
    // cleanly separate functionality between vault stuff and rewards stuff.

    constructor(IERC20 usdcVaultShares_, IERC20 dntVaultShares_, IMemberships memberships_) AppContract(memberships_) {
        _usdcVaultShares = usdcVaultShares_;
        _dntVaultShares = dntVaultShares_;
        _accDntPerShare = 0;
        _reservedRewardShares = 0;
    }

    function register(address depositor_) external override onlyOwner returns (bool) {
        _ineligibleRewards[depositor_] = _accDntPerShare * _usdcVaultShares.balanceOf(depositor_);
        return true;
    }

    function pendingRewards(address depositor_) public view override returns (uint256) {
        return (_usdcVaultShares.balanceOf(depositor_) * _accDntPerShare) - _ineligibleRewards[depositor_];
    }

    function claim() external override onlyMember returns (bool) {
        uint256 rewards = pendingRewards(msg.sender);
        _dntVaultShares.transfer(msg.sender, rewards);
        _ineligibleRewards[msg.sender] = _usdcVaultShares.balanceOf(msg.sender) * _accDntPerShare;
        return true;
    }

    function updateRewards() external override returns (bool) {
        uint256 newRewards = _dntVaultShares.balanceOf(address(this)) - _reservedRewardShares;
        _accDntPerShare = newRewards/_usdcVaultShares.totalSupply();
        return true;
    }
}