# BaseDEALV0
[Git Source](https://github.com/z0r0z/BaseSAFE/blob/49e83097a550e99e166bacce818c6debef62f7e0/src/DEAL/BaseDEALV0.sol)

**Inherits:**
ERC1155


## State Variables
### deals

```solidity
mapping(uint256 dealHashId => DEAL) public deals;
```


### name

```solidity
string public constant name = "Base Deal V0";
```


### symbol

```solidity
string public constant symbol = "BDEAL";
```


### _ids

```solidity
mapping(address party => uint256[]) _ids;
```


### _sections

```solidity
ISections immutable _sections;
```


### validTos

```solidity
mapping(uint256 dealHashId => mapping(address party => address to)) public validTos;
```


## Functions
### constructor


```solidity
constructor(ISections sections) payable;
```

### uri


```solidity
function uri(uint256 dealHashId) public view override(ERC1155) returns (string memory);
```

### draft


```solidity
function draft(DEAL memory deal) public view returns (string memory);
```

### getHashId


```solidity
function getHashId(DEAL memory deal) public pure returns (uint256);
```

### getHashIds


```solidity
function getHashIds(address party) public view returns (uint256[] memory);
```

### checkSignature


```solidity
function checkSignature(address party, uint256 dealHashId, bytes calldata signature)
    public
    view
    returns (bool);
```

### send


```solidity
function send(
    string calldata clientName,
    string calldata resolverName,
    string calldata dealAmount,
    string calldata dealNotes,
    Date calldata expiryDate
) public payable checkVal returns (uint256 dealHashId);
```

### _extractName


```solidity
function _extractName(bytes memory fullName) internal pure returns (string memory);
```

### sign


```solidity
function sign(uint256 dealHashId) public payable checkVal;
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
function _createURI(DEAL memory deal) internal view returns (string memory);
```

### _render


```solidity
function _render(DEAL memory deal) internal view returns (string memory);
```

### _generateLegalText


```solidity
function _generateLegalText(DEAL memory deal) internal view returns (string memory);
```

### approveTransfer


```solidity
function approveTransfer(uint256 dealHashId, address to) public payable checkVal;
```

### safeTransferFrom


```solidity
function safeTransferFrom(
    address from,
    address to,
    uint256 dealHashId,
    uint256 amount,
    bytes calldata data
) public override(ERC1155);
```

### safeBatchTransferFrom


```solidity
function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata dealHashIds,
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

## Structs
### Date

```solidity
struct Date {
    uint256 month;
    uint256 day;
    uint256 year;
}
```

