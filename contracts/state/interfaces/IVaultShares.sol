// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IVaultShares {
    // state changes (writes)
    function issueShares(address depositor_, uint256 amount_) external;
    function burnShares(address depositor_, uint256 amount_) external;
}