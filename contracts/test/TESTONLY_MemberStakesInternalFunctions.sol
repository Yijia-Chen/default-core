// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../os/Memberships/Stakes.sol";
import "hardhat/console.sol";

contract TESTONLY_StakesInternalFunctions is Stakes {

    function packStakeId(uint16 expiryEpoch, uint16 lockDuration) external pure returns (uint32 stakeId) {
        return _packStakeId(expiryEpoch, lockDuration);
    }

    function unpackStakeId(uint32 stakeId) external pure returns(uint16 expiryEpoch, uint16 lockDuration) {
        return _unpackStakeId(stakeId);
    }

    function pushStake(uint16 expiryEpoch, uint16 lockDuration, uint256 amount) external {
        _pushStake(expiryEpoch, lockDuration, amount);
    }

    function insertStakeBefore(uint32 insertedBeforeStakeId, uint16 expiryEpoch, uint16 lockDuration, uint256 amount) external {
        _insertStakeBefore(insertedBeforeStakeId, expiryEpoch, lockDuration, amount);
    }
}