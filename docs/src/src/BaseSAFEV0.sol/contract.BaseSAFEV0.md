# BaseSAFEV0
[Git Source](https://github.com/z0r0z/BaseSAFE/blob/02336b9dfbabe0fc92033ce69b4a16a2e55e44f8/src/BaseSAFEV0.sol)

**Inherits:**
ERC1155


## State Variables
### _section2

```solidity
ISections immutable _section2;
```


### _section3

```solidity
ISections immutable _section3;
```


### _section4

```solidity
ISections immutable _section4;
```


### _section5

```solidity
ISections immutable _section5;
```


### safes

```solidity
mapping(uint256 safeHashId => SAFE) public safes;
```


### name

```solidity
string public constant name = "Base Safe V0";
```


### symbol

```solidity
string public constant symbol = "BSAFE";
```


### _ids

```solidity
mapping(address party => uint256[]) _ids;
```


### validTos

```solidity
mapping(uint256 safeHashId => mapping(address party => address to)) public validTos;
```


## Functions
### constructor


```solidity
constructor(ISections section2, ISections section3, ISections section4, ISections section5)
    payable;
```

### uri


```solidity
function uri(uint256 safeHashId) public view override(ERC1155) returns (string memory);
```

### draft


```solidity
function draft(SAFE memory safe) public view returns (string memory);
```

### getHashId


```solidity
function getHashId(SAFE memory safe) public pure returns (uint256);
```

### getHashIds


```solidity
function getHashIds(address party) public view returns (uint256[] memory);
```

### checkSignature


```solidity
function checkSignature(address party, uint256 safeHashId, bytes calldata signature)
    public
    view
    returns (bool);
```

### send


```solidity
function send(
    string calldata investorName,
    string calldata purchaseAmount,
    string calldata postMoneyValuationCap
) public payable checkVal returns (uint256 safeHashId);
```

### _extractName


```solidity
function _extractName(bytes memory fullName) internal pure returns (string memory);
```

### sign


```solidity
function sign(uint256 safeHashId) public payable checkVal;
```

### _toUint


```solidity
function _toUint(bytes memory s) internal pure returns (uint256 result);
```

### _toAddress


```solidity
function _toAddress(bytes memory s) internal pure returns (address addr);
```

### _createURI


```solidity
function _createURI(SAFE memory safe) internal view returns (string memory);
```

### _render


```solidity
function _render(SAFE memory safe) internal view returns (string memory);
```

### _generateLegalText


```solidity
function _generateLegalText(SAFE memory safe) internal view returns (string memory);
```

### _section1


```solidity
function _section1(SAFE memory safe) internal pure returns (string memory);
```

### approveTransfer


```solidity
function approveTransfer(uint256 safeHashId, address to) public payable checkVal;
```

### safeTransferFrom


```solidity
function safeTransferFrom(
    address from,
    address to,
    uint256 safeHashId,
    uint256 amount,
    bytes calldata data
) public override(ERC1155);
```

### safeBatchTransferFrom


```solidity
function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata safeHashIds,
    uint256[] calldata amounts,
    bytes calldata data
) public override(ERC1155);
```

### burn


```solidity
function burn(address from, uint256 id, uint256 amount) public payable checkVal;
```

### checkVal


```solidity
modifier checkVal();
```

### sweep


```solidity
function sweep() public payable;
```

### fund


```solidity
function fund(string calldata to, string calldata amount, bytes32 log) public payable checkVal;
```

### fundFromETH


```solidity
function fundFromETH(string calldata to, string calldata amount, bytes32 log) public payable;
```

## Events
### Log

```solidity
event Log(address indexed caller, bytes32 indexed log);
```

## Errors
### Registered

```solidity
error Registered();
```

### InvalidSyntax

```solidity
error InvalidSyntax();
```

### Unregistered

```solidity
error Unregistered();
```

### Unauthorized

```solidity
error Unauthorized();
```

### InvalidDecimalPlaces

```solidity
error InvalidDecimalPlaces();
```

### InvalidCharacter

```solidity
error InvalidCharacter();
```

### NumberTooLarge

```solidity
error NumberTooLarge();
```

### Overflow

```solidity
error Overflow();
```

