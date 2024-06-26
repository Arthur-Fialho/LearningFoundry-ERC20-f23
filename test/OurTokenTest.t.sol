// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployOurToken} from "../script/DeployOurToken.s.sol";
import {OurToken} from "../src/OurToken.sol";

contract OurTokenTest is Test {
    OurToken public ourToken;
    DeployOurToken public deployer;

    address bob = makeAddr("Bob");
    address alice = makeAddr("Alice");

    uint256 public constant STARTING_BALANCE = 1000 ether;

    function setUp() public {
        deployer = new DeployOurToken();
        ourToken = deployer.run();

        vm.prank(msg.sender);
        ourToken.transfer(bob, STARTING_BALANCE);
    }

    function testTotalSupply() public view {
        uint256 totalSupply = ourToken.totalSupply();
        assertEq(totalSupply, STARTING_BALANCE);
    }

    function testBobBalance() public view {
        assertEq(STARTING_BALANCE, ourToken.balanceOf(bob));
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(alice);
        ourToken.transferFrom(bob, alice, transferAmount);

        assertEq(ourToken.balanceOf(alice), transferAmount);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE - transferAmount);

        vm.expectRevert();
        ourToken.transferFrom(bob, alice, initialAllowance + 1);

        // Revoke allowance
        vm.prank(bob);
        ourToken.approve(alice, 0);
        assertEq(
            ourToken.allowance(bob, alice),
            0,
            "Allowance not revoked properly"
        );
    }

    function testTransferEvent() public {
        vm.prank(bob);
        uint256 transferAmount = 50;
        bool success = ourToken.transfer(alice, transferAmount);
        assertTrue(success, "Transfer should be successful");
    }

    function testTransferFailure() public {
        vm.prank(bob);
        uint256 insufficientBalance = STARTING_BALANCE + 1;
        vm.expectRevert();
        ourToken.transfer(bob, insufficientBalance);
    }

    function testTransferToZeroAddress() public {
        vm.expectRevert();
        ourToken.transfer(address(0), STARTING_BALANCE);
    }

    function testDecimals() public {
        uint8 decimals = ourToken.decimals();
        assertEq(decimals, 18, "Decimals should be set to 18");
    }

    function testSymbol() public {
        string memory symbol = ourToken.symbol();
        assertEq(symbol, "OT", "Symbol should be OT");
    }

    function testName() public {
        string memory name = ourToken.name();
        assertEq(name, "OurToken", "Name should be OurToken");
    }

    function testTransferWithInsufficientAllowance() public {
        uint256 transferAmount = 500;
        // Alice has no allowance from Bob
        vm.prank(alice);
        vm.expectRevert();
        ourToken.transferFrom(bob, alice, transferAmount);
    }

    function testApproveAndTransferFromZeroAmount() public {
        uint256 initialAllowance = 1000;
        // Bob approves Alice to spend tokens on her behalf
        vm.prank(bob);
        ourToken.approve(alice, initialAllowance);

        // Alice transfers zero amount from Bob's account
        vm.prank(alice);
        ourToken.transferFrom(bob, alice, 0);

        // Ensure balances remain unchanged
        assertEq(ourToken.balanceOf(alice), 0);
        assertEq(ourToken.balanceOf(bob), STARTING_BALANCE);

        // Ensure allowance is correctly updated
        assertEq(ourToken.allowance(bob, alice), initialAllowance);
    }
}
