// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../os/Members/_Staking.sol";
import "hardhat/console.sol";

contract MOCK_Staking is Staking {
    // used to get the stake object from the mapping
    function getStakeForId(uint32 stakeId_) external view returns(Stake memory stake) {
        // shift expiry epoch 16 bits to the left and append the 16bit lock duration at the end to create a composite ID
        return getStakesForMember[msg.sender].getStakeForId[stakeId_];
    }

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

    function registerNewStake(uint16 expiryEpoch_, uint16 lockDuration_, uint256 amount_) external {
        _registerNewStake(expiryEpoch_, lockDuration_, amount_);
    }

    function dequeueStake() external returns (uint16 lockDuration_, uint16 expiryEpoch_, uint256 amountStaked_) {
        return _dequeueStake();
    }
}