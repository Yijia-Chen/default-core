# DefaultOS


Instance of a Default OS


## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| organizationName | bytes32 |
| MODULES | mapping(bytes3 => address) |



## Functions

### constructor
Set organization name and add DAO org ID to DAO tracker



#### Declaration
```solidity
  function constructor(
    bytes32 organizationName_
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`organizationName_` | bytes32 | Name of org

### installModule
Allow DAO to add module to itself



#### Declaration
```solidity
  function installModule(
    contract DefaultOSModuleInstaller installer_
  ) external onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`installer_` | contract DefaultOSModuleInstaller | Address of module's contract factory

### getModule
Get address of DAO's module instance



#### Declaration
```solidity
  function getModule(
    bytes3 moduleKeycode_
  ) external returns (address)
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`moduleKeycode_` | bytes3 | Three letter [A-Z] keycode  of module

#### Returns:
| Type | Description |
| --- | --- |
|`address` | Address of Module instance
### transfer
Transfer ERC20 tokens from DAO to recipient 



#### Declaration
```solidity
  function transfer(
    contract IERC20 token_,
    address recipient_,
    uint256 amount_
  ) external onlyOwner
```

#### Modifiers:
| Modifier |
| --- |
| onlyOwner |

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`token_` | contract IERC20 | ERC20 token contract
|`recipient_` | address | Address of recipient
|`amount_` | uint256 | Amount of tokens to transfer



## Events

### ModuleInstalled
No description

  


