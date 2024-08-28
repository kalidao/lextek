// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Section2} from "../src/Section2.sol";
import {Section3} from "../src/Section3.sol";
import {Section4} from "../src/Section4.sol";
import {Section5} from "../src/Section5.sol";
import {ISections, SAFE, BaseSAFEV0} from "../src/BaseSAFEV0.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

import {LibString} from "@solady/src/utils/LibString.sol";

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

    function setUp() public payable {
        vm.createSelectFork(vm.rpcUrl("base"));
        section2 = ISections(address(new Section2()));
        section3 = ISections(address(new Section3()));
        section4 = ISections(address(new Section4()));
        section5 = ISections(address(new Section5()));
        bsafe = new BaseSAFEV0(section2, section3, section4, section5);
    }

    function testLogURI() public payable {
        console.log(bsafe.uri(0));
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
}

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function approve(address, uint256) external returns (bool);
}
