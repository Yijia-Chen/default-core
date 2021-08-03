// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Permissioned.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DefaultToken is ERC20("Default Token", "DEF"), Permissioned {

    // only the operator should mint new tokens
    function mint(uint256 amount_) external onlyApprovedApps {      
        _mint(msg.sender, amount_);
    }
}