# def_MembersInstaller


Factory contract for the Member Module


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
Install Member module on a DAO 

> Requires EPC and TKN modules to be enabled on DAO. install() is called by the DAO contract

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
|`address` | Address of Member module instance



