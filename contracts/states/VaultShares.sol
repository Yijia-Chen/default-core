// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/StateContract.sol";
import "./interfaces/VaultSharesV1.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// This is a generic contract that manages ownership claims for assets on the DAO balance sheet
// (inside the Treasury Vaults). To start, there will only be two vaults: USDC and DNT. 

contract VaultShares is STATE_VaultShares, StateContract { 
    mapping(address => uint256) public override balanceOf;
    uint256 public override totalSupply;
    string public override name;
    string public override symbol;
    uint8 public override decimals;

    address private _vaultContract; // the vault contract that corresponds to these shares
    address private _operatorContract; // the operator contract that distributes dnt vault shares to contributors
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        _vaultContract = msg.sender;
        _operatorContract = address(0);
    } 

    // **************************** PRIVATE METHODS ****************************

    function _approve(address owner_, address spender_, uint256 amount_) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }

    function _burn(address account_, uint256 amount_) internal {
        require(account_ != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = balanceOf[account_];
        require(accountBalance >= amount_, "ERC20: burn amount exceeds balance");
        unchecked {
            balanceOf[account_] = accountBalance - amount_;
        }
        totalSupply -= amount_;

        emit Transfer(account_, address(0), amount_);
    }

    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");

        totalSupply += amount_;
        balanceOf[account_] += amount_;
        emit Transfer(address(0), account_, amount_);
    }

    function _transfer(address sender_, address recipient_, uint256 amount_) internal {
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(recipient_ != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = balanceOf[sender_];
        require(senderBalance >= amount_, "ERC20: transfer amount_ exceeds balance");
        unchecked {
            balanceOf[sender_] = senderBalance - amount_;
        }
        balanceOf[recipient_] += amount_;

        emit Transfer(sender_, recipient_, amount_);
    }

    // **************************** PUBLIC METHODS ****************************

    function allowance(address owner_, address spender_) public view override returns (uint256) {
        return _allowances[owner_][spender_];
    }


    function approve(address spender_, uint256 amount_) public override returns (bool) {
        _approve(msg.sender, spender_, amount_);
        return true;
    }

    function increaseAllowance(address spender_, uint256 addedValue_) public returns (bool) {
        _approve(msg.sender, spender_, _allowances[msg.sender][spender_] + addedValue_);
        return true;
    }

    function decreaseAllowance(address spender_, uint256 subtractedValue_) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender_];
        require(currentAllowance >= subtractedValue_, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender_, currentAllowance - subtractedValue_);
        }

        return true;
    }

    function transfer(address recipient_, uint256 amount_) public override returns (bool) {
        require(msg.sender == _operatorContract, "VaultShares transfer(): only the operator contract is be able to transfer shares");
        _transfer(msg.sender, recipient_, amount_);
        return true;
    }

    function transferFrom(address sender_, address recipient_, uint256 amount_) public override onlyApprovedApps returns (bool) {
        require(msg.sender == _operatorContract, "VaultShares transferFrom(): only the operator contract is able to transfer shares");
        _transfer(sender_, recipient_, amount_);

        uint256 currentAllowance = _allowances[sender_][msg.sender];
        require(currentAllowance >= amount_, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender_, msg.sender, currentAllowance - amount_);
        }

        return true;
    }

    // only mint to the vault
    function issueShares(address depositor_, uint256 amount_) external override onlyApprovedApps {
        require(msg.sender == _vaultContract, "VaultShares issueshares(): only vault contract can issue shares");
        _mint(depositor_, amount_);
    }

    function burnShares(uint256 amount_) external override onlyApprovedApps {
        _burn(msg.sender, amount_);
    }

    // by only allowing approved applications to transfer shares, we prevent the creation of a secondary market for 
    // vault shares that gives vault depositors the ability to exit vaults without paying the withdraw fee.
    // To begin, only the operator should be able to transfer shares (during incrementEpoch()/bulkTransfer when distributing rewards);

    function setOperatorContract(address newOperatorContract_) external override onlyOwner() {
        _operatorContract = newOperatorContract_;
    }
}