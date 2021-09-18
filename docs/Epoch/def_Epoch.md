# def_Epoch


Instance of Epoch module. Epoch allows DAO to keep track of weekly intervals, and mints new ERC20 tokens at the end of each interval

> In the future, Epoch module may allow DAO to set their own internal lengths (months, biweekly, etc)

## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| current | uint16 |
| epochTime | uint256 |
| TOKEN_BONUS | uint256 |



## Functions

### constructor
Set address of ERC20 token module (DKN) of DAO in state

> Requires TKN module to be enabled on DAO

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


### setTokenBonus
Set amount of tokens that will be minted at the end of each epoch



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
|`newTokenBonus_` | uint256 | Amount of tokens to be minted each epoch

### incrementEpoch
Once 7 days have passed from the start of the last epoch, start a new epoch and mint new tokens


#### Declaration
```solidity
  function incrementEpoch(
  ) external
```

#### Modifiers:
No modifiers





## Events

### EpochIncremented
No description

  


