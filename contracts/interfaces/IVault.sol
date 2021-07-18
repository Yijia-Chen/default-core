// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault is IERC20 {
    function withdraw(uint256 amount) external returns (bool);
    function deposit(uint256 amount) external returns (bool);
    function borrow(uint256 amount) external returns (bool);
    function repay(uint256 amount) external returns(bool);
    function setFee(uint8 percentage) external returns(bool);

    event Withdrawn(address indexed member, uint256 amount);
    event Deposited(address indexed member, uint256 amount);
    event FeeChanged(uint8 percentage);
}