# def_PeerRewards


Instance of Peer Rewards module. This module creates a weekly vote on who should receive allocations. Members cannot vote for themselves and the number of votes each member can give is determined via a combination of the number of endorsements they have and how many consecutive weeks they've been partipating in allocations. A member must manually register to be part of that epoch's allocation round. Relative allocation votes from each member are carried over epoch-to-epoch but can also be manually changed. Members can exchange their accrued allocations for tokens at any time.

> Requires TKN, MBR, EPC modules to be enabled on DAO

## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| participationStreak | mapping(address => uint16) |
| pointsRegisteredForEpoch | mapping(uint16 => mapping(address => uint256)) |
| totalPointsRegisteredForEpoch | mapping(uint16 => uint256) |
| participationHistory | mapping(uint16 => mapping(address => bool)) |
| getAllocationsListFor | mapping(address => struct def_PeerRewards.AllocationsList) |
| eligibleForRewards | mapping(uint16 => mapping(address => bool)) |
| mintableRewards | mapping(uint16 => mapping(address => uint256)) |
| lastEpochClaimed | mapping(address => uint16) |
| PARTICIPATION_THRESHOLD | uint256 |
| REWARDS_THRESHOLD | uint256 |
| CONTRIBUTOR_EPOCH_REWARDS | uint256 |
| MIN_ALLOC_PCTG | uint8 |
| MAX_ALLOC_PCTG | uint8 |



## Functions

### constructor
Set address of TKN, MBR, EPC modules to state


#### Declaration
```solidity
  function constructor(
  ) public DefaultOSModule
```

#### Modifiers:
| Modifier |
| --- |
| DefaultOSModule |



### setParticipationThreshold
No description


#### Declaration
```solidity
  function setParticipationThreshold(
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |



### setRewardsThreshold
No description


#### Declaration
```solidity
  function setRewardsThreshold(
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |



### setContributorEpochRewards
No description


#### Declaration
```solidity
  function setContributorEpochRewards(
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |



### setMinAllocPctg
No description


#### Declaration
```solidity
  function setMinAllocPctg(
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |



### setMaxAllocPctg
No description


#### Declaration
```solidity
  function setMaxAllocPctg(
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |



### register
Member can register points for their pariticipation in the next epoch. The amount of points given to a member depends on how many epochs the member has consecutively participated and their total endorsements

> Total rewards A memberA can give memberB in a given epoch is calculated as [Total epoch rewards] x [[Points registered by memberA in epoch] / [Total points registered in epoch]] X [[Allocation given to memberB by memberA in current epoch] / [Total allocations given by memberB in current epoch]]

#### Declaration
```solidity
  function register(
  ) external
```

#### Modifiers:
No modifiers



### configureAllocation
Change allocation one member is giving to another member for the current epoch



#### Declaration
```solidity
  function configureAllocation(
    address toMember_,
    uint8 newAllocPts_
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`toMember_` | address | Address of member that is receiving allocation
|`newAllocPts_` | uint8 | New allocation that will be set for the current epoch

### commitAllocation
Commit senders allocations and convert them to mintable tokens that recipients can convert to tokens


#### Declaration
```solidity
  function commitAllocation(
  ) external
```

#### Modifiers:
No modifiers



### claimRewards
Convert all member's unclaimed mintable tokens into actual tokens


#### Declaration
```solidity
  function claimRewards(
  ) external
```

#### Modifiers:
No modifiers





## Events

### MemberRegistered
No description

  


### AllocationSet
No description

  


### AllocationGiven
No description

  


### RewardsClaimed
No description

  


