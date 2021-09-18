# def_Members


Instance of Member module. This module allows members to create aliases and create/use endorsements

> Requires EPC and TKN modules to be enabled on DAO

## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| getMemberForAlias | mapping(bytes32 => address) |
| getAliasForMember | mapping(address => bytes32) |
| totalEndorsementsAvailableToGive | mapping(address => uint256) |
| totalEndorsementsGiven | mapping(address => uint256) |
| totalEndorsementsReceived | mapping(address => uint256) |
| endorsementsGiven | mapping(address => mapping(address => uint256)) |
| endorsementsReceived | mapping(address => mapping(address => uint256)) |
| ENDORSEMENT_LIMIT | uint256 |



## Functions

### constructor
Set TKN and EPC module addresses to state



#### Declaration
```solidity
  function constructor(
    contract DefaultOS os_
  ) public DefaultOSModule
```

#### Modifiers:
| Modifier |
| --- |
| DefaultOSModule |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`os_` | contract DefaultOS | Instance of DAO OS

### setEndorsementLimit
Set global limit on endorsements a member can receive from another member



#### Declaration
```solidity
  function setEndorsementLimit(
    uint256 newLimit_
  ) external onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`newLimit_` | uint256 | Max amount of endorsements a member can receive from another member

### setAlias
Set alias for address



#### Declaration
```solidity
  function setAlias(
    bytes32 alias_
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`alias_` | bytes32 | Human readable alias for member

### mintEndorsements
Create endorsements by staking tokens. Total endorsements = tokensStaked x [multipler based on the # lockDuration]



#### Declaration
```solidity
  function mintEndorsements(
    uint16 lockDuration_,
    uint256 tokensStaked_
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`lockDuration_` | uint16 | # of epochs that token will be staked for
|`tokensStaked_` | uint256 | @ of tokens to stake

### reclaimTokens
Reclaim staked tokens by trading in endorsements. Confirms that tokens have expired and member will have enough remaining endorsements after reclaiming tokens


#### Declaration
```solidity
  function reclaimTokens(
  ) external
```

#### Modifiers:
No modifiers



### endorseMember
Give endorsements to another member



#### Declaration
```solidity
  function endorseMember(
    address targetMember_,
    uint256 endorsementsGiven_
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`targetMember_` | address | Address of member who will receive endorsements
|`endorsementsGiven_` | uint256 | # of endorsements to give

### withdrawEndorsementFrom
Withdrawl endorsements given to another member



#### Declaration
```solidity
  function withdrawEndorsementFrom(
    address targetMember_,
    uint256 endorsementsWithdrawn_
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`targetMember_` | address | Address of member to withdrawl endorsements from
|`endorsementsWithdrawn_` | uint256 | # of endorsements to withdrawl



## Events

### MemberRegistered
No description

  


### TokensStaked
No description

  


### TokensUnstaked
No description

  


### EndorsementGiven
No description

  


### EndorsementWithdrawn
No description

  


