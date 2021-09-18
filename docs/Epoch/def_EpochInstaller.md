# def_EpochInstaller


Factory contract for the Epoch module


## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| moduleName | string |



## Functions

### install
Install Epoch module on a DAO. 

> Requires TKN modules to be enabled on DAO. install() is called by the DAO contract

#### Declaration
```solidity
  function install(
  ) external returns (address)
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`address` | Address of Epoch module instance



