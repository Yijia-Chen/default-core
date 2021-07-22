// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IVault.sol";

// our wonderful DAO
contract DaoEntity is Ownable {

    // what the DAO truly owns: everything in here is for keeps.
    address public daoWallet;

    // the internal clock of the DAO.
    IEpoch public epoch;

    // the membership registry
    IMemberRegistry public memberships;

    // our native DAO token...these will be worth a lot one day!
    IERC20 public defaultToken;

    // our native token vault. Provides liquidity in our virtual AMM and its shares are distributed to members as rewards.
    IVaultV1 public dntVault;

    // our usdc vault. Provides liquidity in our virtual AMM, and pays for our expenses.
    IVaultV1 public usdcVault;

    // our rewarder contract, responsible for the prompt delivery of our token to our supporters and contributors!
    IDepositRewarder public depositRewarder;

    // the contributor purse, which holds all the contributor tokens (separate multisig)
    IContributorPurse public contributorPurse;

    // number of new tokens minted each epoch
    uint256 public issuance = 1000000;

    // ok...here we go!
    constructor() {
        // step 1. create a registry for the members
        memberships = new MembershipRegistry();

        // step 1. make the default token
        defaultToken = new DefaultToken();

        // step 2. create a vault for our tokens
        dntVault = new TreasuryVault("DNT Vault Share", "DNT-VS", defaultToken, 80);

        // step 3. create a vault for our usdc
        usdcVault = new TreasuryVault("USDC Vault Share", "USDC-VS", USDC_CONTRACT_ADDRESS, 10);

        // rewarder!!!
        rewarder = new VaultRewarder();
    }

    function incrementEpoch() external onlyOwner returns (bool) {
        
        // literally increment the epoch
        epoch++;

        // mint the new tokens for the epoch to the DAO
        defaultToken.mint(issuance);

        // deposit tokens into the vault for shares
        dntVault.deposit(issuance);

        // distribute reward shares to depositors
        dntVault.transferShares(depositRewarder, issuance/2);

        // distribute reward shares to contributors
        dntVault.transferShares(contributorPurse, issuance/2);

        return true;
    }

}
