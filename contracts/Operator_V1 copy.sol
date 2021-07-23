// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Ownable {

    IEpoch public epoch;
    IMemberships public memberships;
    IERC20 public defaultToken;
    IVaultV1 public dntVault;
    IVaultV1 public usdcVault;
    IRewarder public depositRewarder;
    IPurse public contributorPurse;

    address public daoWallet;
    uint256 public issuance = 1000000;

    constructor() {
        defaultToken = IERC20(defaultToken_);
        dntVault = IVaultV1(usdcVault_);
        
        
        new TreasuryVault("DNT Vault Share", "DNT-VS", defaultToken, 80);
        usdcVault = new TreasuryVault("USDC Vault Share", "USDC-VS", USDC_CONTRACT_ADDRESS, 10);
        rewarder = new VaultRewarder();
    }

    function incrementEpoch() external onlyOwner returns (bool) {
        epoch++;
        defaultToken.mint(issuance);
        dntVault.deposit(issuance);
        dntVault.transferShares(depositRewarder, issuance/2);
        dntVault.transferShares(contributorPurse, issuance/2);
        return true;
    }

}
