// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/StateContract.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DefaultToken is ERC20("Default Token", "DNT"), StateContract {

    function mint(uint256 _amount) external onlyApprovedApps {      
        // only mint to the DAO wallet
        _mint(owner(), _amount);
    }
}