// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/StateContract.sol";
import "./interfaces/VaultSharesV1.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This is a generic contract that manages ownership claims for assets on the DAO balance sheet
// (inside the Treasury Vaults). To start, there will only be two vaults: USDC and DNT. 

contract VaultShares is ERC20, STATE_VaultShares, StateContract { 

    // the primary state (inherited from the ERC20 contract) looks like this: mapping(address => uint256) _balances;
    uint8 private _decimals; // OZ's current ERC20 doesn't allow setting decimals except through function override....
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

    // only mint to the vault
    function issueShares(address depositor_, uint256 amount_) external override onlyApprovedApps {
        require(msg.sender == _vaultContract, "VaultShares issueshares(): only vault contract can issue shares");
        _mint(depositor_, amount_);
    }

    // by only allowing approved applications to transfer shares, we prevent the creation of a secondary market for 
    // vault shares that gives vault depositors the ability to exit vaults without paying the withdraw fee.
    // To begin, only the operator should be able to transfer shares (during incrementEpoch()/bulkTransfer when distributing rewards);

    function transfer(address recipient_, uint256 amount_) public override returns (bool) {

        // this breaks the inherited function, should never return
        require(false, "VaultShares transfer(): only the operator contract is be able to transfer shares");
        return false;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public override returns (bool) {
        require(msg.sender == _operatorContract, "VaultShares transferFrom(): only the operator contract is able to transfer shares");
        return super.transferFrom(sender_, recipient_, amount_);
    }

    function setOperatorContract(address newOperatorContract_) external onlyOwner() {
        _operatorContract = newOperatorContract_;
    }
}