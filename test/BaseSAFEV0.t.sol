// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Section2} from "../src/SAFE/Section2.sol";
import {Section3} from "../src/SAFE/Section3.sol";
import {Section4} from "../src/SAFE/Section4.sol";
import {Section5} from "../src/SAFE/Section5.sol";
import {ISections, SAFE, BaseSAFEV0} from "../src/SAFE/BaseSAFEV0.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

import {LibString} from "@solady/src/utils/LibString.sol";
import {SignatureCheckerLib} from "@solady/src/utils/SignatureCheckerLib.sol";

import "../lib/forge-std/src/console.sol";

contract BaseSAFEV0Test is Test {
    BaseSAFEV0 bsafe;
    ISections section2;
    ISections section3;
    ISections section4;
    ISections section5;

    address constant z0r0z = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    address constant nani = 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C;

    address constant whale = 0x0B0A5886664376F59C351ba3f598C8A8B4D0A6f3;
    address constant usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    address constant ethHolder = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    function setUp() public payable {
        vm.createSelectFork(vm.rpcUrl("base"));
        section2 = ISections(address(new Section2()));
        section3 = ISections(address(new Section3()));
        section4 = ISections(address(new Section4()));
        section5 = ISections(address(new Section5()));
        bsafe = new BaseSAFEV0(section2, section3, section4, section5);
        vm.label(address(bsafe), "BSAFE");
        vm.deal(nani, 1 ether);
        vm.deal(whale, 100 ether);
        deal(usdc, whale, 1000000e6);
    }

    function testLogURI() public payable {
        console.log(bsafe.uri(0));
    }

    function testDraft() public {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        // Retrieve the actual SAFE struct from the contract.
        (
            string memory companyName,
            string memory investorName,
            string memory purchaseAmount,
            string memory postMoneyValuationCap,
            string memory safeDate,
            address companySignature,
        ) = bsafe.safes(id);

        // Create a new SAFE struct with the same data.
        SAFE memory safe = SAFE({
            companyName: companyName,
            investorName: investorName,
            purchaseAmount: purchaseAmount,
            postMoneyValuationCap: postMoneyValuationCap,
            safeDate: safeDate,
            companySignature: companySignature,
            investorSignature: address(0) // Draft should not include investor signature.
        });

        string memory draftURI = bsafe.draft(safe);
        string memory finalURI = bsafe.uri(id);

        // The draft URI should match the final URI before signing.
        assertTrue(keccak256(bytes(draftURI)) == keccak256(bytes(finalURI)));

        // Now let's sign the SAFE.
        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        // After signing, the URIs should be different.
        finalURI = bsafe.uri(id);
        assertTrue(keccak256(bytes(draftURI)) != keccak256(bytes(finalURI)));
    }

    function testGetHashId() public {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        // Retrieve the actual SAFE struct from the contract.
        (
            string memory companyName,
            string memory investorName,
            string memory purchaseAmount,
            string memory postMoneyValuationCap,
            string memory safeDate,
            address companySignature,
        ) = bsafe.safes(id);

        // Create a new SAFE struct with the same data.
        SAFE memory safe = SAFE({
            companyName: companyName,
            investorName: investorName,
            purchaseAmount: purchaseAmount,
            postMoneyValuationCap: postMoneyValuationCap,
            safeDate: safeDate,
            companySignature: companySignature,
            investorSignature: address(0) // Draft should not include investor signature.
        });

        uint256 calculatedId = bsafe.getHashId(safe);
        assertEq(id, calculatedId);
    }

    function testGetHashIds() public {
        vm.startPrank(nani);
        uint256 id1 = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");
        uint256 id2 = bsafe.send(LibString.toHexStringChecksummed(whale), "20000", "20000000");
        vm.stopPrank();

        uint256[] memory naniIds = bsafe.getHashIds(nani);
        assertEq(naniIds.length, 2);
        assertEq(naniIds[0], id1);
        assertEq(naniIds[1], id2);

        uint256[] memory whaleIds = bsafe.getHashIds(whale);
        assertEq(whaleIds.length, 2);
        assertEq(whaleIds[0], id1);
        assertEq(whaleIds[1], id2);
    }

    function testCheckSignature() public {
        address alice;
        uint256 aliceKey;
        (alice, aliceKey) = makeAddrAndKey("alice");

        address bob;
        uint256 bobKey;
        (bob, bobKey) = makeAddrAndKey("bob");

        vm.prank(alice);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(bob), "10000", "10000000");

        bytes32 messageHash = SignatureCheckerLib.toEthSignedMessageHash(bytes32(id));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, messageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        bool isValid = bsafe.checkSignature(alice, id, signature);
        assertTrue(isValid);

        isValid = bsafe.checkSignature(bob, id, signature);
        assertFalse(isValid);

        (v, r, s) = vm.sign(bobKey, messageHash);
        signature = abi.encodePacked(r, s, v);

        isValid = bsafe.checkSignature(bob, id, signature);
        assertTrue(isValid);
    }

    function testSend() public payable {
        vm.prank(nani);
        uint256 id = bsafe.send("z0r0z.base.eth", "10000", "10000000");
        assertTrue(bsafe.balanceOf(z0r0z, id) == 1);
    }

    function testSendAndSignStorage() public payable {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");
        assertTrue(bsafe.balanceOf(whale, id) == 1);

        (
            string memory companyName,
            string memory investorName,
            string memory purchaseAmount,
            string memory postMoneyValuationCap,
            ,
            address companySignature,
            address investorSignature
        ) = bsafe.safes(id);

        assertEq(keccak256(bytes(companyName)), keccak256(bytes("nani.base.eth")));
        assertEq(
            keccak256(bytes(investorName)),
            keccak256(bytes(LibString.toHexStringChecksummed(whale)))
        );
        assertEq(keccak256(bytes(purchaseAmount)), keccak256(bytes("10000")));
        assertEq(keccak256(bytes(postMoneyValuationCap)), keccak256(bytes("10000000")));
        assertEq(companySignature, nani);
        assertEq(investorSignature, address(0));

        console.log(bsafe.uri(id));

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        console.log(bsafe.uri(id));

        assertTrue(bsafe.balanceOf(whale, id) == 1);
        assertTrue(bsafe.balanceOf(nani, id) == 1);

        (
            companyName,
            investorName,
            purchaseAmount,
            postMoneyValuationCap,
            ,
            companySignature,
            investorSignature
        ) = bsafe.safes(id);

        assertEq(keccak256(bytes(companyName)), keccak256(bytes("nani.base.eth")));
        assertEq(
            keccak256(bytes(investorName)),
            keccak256(bytes(LibString.toHexStringChecksummed(whale)))
        );
        assertEq(keccak256(bytes(purchaseAmount)), keccak256(bytes("10000")));
        assertEq(keccak256(bytes(postMoneyValuationCap)), keccak256(bytes("10000000")));
        assertEq(companySignature, nani);
        assertEq(investorSignature, whale);
    }

    function testSendAndSign() public payable {
        uint256 companyBalBefore = IERC20(usdc).balanceOf(nani);
        uint256 investorBalBefore = IERC20(usdc).balanceOf(whale);
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");
        assertTrue(bsafe.balanceOf(whale, id) == 1);
        assertTrue(bsafe.balanceOf(nani, id) == 0);

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        assertTrue(bsafe.balanceOf(whale, id) == 1);
        assertTrue(bsafe.balanceOf(nani, id) == 1);

        uint256 companyBalAfter = IERC20(usdc).balanceOf(nani);
        uint256 investorBalAfter = IERC20(usdc).balanceOf(whale);

        assertTrue(companyBalAfter == companyBalBefore + 10000 * 10 ** 6);
        assertTrue(investorBalAfter == investorBalBefore - 10000 * 10 ** 6);
    }

    function testSendAndSignDecimalUSDC() public payable {
        uint256 companyBalBefore = IERC20(usdc).balanceOf(nani);
        uint256 investorBalBefore = IERC20(usdc).balanceOf(whale);
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "25.55", "10000000");
        assertTrue(bsafe.balanceOf(whale, id) == 1);
        assertTrue(bsafe.balanceOf(nani, id) == 0);

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        assertTrue(bsafe.balanceOf(whale, id) == 1);
        assertTrue(bsafe.balanceOf(nani, id) == 1);

        uint256 companyBalAfter = IERC20(usdc).balanceOf(nani);
        uint256 investorBalAfter = IERC20(usdc).balanceOf(whale);

        assertTrue(companyBalAfter == companyBalBefore + 25550000);
        assertTrue(investorBalAfter == investorBalBefore - 25550000);
    }

    error Unauthorized();

    function testSignUnauthFail() public payable {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");
        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(z0r0z);
        vm.expectRevert(Unauthorized.selector);
        bsafe.sign(id);
    }

    error Unregistered();
    error InvalidReceiver();

    function testSendUnregisteredNameFail() public payable {
        vm.prank(nani);
        vm.expectRevert(InvalidReceiver.selector);
        bsafe.send("zany.z0r0z.eth", "10000", "10000000");
    }

    function testSendFailOnDuplicate() public {
        vm.prank(nani);
        bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");
        vm.expectRevert(BaseSAFEV0.Registered.selector);
        vm.prank(nani);
        bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");
    }

    function testSignFailOnUnregistered() public {
        uint256 fakeId = 12345;

        vm.expectRevert(BaseSAFEV0.Unregistered.selector);
        vm.prank(whale);
        bsafe.sign(fakeId);
    }

    function testSignFailOnAlreadySigned() public {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        vm.expectRevert(BaseSAFEV0.Registered.selector);
        vm.prank(whale);
        bsafe.sign(id);
    }

    error InvalidDecimalPlaces();
    error InvalidCharacter();
    error NumberTooLarge();

    function testSendInvalidInputs() public {
        vm.startPrank(nani);
        // Test with empty investor name.
        vm.expectRevert();
        bsafe.send("", "10000", "10000000");
        // Test with garbled investor name.
        vm.startPrank(nani);
        vm.expectRevert();
        bsafe.send("bob a ss d aw dd", "10000", "10000000");
        vm.startPrank(nani);
        vm.expectRevert();
        bsafe.send("bobbbbbbbbbbbbbbbbbbbb", "10000", "10000000");
        // ok
        vm.startPrank(nani);
        bsafe.send("z0r0z.base.eth", "123456", "10000000");
        vm.startPrank(nani);
        bsafe.send("z0r0z.base.eth", "10500.5", "10000000");
        // Purchase amount invalid character.
        vm.expectRevert(InvalidCharacter.selector);
        bsafe.send("z0r0z.base.eth", "123A56", "10000000");
        // Purchase decimals invalid.
        vm.expectRevert(InvalidDecimalPlaces.selector);
        bsafe.send("z0r0z.base.eth", "12344444488888.4444444444444444444", "10000000");
        vm.expectRevert(InvalidDecimalPlaces.selector);
        bsafe.send("z0r0z.base.eth", "12.34444444444444444444444444", "10000000");
        // Purchase amount invalid.
        vm.expectRevert(NumberTooLarge.selector);
        bsafe.send(
            "z0r0z.base.eth",
            "123444444444466666666666666666666666666666666666666444444448888888888888888888884444444",
            "10000000"
        );
    }

    function testTokenTransferDuringSign() public {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        uint256 initialWhaleBalance = IERC20(usdc).balanceOf(whale);

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);

        vm.prank(whale);
        bsafe.sign(id);

        uint256 finalWhaleBalance = IERC20(usdc).balanceOf(whale);
        uint256 finalContractBalance = IERC20(usdc).balanceOf(address(bsafe));

        assertEq(initialWhaleBalance - finalWhaleBalance, 10000 * 10 ** 6);
        assertEq(finalContractBalance, 0);
    }

    function testApproveTransfer() public payable {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        address newOwner = address(0x123);

        // Company approves transfer.
        vm.prank(nani);
        bsafe.approveTransfer(id, newOwner);

        // Investor approves transfer.
        vm.prank(whale);
        bsafe.approveTransfer(id, newOwner);

        // Transfer should succeed.
        vm.prank(whale);
        bsafe.safeTransferFrom(whale, newOwner, id, 1, "");

        assertTrue(bsafe.balanceOf(newOwner, id) == 1);
        assertTrue(bsafe.balanceOf(whale, id) == 0);
    }

    function testTransferFailsWithoutBothApprovals() public payable {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        address newOwner = address(0x123);

        // Only company approves transfer.
        vm.prank(nani);
        bsafe.approveTransfer(id, newOwner);

        // Transfer should fail.
        vm.prank(whale);
        vm.expectRevert(Unauthorized.selector);
        bsafe.safeTransferFrom(whale, newOwner, id, 1, "");

        assertTrue(bsafe.balanceOf(whale, id) == 1);
        assertTrue(bsafe.balanceOf(newOwner, id) == 0);
    }

    function testTransferToUnapprovedAddress() public payable {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        address approvedNewOwner = address(0x123);
        address unapprovedNewOwner = address(0x456);

        // Both parties approve transfer to approvedNewOwner.
        vm.prank(nani);
        bsafe.approveTransfer(id, approvedNewOwner);
        vm.prank(whale);
        bsafe.approveTransfer(id, approvedNewOwner);

        // Try to transfer to unapprovedNewOwner.
        vm.prank(whale);
        vm.expectRevert(Unauthorized.selector);
        bsafe.safeTransferFrom(whale, unapprovedNewOwner, id, 1, "");

        assertTrue(bsafe.balanceOf(whale, id) == 1);
        assertTrue(bsafe.balanceOf(unapprovedNewOwner, id) == 0);
    }

    function testApproveTransferUnauthorized() public payable {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        address newOwner = address(0x123);

        // Unauthorized address tries to approve transfer.
        vm.prank(address(0x456));
        vm.expectRevert(Unauthorized.selector);
        bsafe.approveTransfer(id, newOwner);
    }

    function testSafeBatchTransferFrom() public payable {
        // Create three SAFEs.
        vm.startPrank(nani);
        uint256 id1 = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");
        uint256 id2 = bsafe.send(LibString.toHexStringChecksummed(whale), "20000", "20000000");
        uint256 id3 = bsafe.send(LibString.toHexStringChecksummed(whale), "30000", "30000000");
        vm.stopPrank();

        // Sign all SAFEs.
        vm.startPrank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        bsafe.sign(id1);
        bsafe.sign(id2);
        bsafe.sign(id3);
        vm.stopPrank();

        address newOwner = address(0x123);

        // Approve transfers for id1 and id2, but not id3.
        vm.prank(nani);
        bsafe.approveTransfer(id1, newOwner);
        vm.prank(whale);
        bsafe.approveTransfer(id1, newOwner);

        vm.prank(nani);
        bsafe.approveTransfer(id2, newOwner);
        vm.prank(whale);
        bsafe.approveTransfer(id2, newOwner);

        // Test 1: Batch transfer of approved tokens should succeed.
        uint256[] memory ids = new uint256[](2);
        ids[0] = id1;
        ids[1] = id2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1;
        amounts[1] = 1;

        vm.prank(whale);
        bsafe.safeBatchTransferFrom(whale, newOwner, ids, amounts, "");

        assertTrue(bsafe.balanceOf(newOwner, id1) == 1);
        assertTrue(bsafe.balanceOf(newOwner, id2) == 1);
        assertTrue(bsafe.balanceOf(whale, id1) == 0);
        assertTrue(bsafe.balanceOf(whale, id2) == 0);

        // Test 2: Batch transfer including unapproved transfer should fail.
        ids = new uint256[](3);
        ids[0] = id1;
        ids[1] = id2;
        ids[2] = id3;
        amounts = new uint256[](3);
        amounts[0] = 1;
        amounts[1] = 1;
        amounts[2] = 1;

        vm.prank(nani);
        vm.expectRevert(Unauthorized.selector);
        bsafe.safeBatchTransferFrom(nani, newOwner, ids, amounts, "");

        // Test 3: Batch transfer to unapproved address should fail.
        address unapprovedOwner = address(0x456);

        vm.prank(nani);
        vm.expectRevert(Unauthorized.selector);
        bsafe.safeBatchTransferFrom(nani, unapprovedOwner, ids, amounts, "");
    }

    function testMultipleApprovalsAndTransfers() public {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        address newOwner1 = address(0x123);
        address newOwner2 = address(0x456);

        // First approval and transfer.
        vm.prank(nani);
        bsafe.approveTransfer(id, newOwner1);
        vm.prank(whale);
        bsafe.approveTransfer(id, newOwner1);

        vm.prank(whale);
        bsafe.safeTransferFrom(whale, newOwner1, id, 1, "");

        // Second approval and transfer.
        vm.prank(nani);
        bsafe.approveTransfer(id, newOwner2);
        vm.prank(whale);
        bsafe.approveTransfer(id, newOwner2);

        vm.prank(newOwner1);
        bsafe.safeTransferFrom(newOwner1, newOwner2, id, 1, "");

        assertEq(bsafe.balanceOf(newOwner2, id), 1);
        assertEq(bsafe.balanceOf(newOwner1, id), 0);
        assertEq(bsafe.balanceOf(whale, id), 0);
    }

    function testURIAfterTransfer() public {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        string memory initialURI = bsafe.uri(id);

        address newOwner = address(0x123);

        vm.prank(nani);
        bsafe.approveTransfer(id, newOwner);
        vm.prank(whale);
        bsafe.approveTransfer(id, newOwner);

        vm.prank(whale);
        bsafe.safeTransferFrom(whale, newOwner, id, 1, "");

        string memory finalURI = bsafe.uri(id);

        assertTrue(keccak256(bytes(initialURI)) == keccak256(bytes(finalURI)));
    }

    function testBurn() public {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        assertEq(bsafe.balanceOf(whale, id), 1);

        // Burn the SAFE.
        vm.prank(whale);
        bsafe.burn(whale, id, 1);

        // Check balance after burning.
        assertEq(bsafe.balanceOf(whale, id), 0);

        // Try to burn again (should fail)
        vm.expectRevert(); // Expect revert due to insufficient balance.
        vm.prank(whale);
        bsafe.burn(whale, id, 1);

        // Try to burn from an address that doesn't own the token.
        vm.expectRevert(); // Expect revert due to not being owner or approved.
        vm.prank(whale);
        bsafe.burn(nani, id, 1);
    }

    function testBurnAfterSigning() public {
        // Create and sign a SAFE.
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        // Try to burn after signing (this should succeed as per current implementation).
        vm.prank(whale);
        bsafe.burn(whale, id, 1);

        // Check balance after burning.
        assertEq(bsafe.balanceOf(whale, id), 0);

        // Try to burn after signing (this should succeed as per current implementation).
        vm.prank(nani);
        bsafe.burn(nani, id, 1);

        // Check balance after burning.
        assertEq(bsafe.balanceOf(nani, id), 0);
    }

    function testBurnByApprovedOperator() public {
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        // Approve an operator.
        address operator = address(0x3);
        vm.prank(whale);
        bsafe.setApprovalForAll(operator, true);

        // Burn by the approved operator.
        vm.prank(operator);
        bsafe.burn(whale, id, 1);

        // Check balance after burning.
        assertEq(bsafe.balanceOf(whale, id), 0);
    }

    function testBurnFailByNonParty() public {
        // Create and sign a SAFE.
        vm.prank(nani);
        uint256 id = bsafe.send(LibString.toHexStringChecksummed(whale), "10000", "10000000");

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);
        vm.prank(whale);
        bsafe.sign(id);

        vm.expectRevert(); // Expect revert due to insufficient approval.
        // Try to burn as non-party (this should fail as per current implementation).
        bsafe.burn(whale, id, 1);

        // Check balance after.
        assertEq(bsafe.balanceOf(whale, id), 1);

        vm.expectRevert();
        bsafe.burn(nani, id, 1);

        // Check balance after burning.
        assertEq(bsafe.balanceOf(nani, id), 1);

        vm.prank(nani); // Expect success.
        bsafe.burn(nani, id, 1);
    }

    function testFund() public {
        address recipient = address(0x123);
        uint256 amount = 100 * 1e6; // 100 USDC.

        uint256 whaleBalanceBefore = IERC20(usdc).balanceOf(whale);
        uint256 recipientBalanceBefore = IERC20(usdc).balanceOf(recipient);

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);

        vm.prank(whale);
        bsafe.fund(LibString.toHexStringChecksummed(recipient), "100", bytes32(0));

        uint256 whaleBalanceAfter = IERC20(usdc).balanceOf(whale);
        uint256 recipientBalanceAfter = IERC20(usdc).balanceOf(recipient);

        assertEq(whaleBalanceBefore - whaleBalanceAfter, amount);
        assertEq(recipientBalanceAfter - recipientBalanceBefore, amount);
    }

    function testFundWithENS() public {
        string memory recipientENS = "nani.base.eth";
        uint256 amount = 100 * 1e6; // 100 USDC.

        uint256 whaleBalanceBefore = IERC20(usdc).balanceOf(whale);

        vm.prank(whale);
        IERC20(usdc).approve(address(bsafe), type(uint256).max);

        vm.prank(whale);
        bsafe.fund(recipientENS, "100", bytes32(0));

        uint256 whaleBalanceAfter = IERC20(usdc).balanceOf(whale);
        assertEq(whaleBalanceBefore - whaleBalanceAfter, amount);
    }

    function testFundFromETH() public {
        address recipient = address(0x123);
        uint256 ethAmount = 1 ether;
        uint256 usdcAmount = 2300 * 1e6; // Assuming 1 ETH = 2300 USDC.

        uint256 recipientBalanceBefore = IERC20(usdc).balanceOf(recipient);

        vm.prank(ethHolder);
        bsafe.fundFromETH{value: ethAmount}(
            LibString.toHexStringChecksummed(recipient), "2300", bytes32(0)
        );

        uint256 recipientBalanceAfter = IERC20(usdc).balanceOf(recipient);
        assertEq(recipientBalanceAfter - recipientBalanceBefore, usdcAmount);
    }

    function testFundFromETHWithENS() public {
        string memory recipientENS = "nani.base.eth";
        uint256 ethAmount = 1 ether;

        uint256 recipientBalanceBefore = IERC20(usdc).balanceOf(nani);

        vm.prank(whale);
        bsafe.fundFromETH{value: ethAmount}(recipientENS, "1000", bytes32(0));

        assertEq(whale.balance, 99 ether);
        assertTrue(recipientBalanceBefore + 1000 * 1e6 == IERC20(usdc).balanceOf(nani));
    }

    function testFundFromETHRefund() public {
        address recipient = address(0x123);
        uint256 ethAmount = 2 ether;
        uint256 usdcAmount = 1000 * 1e6; // We're only requesting 1000 USDC.

        uint256 recipientBalanceBefore = IERC20(usdc).balanceOf(recipient);
        uint256 whaleBalanceBeforeWeth = IERC20(WETH).balanceOf(whale);

        assertTrue(IERC20(WETH).balanceOf(address(bsafe)) == 0);

        vm.prank(whale);
        bsafe.fundFromETH{value: ethAmount}(
            LibString.toHexStringChecksummed(recipient), "1000", bytes32(0)
        );

        uint256 whaleBalanceAfterWeth = IERC20(WETH).balanceOf(whale);
        uint256 recipientBalanceAfter = IERC20(usdc).balanceOf(recipient);

        assertEq(recipientBalanceAfter - recipientBalanceBefore, usdcAmount);
        assertTrue(address(bsafe).balance == 0);
        assertTrue(IERC20(WETH).balanceOf(address(bsafe)) == 0);
        assertTrue(whaleBalanceAfterWeth > whaleBalanceBeforeWeth); // Check overpay refund.
    }
}

address constant WETH = 0x4200000000000000000000000000000000000006;

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function approve(address, uint256) external returns (bool);
}
