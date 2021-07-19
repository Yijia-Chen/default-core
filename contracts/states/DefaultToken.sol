// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DefaultToken is ERC20("Default Token", "DNT"), Ownable {
    
    // primary state: 
    // 

    function mint(uint256 _amount) external onlyOwner returns (bool) {      
        // only mint to the DAO wallet
        _mint(owner(), _amount);
        return true;
    }
}