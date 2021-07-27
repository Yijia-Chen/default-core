// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// This is a generic contract that manages ownership claims for assets on the DAO balance sheet
// (inside the Treasury Vaults). To start, there will only be two vaults: USDC and DNT.

import "../libraries/StateContract.sol";
import "./interfaces/IVaultShares.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract VaultShares is ERC20, STATE_VaultShares, StateContract { 

    uint8 private _decimals;
    address private _vaultContract; // the vault contract that corresponds to these shares
    address private _operatorContract; // the operator contract that distributes dnt vault shares to contributors

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _vaultContract = msg.sender;
        _operatorContract = address(0);
    } 

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
 
    function transfer(address recipient_, uint256 amount_) public override onlyApprovedApps returns (bool) {
        require(msg.sender == _operatorContract, "VaultShares transfer(): only the operator contract is able to transfer shares");
        return super.transfer(recipient_, amount_);
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public override onlyApprovedApps returns (bool) {
        require(msg.sender == _operatorContract, "VaultShares transferFrom(): only the operator contract is able to transfer shares");
        return super.transferFrom(sender_, recipient_, amount_);
    }

    // only mint to the vault
    function issueShares(address depositor_, uint256 amount_) external override onlyApprovedApps {
        require(msg.sender == _vaultContract, "VaultShares issueShares(): only vault contract can issue shares");
        _mint(depositor_, amount_);
    }

    function burnShares(address depositor_, uint256 amount_) external override onlyApprovedApps {
        require(msg.sender == _vaultContract, "VaultShares burnShares(): only vault contract can burn shares");
        _burn(depositor_, amount_);
    }

    // by only allowing approved applications to transfer shares, we prevent the creation of a secondary market for 
    // vault shares that gives vault depositors the ability to exit vaults without paying the withdraw fee.
    // To begin, only the operator should be able to transfer shares (during incrementEpoch()/bulkTransfer when distributing rewards);

    function setOperatorContract(address newOperatorContract_) external override onlyOwner() {
        _operatorContract = newOperatorContract_;
    }
}