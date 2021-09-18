# DefaultOSFactory


Keep track of global state of full list of DAOs and the addresses these DAOs map to


## Contents
<!-- START doctoc -->
<!-- END doctoc -->

## Globals

> Note this contains internal vars as well due to a bug in the docgen procedure

| Var | Type |
| --- | --- |
| osMap | mapping(bytes32 => address) |



## Functions

### setOS
Add a new DAO to full list of DAOs using DefaultOS. 



#### Declaration
```solidity
  function setOS(
    bytes32 name_
  ) public
```

#### Modifiers:
No modifiers

#### Args:
| Arg | Type | Description |
| --- | --- | --- |
|`name_` | bytes32 | name of DAO



## Events

### OSCreated
No description

  


