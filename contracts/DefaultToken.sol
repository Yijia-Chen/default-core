// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DefaultToken is ERC20("Default Token", "DNT"), Ownable {
    
    function mint(uint256 _amount) external onlyOwner returns (bool) {
        
        // only mint to the DAO address
        _mint(msg.sender, _amount);
        return true;
    }
}