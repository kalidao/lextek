// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Base64} from "@solady/src/utils/Base64.sol";
import {ERC1155} from "@solady/src/tokens/ERC1155.sol";
import {LibString} from "@solady/src/utils/LibString.sol";
import {DateTimeLib} from "@solady/src/utils/DateTimeLib.sol";
import {SafeTransferLib} from "@solady/src/utils/SafeTransferLib.sol";

struct SAFE {
    string companyName;
    string investorName;
    string purchaseAmount;
    string postMoneyValuationCap;
    string safeDate;
    address companySignature;
    address investorSignature;
}

interface ISections {
    function section2() external view returns (string memory);
    function section3() external view returns (string memory);
    function section4() external view returns (string memory);
    function section5() external view returns (string memory);
}

interface IIE {
    function command(string calldata) external payable;
    function whatIsTheNameOf(address) external view returns (string memory);
    function whatIsTheAddressOf(string memory) external view returns (address, address, bytes32);
}

IIE constant IE = IIE(0x1e00cE4800dE0D0000640070006dfc5F93dD0ff9);
address constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

contract BaseSAFEV0 is ERC1155 {
    ISections immutable _section2;
    ISections immutable _section3;
    ISections immutable _section4;
    ISections immutable _section5;

    mapping(uint256 safeHashId => SAFE) public safes;
    string public constant name = "Base Safe V0";
    string public constant symbol = "BSAFE";

    constructor(ISections section2, ISections section3, ISections section4, ISections section5)
        payable
    {
        (_section2, _section3, _section4, _section5) = (section2, section3, section4, section5);
        SafeTransferLib.safeApprove(USDC, address(IE), type(uint256).max);
    }

    function uri(uint256 safeHashId) public view override(ERC1155) returns (string memory) {
        return _createURI(safes[safeHashId]);
    }

    function draft(SAFE memory safe) public view returns (string memory) {
        if (safe.investorSignature != address(0)) safe.investorSignature = address(0);
        return _createURI(safe);
    }

    function getHashId(SAFE memory safe) public pure returns (uint256) {
        if (safe.investorSignature != address(0)) safe.investorSignature = address(0);
        return uint256(keccak256(abi.encode(safe)));
    }

    error Registered();

    function send(
        string calldata investorName,
        string calldata purchaseAmount,
        string calldata postMoneyValuationCap
    ) public returns (uint256 safeHashId) {
        SAFE memory safe;

        string memory baseName = IE.whatIsTheNameOf(msg.sender);
        if (bytes(baseName).length != 0) safe.companyName = baseName;
        else safe.companyName = LibString.toHexStringChecksummed(msg.sender);

        safe.investorName = investorName;
        safe.purchaseAmount = purchaseAmount;
        safe.postMoneyValuationCap = postMoneyValuationCap;
        (uint256 year, uint256 month, uint256 day) = DateTimeLib.timestampToDate(block.timestamp);

        string memory _month = LibString.toString(month);
        string memory _day = LibString.toString(day);
        string memory _year = LibString.toString(year);

        safe.safeDate = string(abi.encodePacked(_month, "/", _day, "/", _year));
        safe.companySignature = msg.sender;

        safeHashId = uint256(keccak256(abi.encode(safe)));

        if (bytes(safes[safeHashId].companyName).length != 0) revert Registered();

        safes[safeHashId] = SAFE({
            companyName: safe.companyName,
            investorName: safe.investorName,
            purchaseAmount: safe.purchaseAmount,
            postMoneyValuationCap: safe.postMoneyValuationCap,
            safeDate: safe.safeDate,
            companySignature: safe.companySignature,
            investorSignature: address(0)
        });

        bool ens = bytes(safe.investorName).length != 42;

        string memory shortName;
        if (ens) shortName = _extractName(bytes(safe.investorName));
        (, address investorAddress,) = IE.whatIsTheAddressOf(ens ? shortName : safe.investorName);
        _mint(investorAddress, safeHashId, 1, "");
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

    function sign(uint256 safeHashId) public {
        SAFE storage safe = safes[safeHashId];

        if (safe.companySignature == address(0)) revert Unregistered();
        if (safe.investorSignature != address(0)) revert Registered();

        if (bytes(safe.investorName).length == 42) {
            if (msg.sender != _toAddress(bytes(safe.investorName))) revert Unauthorized();
        } else {
            (, address investorAddress,) =
                IE.whatIsTheAddressOf(_extractName(bytes(safe.investorName)));
            if (msg.sender != investorAddress) {
                revert Unauthorized();
            }
        }

        safe.investorSignature = msg.sender;

        bool ens = bytes(safe.companyName).length != 42;

        string memory shortName;
        if (ens) shortName = _extractName(bytes(safe.companyName));

        (, address companyAddress,) = IE.whatIsTheAddressOf(ens ? shortName : safe.companyName);

        _mint(companyAddress, safeHashId, 1, "");

        SafeTransferLib.safeTransferFrom(
            USDC, msg.sender, address(this), _toUint(bytes(safe.purchaseAmount))
        );
        IE.command(
            string(
                abi.encodePacked(
                    "send ",
                    ens ? shortName : safe.companyName,
                    " ",
                    safe.purchaseAmount,
                    " ",
                    "usdc"
                )
            )
        );

        if ( /*recycle*/ (safeHashId = SafeTransferLib.balanceOf(USDC, address(this))) != 0) {
            SafeTransferLib.safeTransfer(USDC, msg.sender, safeHashId);
        }
    }

    error InvalidCharacter();

    function _toUint(bytes memory s) internal pure returns (uint256 result) {
        unchecked {
            uint256 len = s.length;
            bool hasDecimal;
            uint256 decimalPlaces;
            for (uint256 i; i != len; ++i) {
                bytes1 c = s[i];
                if (c >= 0x30 && c <= 0x39) {
                    result = result * 10 + uint8(c) - 48;
                    if (hasDecimal) {
                        if (++decimalPlaces > 6) break;
                    }
                } else if (c == 0x2E && !hasDecimal) {
                    hasDecimal = true;
                } else if (c != 0x20) {
                    revert InvalidCharacter();
                }
            }
            if (!hasDecimal) {
                result *= 10 ** 6;
            } else if (decimalPlaces < 6) {
                result *= 10 ** (6 - decimalPlaces);
            }
        }
    }

    function _toAddress(bytes memory s) internal pure virtual returns (address addr) {
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

    function _createURI(SAFE memory safe) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            "Base SAFE V0",
                            '","description":"Onchain Y Combinator SAFE"',
                            ',"image":"',
                            _render(safe),
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function _render(SAFE memory safe) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '<svg width="800" height="3900" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                            "<style>",
                            '.legal-text { font-family: "Times New Roman", Times, serif; font-size: 12px; text-align: justify; line-height: 1.5; }',
                            ".title { font-size: 16px; font-weight: bold; text-align: center; }",
                            ".section { font-size: 14px; font-weight: bold; }",
                            ".highlight { background-color: yellow; opacity: 0.5; }",
                            ".editable { cursor: pointer; }",
                            ".dropdown { cursor: pointer; }",
                            ".signature-line { border-bottom: 1px solid black; min-width: 200px; display: inline-block; text-align: center; cursor: pointer; }",
                            "</style>",
                            '<rect width="100%" height="100%" fill="white" />',
                            '<foreignObject x="50" y="30" width="700" height="6700">',
                            '<div xmlns="http://www.w3.org/1999/xhtml">',
                            '<p class="title">SAFE (Simple Agreement for Future Equity)</p>',
                            _generateLegalText(safe),
                            "</div>",
                            "</foreignObject>",
                            "</svg>"
                        )
                    )
                )
            )
        );
    }

    function _generateLegalText(SAFE memory safe) internal view returns (string memory) {
        return string(
            abi.encodePacked(
                _section1(safe),
                _section2.section2(),
                _section3.section3(),
                _section4.section4(),
                _section5.section5(),
                '<p class="legal-text">',
                safe.companyName,
                "</p>",
                '<p class="legal-text">By: ',
                safe.companySignature != address(0)
                    ? LibString.toHexStringChecksummed(safe.companySignature)
                    : "____________________",
                "</p>",
                '<p class="legal-text">',
                safe.investorName,
                "</p>",
                '<p class="legal-text">By: ',
                safe.investorSignature != address(0)
                    ? LibString.toHexStringChecksummed(safe.investorSignature)
                    : "____________________",
                "</p>"
            )
        );
    }

    function _section1(SAFE memory safe) internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<p class="legal-text">THIS INSTRUMENT AND ANY SECURITIES ISSUABLE PURSUANT HERETO HAVE NOT BEEN REGISTERED UNDER THE SECURITIES ACT OF 1933, AS AMENDED (THE "SECURITIES ACT"), OR UNDER THE SECURITIES LAWS OF CERTAIN STATES. THESE SECURITIES MAY NOT BE OFFERED, SOLD OR OTHERWISE TRANSFERRED, PLEDGED OR HYPOTHECATED EXCEPT AS PERMITTED IN THIS SAFE AND UNDER THE ACT AND APPLICABLE STATE SECURITIES LAWS PURSUANT TO AN EFFECTIVE REGISTRATION STATEMENT OR AN EXEMPTION THEREFROM.</p>',
                '<p class="title">',
                safe.companyName,
                "</p>",
                '<p class="legal-text">THIS CERTIFIES THAT in exchange for the payment by ',
                safe.investorName,
                ' (the "Investor") of $',
                safe.purchaseAmount,
                ' (the "Purchase Amount") on or about ',
                safe.safeDate,
                ", ",
                safe.companyName,
                ', a Delaware corporation (the "Company"), issues to the Investor the right to certain shares of the Company\'s Capital Stock, subject to the terms described below. For the avoidance of doubt, if not otherwise provided by reference to their public key or Ethereum Name Service (ENS) domain, the identity and corporate organization of the parties shall be understood with respect to this document and other evidence provided by the parties in connection with the transactions contemplated hereby.</p>',
                '<p class="legal-text">The "Post-Money Valuation Cap" is $',
                safe.postMoneyValuationCap,
                ". See Section 2 for certain additional defined terms.</p>",
                '<h2 class="section">1. Events</h2>',
                '<p class="legal-text">(a) Equity Financing. If there is an Equity Financing before the termination of this Safe, on the initial closing of such Equity Financing, this Safe will automatically convert into the greater of: (1) the number of shares of Standard Preferred Stock equal to the Purchase Amount divided by the lowest price per share of the Standard Preferred Stock; or (2) the number of shares of Safe Preferred Stock equal to the Purchase Amount divided by the Safe Price.</p>',
                '<p class="legal-text">In connection with the automatic conversion of this Safe into shares of Standard Preferred Stock or Safe Preferred Stock, the Investor will execute and deliver to the Company all of the transaction documents related to the Equity Financing; provided, that such documents (i) are the same documents to be entered into with the purchasers of Standard Preferred Stock, with appropriate variations for the Safe Preferred Stock if applicable, and (ii) have customary exceptions to any drag-along applicable to the Investor, including (without limitation) limited representations, warranties, liability and indemnification obligations for the Investor.</p>',
                '<p class="legal-text">(b) Liquidity Event. If there is a Liquidity Event before the termination of this Safe, the Investor will automatically be entitled (subject to the liquidation priority set forth in Section 1(d) below) to receive a portion of Proceeds, due and payable to the Investor immediately prior to, or concurrent with, the consummation of such Liquidity Event, equal to the greater of (i) the Purchase Amount (the "Cash-Out Amount") or (ii) the amount payable on the number of shares of Common Stock equal to the Purchase Amount divided by the Liquidity Price (the "Conversion Amount"). If any of the Company\'s securityholders are given a choice as to the form and amount of Proceeds to be received in a Liquidity Event, the Investor will be given the same choice, provided that the Investor may not choose to receive a form of consideration that the Investor would be ineligible to receive as a result of the Investor\'s failure to satisfy any requirement or limitation generally applicable to the Company\'s securityholders, or under any applicable laws.</p>',
                '<p class="legal-text">Notwithstanding the foregoing, in connection with a Change of Control intended to qualify as a tax-free reorganization, the Company may reduce the cash portion of Proceeds payable to the Investor by the amount determined by its board of directors in good faith for such Change of Control to qualify as a tax-free reorganization for U.S. federal income tax purposes, provided that such reduction (A) does not reduce the total Proceeds payable to such Investor and (B) is applied in the same manner and on a pro rata basis to all securityholders who have equal priority to the Investor under Section 1(d).</p>',
                '<p class="legal-text">(c) Dissolution Event. If there is a Dissolution Event before the termination of this Safe, the Investor will automatically be entitled (subject to the liquidation priority set forth in Section 1(d) below) to receive a portion of Proceeds equal to the Cash-Out Amount, due and payable to the Investor immediately prior to the consummation of the Dissolution Event.</p>',
                '<p class="legal-text">(d) Liquidation Priority. In a Liquidity Event or Dissolution Event, this Safe is intended to operate like standard non-participating Preferred Stock. The Investor\'s right to receive its Cash-Out Amount is:</p>',
                '<p class="legal-text">(i) Junior to payment of outstanding indebtedness and creditor claims, including contractual claims for payment and convertible promissory notes (to the extent such convertible promissory notes are not actually or notionally converted into Capital Stock);</p>',
                '<p class="legal-text">(ii) On par with payments for other Safes and/or Preferred Stock, and if the applicable Proceeds are insufficient to permit full payments to the Investor and such other Safes and/or Preferred Stock, the applicable Proceeds will be distributed pro rata to the Investor and such other Safes and/or Preferred Stock in proportion to the full payments that would otherwise be due; and</p>',
                '<p class="legal-text">(iii) Senior to payments for Common Stock.</p>',
                '<p class="legal-text">The Investor\'s right to receive its Conversion Amount is (A) on par with payments for Common Stock and other Safes and/or Preferred Stock who are also receiving Conversion Amounts or Proceeds on a similar as-converted to Common Stock basis, and (B) junior to payments described in clauses (i) and (ii) above (in the latter case, to the extent such payments are Cash-Out Amounts or similar liquidation preferences).</p>',
                '<p class="legal-text">(e) Termination. This Safe will automatically terminate (without relieving the Company of any obligations arising from a prior breach of or non-compliance with this Safe) immediately following the earliest to occur of: (i) the issuance of Capital Stock to the Investor pursuant to the automatic conversion of this Safe under Section 1(a); or (ii) the payment, or setting aside for payment, of amounts due the Investor pursuant to Section 1(b) or Section 1(c).</p>'
            )
        );
    }
}
