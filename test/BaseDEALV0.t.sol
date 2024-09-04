// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import {Sections} from "../src/DEAL/Sections.sol";
import {ISections, DEAL, BaseDEALV0} from "../src/DEAL/BaseDEALV0.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

import {LibString} from "@solady/src/utils/LibString.sol";
import {SignatureCheckerLib} from "@solady/src/utils/SignatureCheckerLib.sol";

import "../lib/forge-std/src/console.sol";

contract BaseDEALV0Test is Test {
    BaseDEALV0 bdeal;
    ISections sections;

    address constant z0r0z = 0x1C0Aa8cCD568d90d61659F060D1bFb1e6f855A20;
    address constant nani = 0x999657A41753b8E69C66e7b1A8E37d513CB44E1C;

    address constant whale = 0x0B0A5886664376F59C351ba3f598C8A8B4D0A6f3;
    address constant usdc = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    function setUp() public payable {
        vm.createSelectFork(vm.rpcUrl("base"));
        sections = ISections(address(new Sections()));
        bdeal = new BaseDEALV0(sections);
        vm.label(address(bdeal), "BDEAL");
        vm.deal(nani, 1 ether);
        vm.deal(whale, 100 ether);
        deal(usdc, whale, 1000000e6);
    }

    function testLogURI() public payable {
        console.log(bdeal.uri(0));
    }
}

address constant WETH = 0x4200000000000000000000000000000000000006;

interface IERC20 {
    function balanceOf(address) external returns (uint256);
    function approve(address, uint256) external returns (bool);
}
