# DefaultOSModuleInstaller


Interface for a module installer - the factory contract that creates a module instance for a DAO. Each module will be associated to a unique three letter [A-Z] keycode


## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| moduleKeycode | bytes3 |



## Functions

### constructor
No description


#### Declaration
```solidity
  function constructor(
  ) internal
```

#### Modifiers:
No modifiers



### install
Install an instance of a module for a given DAO

> install() is called by the DAO contract

#### Declaration
```solidity
  function install(
  ) external returns (address moduleAddress)
```

#### Modifiers:
No modifiers


#### Returns:
| Type | Description |
| --- | --- |
|`moduleAddress` | Address of module instance



