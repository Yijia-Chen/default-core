# def_Mining


Allows members of DAO to mine the DEF token. Rewards have a set value that can be changed by the DAO. Rewards are distributed equally to all each held in the vault.


## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| unclaimableRewards | mapping(address => uint256) |
| registered | mapping(address => bool) |
| accRewardsPerShare | uint256 |
| lastEpochIssued | uint256 |
| EPOCH_MINING_REWARDS | uint256 |
| TOKEN_BONUS | uint256 |



## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) public DefaultOSModule
```

#### Modifiers:
| Modifier |
| --- |
| DefaultOSModule |



### setTokenBonus
Set weekly token bonus to caller of issueRewards() function.



#### Declaration
```solidity
  function setTokenBonus(
    uint256 newTokenBonus_
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`newTokenBonus_` | uint256 | # of tokens to be paid to caller of issueRewards function

### pendingRewards
Calculate the available rewards for the caller. 

> Available rewards are calculated as the [[sender's total balance in the vault] X [multipler on the reward per share]] - [unclaimable rewards for the sender]
Rewards are denominated in the token's units / [1e12]

#### Declaration
```solidity
  function pendingRewards(
  ) public returns (uint256)
```

#### Modifiers:
No modifiers



### assignVault
Assign the vault contract to be mined. This "activates" the mining program

> The token should have a vault in the treasury before calling this function

#### Declaration
```solidity
  function assignVault(
    address token_
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`token_` | address | the Address of the token to be mined


### issueRewards
Sets the amount of rewards a miner can receive per token deposited in the vault. Rewards are distributed evenly to all tokens in the vault.


#### Declaration
```solidity
  function issueRewards(
  ) external
```

#### Modifiers:
No modifiers



### register
Reset the mining rewards for member to 0.

> This function sets unclaimable rewards to the total balance of rewards for the member. This effectively sets rewards to zero since redeemable rewards = total possible rewards - uncaimable rewards

#### Declaration
```solidity
  function register(
  ) external
```

#### Modifiers:
No modifiers



### claimRewards
Redeem all available rewards


#### Declaration
```solidity
  function claimRewards(
  ) external
```

#### Modifiers:
No modifiers





## Events

### RewardsIssued
No description

  


### RewardsClaimed
No description

  


### MemberRegistered
No description

  


