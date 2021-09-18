# def_Token


Instance of Token module. 

> Tokens set to three decimals

## Contents
<!-- START doctoc -->
<!-- END doctoc -->




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



### mint
Mint new tokens and assign them to member address



#### Declaration
```solidity
  function mint(
    address member_,
    uint256 amount_
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`member_` | address | Address of member
|`amount_` | uint256 | Number of tokens to transfer

### decimals
Decimals used for displaying the contract


#### Declaration
```solidity
  function decimals(
  ) public returns (uint8)
```

#### Modifiers:
No modifiers





