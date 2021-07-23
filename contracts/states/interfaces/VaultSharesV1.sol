// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface STATE_VaultShares {
    // state changes (writes)
    function issueShares(address depositor_, uint256 amount_) external;
}