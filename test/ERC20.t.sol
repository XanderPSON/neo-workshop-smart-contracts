// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "../src/ERC20.sol";
import {IERC20} from "../src/IERC20.sol";

/// @notice Tests for the supplied ERC-20 base. These pass out of the box.
/// If you do the stretch (write transfer/approve/transferFrom yourself), these
/// are the tests your implementation must pass.
contract ERC20Test is Test {
    ERC20 internal token;

    address internal deployer = address(this);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    uint256 internal constant SUPPLY = 1_000_000 ether;

    function setUp() public {
        token = new ERC20("Test Token", "TEST", SUPPLY);
    }

    function test_constructor_setsMetadataAndMintsToDeployer() public view {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), SUPPLY);
        assertEq(token.balanceOf(deployer), SUPPLY);
    }

    function test_constructor_emitsMintTransfer() public {
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(address(0), deployer, SUPPLY);
        new ERC20("Test Token", "TEST", SUPPLY);
    }

    function test_transfer_movesBalance() public {
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(deployer, alice, 100 ether);
        assertTrue(token.transfer(alice, 100 ether));

        assertEq(token.balanceOf(alice), 100 ether);
        assertEq(token.balanceOf(deployer), SUPPLY - 100 ether);
        assertEq(token.totalSupply(), SUPPLY);
    }

    function test_transfer_revert_insufficientBalance() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ERC20.InsufficientBalance.selector, 1 ether, 0));
        token.transfer(bob, 1 ether);
    }

    function test_approve_setsAllowance() public {
        vm.expectEmit(true, true, false, true);
        emit IERC20.Approval(deployer, alice, 50 ether);
        assertTrue(token.approve(alice, 50 ether));
        assertEq(token.allowance(deployer, alice), 50 ether);

        token.approve(alice, 10 ether);
        assertEq(token.allowance(deployer, alice), 10 ether);
    }

    function test_transferFrom_spendsAllowance() public {
        token.approve(alice, 50 ether);

        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(deployer, bob, 30 ether);
        assertTrue(token.transferFrom(deployer, bob, 30 ether));

        assertEq(token.balanceOf(bob), 30 ether);
        assertEq(token.balanceOf(deployer), SUPPLY - 30 ether);
        assertEq(token.allowance(deployer, alice), 20 ether);
    }

    function test_transferFrom_revert_insufficientAllowance() public {
        token.approve(alice, 10 ether);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(ERC20.InsufficientAllowance.selector, 11 ether, 10 ether));
        token.transferFrom(deployer, bob, 11 ether);
    }

    function test_transferFrom_revert_insufficientBalance() public {
        token.transfer(alice, 5 ether);
        vm.prank(alice);
        token.approve(bob, 100 ether);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(ERC20.InsufficientBalance.selector, 6 ether, 5 ether));
        token.transferFrom(alice, bob, 6 ether);
    }

    function testFuzz_transfer_conservesSupply(uint256 amount) public {
        amount = bound(amount, 0, SUPPLY);
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice) + token.balanceOf(deployer), SUPPLY);
    }
}
