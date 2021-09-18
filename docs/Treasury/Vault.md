# Vault


Vault allows a member to deposit an ERC20 tokens with a DAO.The member receives shares in the vault in exchange, and these shares are themselves ERC20 tokens that can only be transferred by the DAO. Each vault holds a single token.


## Contents
<!-- START doctoc -->
<!-- END doctoc -->




## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) public ERC20
```

#### Modifiers:
| Modifier |
| --- |
| ERC20 |



### decimals
No description


#### Declaration
```solidity
  function decimals(
  ) public returns (uint8)
```

#### Modifiers:
No modifiers



### deposit
Deposit at the DAO and get shares in the vault

> Total amount of shares calculated as [Total assets deposited] * [[Total shares oustanding] / [Total assets in vault]]]


#### Declaration
```solidity
  function deposit(
    address member_,
    uint256 depositAmount_
  ) external onlyOwner returns (uint256)
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`member_` | address | Address of member to deposit shares on behalf of
|`depositAmount_` | uint256 | Total amount to deposit of a given asset to deposit in vault

### withdraw
Open the vault. Return assets to the user and burn their shares of the vault.

> Total amount of asset to withdrawl is [Total shares redeemed as a % of total # of shares] * [Amount of assets in vault]


#### Declaration
```solidity
  function withdraw(
    address member_,
    uint256 totalSharesRedeemed_
  ) external onlyOwner returns (uint256 tokensWithdrawn)
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`member_` | address | Address of member to deposit shares on behalf of
|`totalSharesRedeemed_` | uint256 | Total amount to shares to trade in for the originally deosited asset

### transfer
restrict share transfers to the OS to prevent secondary markets for vault shares, e.g. letting vault depositors exit without paying the withdraw fee, or borrowing against the shares in lending protocols


#### Declaration
```solidity
  function transfer(
  ) public onlyOwner returns (bool)
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |



### transferFrom
restrict share transfers to the OS to prevent secondary markets for vault shares, e.g. letting vault depositors exit without paying the withdraw fee, or borrowing against the shares in lending protocols


#### Declaration
```solidity
  function transferFrom(
  ) public onlyOwner returns (bool)
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |





