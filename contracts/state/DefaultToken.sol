// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../libraries/Permissioned.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DefaultToken is ERC20("Default Token", "DNT"), Permissioned {

    address private _operator = address(0); // the address of the operator contract

    // only the operator should mint new tokens
    function mint(uint256 amount_) external onlyApprovedApps {      
        require (msg.sender == _operator && isApproved[_operator],
                "DefaultToken mint(): only an approved _operator contract can mint new Default Tokens");
        _mint(_operator, amount_);
    }

    function changeOperator(address newOperator_) external onlyOwner {
        _operator = newOperator_;
    }
}