# def_Treasury



> A treasury is a collection of vaults and each vault can store a single token. Members can deposit and withdraw from vaults, and the treasury takes a % fee from each withdraw

## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| getVault | mapping(address => contract Vault) |
| vaultFee | mapping(address => uint8) |



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



### openVault
Open a new vault of a specific token for the treasury. (Governance only)



#### Declaration
```solidity
  function openVault(
    address token_,
    uint8 fee_
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`token_` | address | Address of token to create a vault for
|`fee_` | uint8 | Percentage fee (0-100) that members will pay to the DAO from each withdrawl

### withdrawFromVault
Withdraw DAO's earned fees from the vault. (Governance only)



#### Declaration
```solidity
  function withdrawFromVault(
    contract Vault vault_,
    uint256 amountshares_
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`vault_` | contract Vault | Address of vault
|`amountshares_` | uint256 | # of shares to withdrawl in exchange fo

### changeFee
Withdraw earned fees from the vault. No fee will be charged on this withdrawl. (Governance only)



#### Declaration
```solidity
  function changeFee(
    contract Vault vault_,
    uint8 newFeePctg
  ) external onlyOS
```

#### Modifiers:
| Modifier |
| --- |
| onlyOS |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`vault_` | contract Vault | Address of vault
|`newFeePctg` | uint8 | New percentage fee (0-100) that members will pay to the DAO from each withdrawl

### deposit
Deposit tokens into vault



#### Declaration
```solidity
  function deposit(
    contract Vault vault_,
    uint256 amountTokens_
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`vault_` | contract Vault | Address of vault
|`amountTokens_` | uint256 | Number of tokens to withdrawl

### withdraw
User can exchange their shares in vault for the original ERC-20 token



#### Declaration
```solidity
  function withdraw(
    contract Vault vault_,
    uint256 amountShares_
  ) external
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`vault_` | contract Vault | Address of vault
|`amountShares_` | uint256 | Amount of shares to trade in for tokens



## Events

### VaultOpened
No description

  


### VaultFeeChanged
No description

  


### Deposited
No description

  


### Withdrawn
No description

  


