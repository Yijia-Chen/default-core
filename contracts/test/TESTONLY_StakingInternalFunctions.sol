// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../os/OS.sol";
import "../os/Directory/Staking.sol";

contract TESTONLY_StakingInternalFunctions is Staking {
    constructor(OS os_) Staking(os_) {}

    function pushStake(uint16 expiryEpoch, uint256 amount) external {
        _pushStake(expiryEpoch, amount);
    }

    function dequeueStake() external {
        _dequeueStake();
    }

    function insertStakeBefore(uint16 existingStakeExpiry, uint16 newExpiryEpoch, uint256 amount) external {
        _insertStakeBefore(existingStakeExpiry, newExpiryEpoch, amount);
    }
}