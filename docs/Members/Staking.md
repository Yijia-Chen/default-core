# Staking


/ @title Staking contract
Add and remove token stakes.
co


## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| getStakesForMember | mapping(address => struct Staking.StakesList) |



## Functions

### _packStakeId
/ @notice Construct stake ID. Used as the comparison for the list sort



#### Declaration
```solidity
  function _packStakeId(
    uint16 expiryEpoch_,
    uint16 lockDuration_
  ) internal returns (uint32 stakeId)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`expiryEpoch_` | uint16 | Epoch when this batch of staked tokens expire
|`lockDuration_` | uint16 | # of epochs that token will be staked for

#### Returns:
| Type | Description |
| --- | --- |
|`stakeId` | Composite stake ID
### _unpackStakeId
/ @notice Deconstruct the composite ID of the stake to get the expiry epoch and lock duration



#### Declaration
```solidity
  function _unpackStakeId(
    uint32 stakeId_
  ) internal returns (uint16 lockDuration, uint16 expiryEpoch)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`stakeId_` | uint32 | Composite stake ID

#### Returns:
| Type | Description |
| --- | --- |
|`lockDuration` | # of epochs that token will be staked for
|`expiryEpoch` | Epoch when this batch of staked tokens expire
### _registerNewStake
/ @notice Register a new stake

> Does a sorted insert into the doubly linked list based on expiryEpoch


#### Declaration
```solidity
  function _registerNewStake(
    uint16 expiryEpoch_,
    uint16 lockDuration_,
    uint256 amount_
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`expiryEpoch_` | uint16 | Epoch when this batch of staked tokens expire
|`lockDuration_` | uint16 | # of epochs that token will be staked for
|`amount_` | uint256 | Number of tokens to stake

### _pushStake
/ @notice Push stake to end of list



#### Declaration
```solidity
  function _pushStake(
    uint16 expiryEpoch_,
    uint16 lockDuration_,
    uint256 amount_
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`expiryEpoch_` | uint16 | Epoch when this batch of staked tokens expire
|`lockDuration_` | uint16 | # of epochs that token will be staked for
|`amount_` | uint256 | Number of tokens to stake

### _insertStakeBefore
/ @notice Insert a new stake before given stake



#### Declaration
```solidity
  function _insertStakeBefore(
    uint32 insertedBeforeStakeId_,
    uint16 expiryEpoch_,
    uint16 lockDuration_,
    uint256 amount_
  ) internal
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`insertedBeforeStakeId_` | uint32 | Composite ID of stake that new stake will be inserted before
|`expiryEpoch_` | uint16 | Epoch when this batch of staked tokens expire
|`lockDuration_` | uint16 | # of epochs that token will be staked for
|`amount_` | uint256 | Number of tokens to stake

### _dequeueStake
/ @notice Dequeue the first stake in the queue



#### Declaration
```solidity
  function _dequeueStake(
  ) internal returns (uint16 lockDuration_, uint16 expiryEpoch_, uint256 amountStaked_)
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`lockDuration_` | # of epochs that token will be staked for
|`expiryEpoch_` | Epoch when this batch of staked tokens expire
|`amountStaked_` | Number of tokens that were staked


