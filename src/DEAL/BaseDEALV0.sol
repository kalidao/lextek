// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Base64} from "@solady/src/utils/Base64.sol";
import {ERC1155} from "@solady/src/tokens/ERC1155.sol";
import {LibString} from "@solady/src/utils/LibString.sol";
import {DateTimeLib} from "@solady/src/utils/DateTimeLib.sol";
import {SafeTransferLib} from "@solady/src/utils/SafeTransferLib.sol";
import {SignatureCheckerLib} from "@solady/src/utils/SignatureCheckerLib.sol";

struct DEAL {
    string clientName;
    string providerName;
    string resolverName;
    string dealAmount; /*USDC*/
    string dealNotes;
    string dealDate;
    string expiryDate;
    uint256 expiryTimestamp;
    address providerSignature;
    address clientSignature;
}

interface ISections {
    function sections(DEAL calldata deal) external view returns (string memory);
}

interface IEscrows {
    function escrow(address, address, address, address, uint256, string calldata, uint256)
        external
        payable
        returns (bytes32);
}

interface IIE {
    function command(string calldata) external payable;
    function whatIsTheNameOf(address) external view returns (string memory);
    function whatIsTheAddressOf(string memory) external view returns (address, address, bytes32);
}

IIE constant IE = IIE(0x1eB800E42c879193A1D3d940000000c300e80041);
address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
address constant WETH = 0x4200000000000000000000000000000000000006;
IEscrows constant ESCROWS = IEscrows(0x00000000000044992CB97CB1A57A32e271C04c11);

contract BaseDEALV0 is ERC1155 {
    mapping(uint256 dealHashId => DEAL) public deals;
    string public constant name = "Base Deal V0";
    string public constant symbol = "BDEAL";
    mapping(address party => uint256[]) _ids;

    ISections immutable _sections;

    constructor(ISections sections) payable {
        _sections = sections;
        SafeTransferLib.safeApprove(USDC, address(IE), type(uint256).max);
        SafeTransferLib.safeApprove(WETH, address(IE), type(uint256).max);
        SafeTransferLib.safeApprove(USDC, address(ESCROWS), type(uint256).max);
    }

    function uri(uint256 dealHashId) public view override(ERC1155) returns (string memory) {
        return _createURI(deals[dealHashId]);
    }

    function draft(DEAL memory deal) public view returns (string memory) {
        if (deal.clientSignature != address(0)) delete deal.clientSignature;
        return _createURI(deal);
    }

    function getHashId(DEAL memory deal) public pure returns (uint256) {
        if (deal.clientSignature != address(0)) delete deal.clientSignature;
        return uint256(keccak256(abi.encode(deal)));
    }

    function getHashIds(address party) public view returns (uint256[] memory) {
        return _ids[party];
    }

    function checkSignature(address party, uint256 dealHashId, bytes calldata signature)
        public
        view
        returns (bool)
    {
        return SignatureCheckerLib.isValidSignatureNowCalldata(
            party, SignatureCheckerLib.toEthSignedMessageHash(bytes32(dealHashId)), signature
        );
    }

    error Registered();

    struct Date {
        uint256 month;
        uint256 day;
        uint256 year;
    }

    function send(
        string calldata clientName,
        string calldata resolverName,
        string calldata dealAmount,
        string calldata dealNotes,
        Date calldata expiryDate
    ) public payable checkVal returns (uint256 dealHashId) {
        _toUint(bytes(dealAmount)); // Validate input.
        DEAL memory deal;

        string memory baseName = IE.whatIsTheNameOf(msg.sender);
        if (bytes(baseName).length != 0) deal.providerName = baseName;
        else deal.providerName = LibString.toHexStringChecksummed(msg.sender);

        deal.clientName = clientName;
        deal.resolverName = resolverName;
        deal.dealAmount = dealAmount;
        deal.dealNotes = dealNotes;

        (uint256 year, uint256 month, uint256 day) = DateTimeLib.timestampToDate(block.timestamp);

        string memory _month = LibString.toString(month);
        string memory _day = LibString.toString(day);
        string memory _year = LibString.toString(year);

        deal.dealDate = string(abi.encodePacked(_month, "/", _day, "/", _year));

        _month = LibString.toString(expiryDate.month);
        _day = LibString.toString(expiryDate.day);
        _year = LibString.toString(expiryDate.year);

        deal.expiryDate = string(abi.encodePacked(_month, "/", _day, "/", _year));

        deal.expiryTimestamp =
            DateTimeLib.dateToTimestamp(expiryDate.year, expiryDate.month, expiryDate.day);

        deal.providerSignature = msg.sender;

        dealHashId = uint256(keccak256(abi.encode(deal)));

        if (bytes(deals[dealHashId].providerName).length != 0) revert Registered();

        deals[dealHashId] = DEAL({
            providerName: deal.providerName,
            clientName: deal.clientName,
            resolverName: deal.resolverName,
            dealAmount: deal.dealAmount,
            dealNotes: deal.dealNotes,
            dealDate: deal.dealDate,
            expiryDate: deal.expiryDate,
            expiryTimestamp: deal.expiryTimestamp,
            providerSignature: deal.providerSignature,
            clientSignature: address(0)
        });

        bool ens = bytes(deal.clientName).length != 42;

        string memory shortName;
        if (ens) shortName = _extractName(bytes(deal.clientName));
        (, address clientAddress,) = IE.whatIsTheAddressOf(ens ? shortName : deal.clientName);
        _mint(clientAddress, dealHashId, 1, "");
        _ids[clientAddress].push(dealHashId);
        _ids[msg.sender].push(dealHashId);

        ens = bytes(deal.resolverName).length != 42;
        if (ens) shortName = _extractName(bytes(deal.resolverName));
        (, address resolverAddress,) = IE.whatIsTheAddressOf(ens ? shortName : deal.resolverName);
        _ids[resolverAddress].push(dealHashId);
    }

    error InvalidSyntax();

    function _extractName(bytes memory fullName) internal pure returns (string memory) {
        uint256 length = fullName.length;
        if (length <= 9) revert InvalidSyntax();
        unchecked {
            uint256 newLength = length - 9;
            bytes memory result = new bytes(newLength);

            for (uint256 i; i != newLength; ++i) {
                result[i] = fullName[i];
            }

            return string(result);
        }
    }

    error Unregistered();
    error Unauthorized();

    mapping(uint256 dealHashId => bytes32) public escrowHashes;

    function sign(uint256 dealHashId) public payable returns (bytes32 escrowHash) {
        DEAL storage deal = deals[dealHashId];

        if (deal.providerSignature == address(0)) revert Unregistered();
        if (deal.clientSignature != address(0)) revert Registered();

        if (bytes(deal.clientName).length == 42) {
            if (msg.sender != _toAddress(bytes(deal.clientName))) revert Unauthorized();
        } else {
            (, address clientAddress,) = IE.whatIsTheAddressOf(_extractName(bytes(deal.clientName)));
            if (msg.sender != clientAddress) {
                revert Unauthorized();
            }
        }

        deal.clientSignature = msg.sender;

        bool ens = bytes(deal.providerName).length != 42;
        string memory shortName;
        if (ens) shortName = _extractName(bytes(deal.providerName));

        (, address provider,) = IE.whatIsTheAddressOf(ens ? shortName : deal.providerName);

        _mint(provider, dealHashId, 1, "");

        bool invoiceDue = deal.expiryTimestamp <= block.timestamp;

        uint256 dealAmount = _toUint(bytes(deal.dealAmount));

        if (msg.value != 0) {
            SafeTransferLib.safeTransferETH(WETH, msg.value); // Wrap.
            IE.command(string(abi.encodePacked("swap", " weth ", "to ", deal.dealAmount, " usdc")));

            uint256 sum;
            if ((sum = SafeTransferLib.balanceOf(WETH, address(this))) != 0) {
                assembly ("memory-safe") {
                    mstore(0x00, 0x2e1a7d4d) // `withdraw(uint256)`.
                    mstore(0x20, sum) // Store the `sum` argument.
                    pop(call(gas(), WETH, 0, 0x1c, 0x24, codesize(), 0x00))
                }
                SafeTransferLib.safeTransferETH(msg.sender, sum);
            }
        } else {
            SafeTransferLib.safeTransferFrom(USDC, msg.sender, address(this), dealAmount);
        }

        if (invoiceDue) {
            IE.command(
                string(
                    abi.encodePacked(
                        "send ",
                        ens ? shortName : deal.providerName,
                        " ",
                        deal.dealAmount,
                        " ",
                        "usdc"
                    )
                )
            );
        } else {
            address resolver;
            if (bytes(deal.resolverName).length == 42) {
                resolver = _toAddress(bytes(deal.resolverName));
            } else {
                (, resolver,) = IE.whatIsTheAddressOf(_extractName(bytes(deal.resolverName)));
            }
            escrowHash = ESCROWS.escrow(
                USDC,
                msg.sender,
                provider,
                resolver,
                dealAmount,
                deal.dealNotes,
                deal.expiryTimestamp
            );
            escrowHashes[dealHashId] = escrowHash;
        }

        if ( /*recycle*/ (dealHashId = SafeTransferLib.balanceOf(USDC, address(this))) != 0) {
            SafeTransferLib.safeTransfer(USDC, msg.sender, dealHashId);
        }
    }

    receive() external payable {
        assembly ("memory-safe") {
            if iszero(eq(caller(), WETH)) { revert(codesize(), codesize()) }
        }
    }

    error InvalidDecimalPlaces();
    error InvalidCharacter();
    error NumberTooLarge();

    function _toUint(bytes memory s) internal pure returns (uint256 result) {
        uint256 len = s.length;
        uint256 decimalPos = len;
        uint256 digits;
        uint256 maxDigits = 78;
        uint256 maxDecimals = 6;

        unchecked {
            for (uint256 i; i != len;) {
                bytes1 c = s[i++];
                if (c >= 0x30 && c <= 0x39) {
                    if (digits >= maxDigits) revert NumberTooLarge();
                    result = result * 10 + uint8(c) - 48;
                    ++digits;
                } else if (c == 0x2E && decimalPos == len) {
                    decimalPos = digits;
                } else if (c != 0x20) {
                    revert InvalidCharacter();
                }
            }

            uint256 decimals = digits - decimalPos;
            if (decimals > maxDecimals) revert InvalidDecimalPlaces();

            if (decimalPos == len) {
                result *= 10 ** maxDecimals;
            } else {
                result *= 10 ** (maxDecimals - decimals);
            }
        }
    }

    function _toAddress(bytes memory s) internal pure returns (address addr) {
        unchecked {
            uint256 result;
            for (uint256 i = 2; i != 42; ++i) {
                result *= 16;
                uint8 b = uint8(s[i]);
                if (b >= 48 && b <= 57) {
                    result += b - 48;
                } else if (b >= 65 && b <= 70) {
                    result += b - 55;
                } else if (b >= 97 && b <= 102) {
                    result += b - 87;
                } else {
                    revert InvalidSyntax();
                }
            }
            return address(uint160(result));
        }
    }

    function _createURI(DEAL memory deal) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            "Base DEAL V0",
                            '","description":"Onchain DEAL Structure"',
                            ',"image":"',
                            _render(deal),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function _render(DEAL memory deal) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" ',
                            'viewBox="0 0 800 1600" width="100%" height="100%" preserveAspectRatio="xMinYMin meet">',
                            "<style>",
                            '.legal-text { font-family: "Times New Roman", Times, serif; font-size: 12px; text-align: justify; line-height: 1.5; }',
                            ".title { font-size: 16px; font-weight: bold; text-align: center; }",
                            ".section { font-size: 14px; font-weight: bold; }",
                            ".signature-line { border-bottom: 1px solid black; min-width: 200px; display: inline-block; text-align: center; }",
                            "</style>",
                            '<rect width="100%" height="100%" fill="white" />',
                            '<foreignObject x="50" y="30" width="700" height="4140">',
                            '<div xmlns="http://www.w3.org/1999/xhtml">',
                            '<p class="title">DEAL (Digital Escrow Agreement for Labor)</p>',
                            _generateLegalText(deal),
                            "</div>",
                            "</foreignObject>",
                            "</svg>"
                        )
                    )
                )
            )
        );
    }

    function _generateLegalText(DEAL memory deal) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                _sections.sections(deal),
                '<p class="legal-text"> IN WITNESS WHEREOF, the undersigned have caused this Deal to be duly executed and delivered.</p>'
                '<div class="signature-block">',
                '<p class="legal-text">',
                deal.providerName,
                "</p>",
                '<p class="legal-text">By: <span class="signature-line">',
                deal.providerSignature != address(0)
                    ? LibString.toHexStringChecksummed(deal.providerSignature)
                    : "",
                "</span></p>",
                '<p class="legal-text">',
                deal.clientName,
                "</p>",
                '<p class="legal-text">By: <span class="signature-line">',
                deal.clientSignature != address(0)
                    ? LibString.toHexStringChecksummed(deal.clientSignature)
                    : "",
                "</span></p>",
                "</div>"
            )
        );
    }

    mapping(uint256 dealHashId => mapping(address party => address to)) public validTos;

    function approveTransfer(uint256 dealHashId, address to) public payable checkVal {
        DEAL storage deal = deals[dealHashId];

        if (msg.sender != deal.providerSignature) {
            if (msg.sender != deal.clientSignature) {
                revert Unauthorized();
            }
        }

        validTos[dealHashId][msg.sender] = to;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 dealHashId,
        uint256 amount,
        bytes calldata data
    ) public override(ERC1155) {
        DEAL storage deal = deals[dealHashId];
        if (
            to != validTos[dealHashId][deal.providerSignature]
                || to != validTos[dealHashId][deal.clientSignature]
        ) {
            revert Unauthorized();
        }
        super.safeTransferFrom(from, to, dealHashId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata dealHashIds,
        uint256[] calldata amounts,
        bytes calldata data
    ) public override(ERC1155) {
        for (uint256 i; i != dealHashIds.length; ++i) {
            DEAL storage deal = deals[dealHashIds[i]];
            if (
                to != validTos[dealHashIds[i]][deal.providerSignature]
                    || to != validTos[dealHashIds[i]][deal.clientSignature]
            ) {
                revert Unauthorized();
            }
        }
        super.safeBatchTransferFrom(from, to, dealHashIds, amounts, data);
    }

    function burn(address from, uint256 id, uint256 amount) public payable checkVal {
        _burn(msg.sender, from, id, amount); // Only owner or approved. For edits.
    }

    error Overflow();

    modifier checkVal() {
        if (msg.value > 0.01 ether) revert Overflow();
        _;
    }

    function sweep() public payable {
        SafeTransferLib.safeTransferETH(
            0xDa000000000000d2885F108500803dfBAaB2f2aA, address(this).balance
        );
    }

    event Log(address indexed caller, bytes32 indexed log);

    function fund(string calldata to, string calldata amount, /*USDC*/ bytes32 log)
        public
        payable
        checkVal
    {
        bool ens = bytes(to).length != 42;
        string memory shortName;
        if (ens) shortName = _extractName(bytes(to));

        SafeTransferLib.safeTransferFrom(
            USDC,
            msg.sender,
            address(this),
            _toUint(bytes(amount)) // Validate.
        );
        IE.command(
            string(abi.encodePacked("send ", ens ? shortName : to, " ", amount, " ", "usdc"))
        );

        uint256 sum;
        if ((sum = SafeTransferLib.balanceOf(USDC, address(this))) != 0) {
            SafeTransferLib.safeTransfer(USDC, msg.sender, sum);
        }
        emit Log(msg.sender, log);
    }

    function fundFromETH(string calldata to, string calldata amount, /*USDC*/ bytes32 log)
        public
        payable
    {
        bool ens = bytes(to).length != 42;
        string memory shortName;
        if (ens) shortName = _extractName(bytes(to));

        SafeTransferLib.safeTransferETH(WETH, msg.value); // Wrap.
        IE.command(
            string(
                abi.encodePacked(
                    "swap", " weth ", "to ", amount, " usdc", " for ", ens ? shortName : to
                )
            )
        );

        uint256 sum;
        if ((sum = SafeTransferLib.balanceOf(WETH, address(this))) != 0) {
            assembly ("memory-safe") {
                mstore(0x00, 0x2e1a7d4d) // `withdraw(uint256)`.
                mstore(0x20, sum) // Store the `sum` argument.
                pop(call(gas(), WETH, 0, 0x1c, 0x24, codesize(), 0x00))
            }
            SafeTransferLib.safeTransferETH(msg.sender, sum);
        }
        emit Log(msg.sender, log);
    }

    function fundDeal(DEAL memory deal) public payable returns (bytes32 escrowHash) {
        string memory baseName = IE.whatIsTheNameOf(msg.sender);
        if (bytes(baseName).length != 0) deal.clientName = baseName;
        else deal.clientName = LibString.toHexStringChecksummed(msg.sender);

        if (deal.providerSignature != address(0)) delete deal.providerSignature;
        deal.clientSignature = msg.sender;
        uint256 dealHashId = uint256(keccak256(abi.encode(deal)));

        bool ens = bytes(deal.providerName).length != 42;
        string memory shortName;
        if (ens) shortName = _extractName(bytes(deal.providerName));

        (, address provider,) = IE.whatIsTheAddressOf(ens ? shortName : deal.providerName);

        _mint(provider, dealHashId, 1, "");
        _mint(msg.sender, dealHashId, 1, "");

        bool invoiceDue = deal.expiryTimestamp <= block.timestamp;

        uint256 dealAmount = _toUint(bytes(deal.dealAmount));

        if (msg.value != 0) {
            SafeTransferLib.safeTransferETH(WETH, msg.value); // Wrap.
            IE.command(string(abi.encodePacked("swap", " weth ", "to ", deal.dealAmount, " usdc")));

            uint256 sum;
            if ((sum = SafeTransferLib.balanceOf(WETH, address(this))) != 0) {
                assembly ("memory-safe") {
                    mstore(0x00, 0x2e1a7d4d) // `withdraw(uint256)`.
                    mstore(0x20, sum) // Store the `sum` argument.
                    pop(call(gas(), WETH, 0, 0x1c, 0x24, codesize(), 0x00))
                }
                SafeTransferLib.safeTransferETH(msg.sender, sum);
            }
        } else {
            SafeTransferLib.safeTransferFrom(USDC, msg.sender, address(this), dealAmount);
        }

        if (invoiceDue) {
            IE.command(
                string(
                    abi.encodePacked(
                        "send ",
                        ens ? shortName : deal.providerName,
                        " ",
                        deal.dealAmount,
                        " ",
                        "usdc"
                    )
                )
            );
        } else {
            address resolver;
            if (bytes(deal.resolverName).length == 42) {
                resolver = _toAddress(bytes(deal.resolverName));
            } else {
                (, resolver,) = IE.whatIsTheAddressOf(_extractName(bytes(deal.resolverName)));
            }
            escrowHash = ESCROWS.escrow(
                USDC,
                msg.sender,
                provider,
                resolver,
                dealAmount,
                deal.dealNotes,
                deal.expiryTimestamp
            );
            escrowHashes[dealHashId] = escrowHash;
            _ids[resolver].push(dealHashId);
        }

        if (bytes(deals[dealHashId].clientName).length != 0) revert Registered();

        deals[dealHashId] = DEAL({
            providerName: deal.providerName,
            clientName: deal.clientName,
            resolverName: deal.resolverName,
            dealAmount: deal.dealAmount,
            dealNotes: deal.dealNotes,
            dealDate: deal.dealDate,
            expiryDate: deal.expiryDate,
            expiryTimestamp: deal.expiryTimestamp,
            providerSignature: address(0),
            clientSignature: deal.clientSignature
        });

        _ids[msg.sender].push(dealHashId);
        _ids[provider].push(dealHashId);

        if ( /*recycle*/ (dealHashId = SafeTransferLib.balanceOf(USDC, address(this))) != 0) {
            SafeTransferLib.safeTransfer(USDC, msg.sender, dealHashId);
        }
    }

    function providerSign(uint256 dealHashId) public payable checkVal {
        DEAL storage deal = deals[dealHashId];

        if (deal.clientSignature == address(0)) revert Unregistered();
        if (deal.providerSignature != address(0)) revert Registered();

        if (bytes(deal.providerName).length == 42) {
            if (msg.sender != _toAddress(bytes(deal.providerName))) revert Unauthorized();
        } else {
            (, address providerAddress,) =
                IE.whatIsTheAddressOf(_extractName(bytes(deal.providerName)));
            if (msg.sender != providerAddress) {
                revert Unauthorized();
            }
        }

        deal.providerSignature = msg.sender;
    }
}
