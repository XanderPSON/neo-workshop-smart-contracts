// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";
import {IERC20} from "../src/IERC20.sol";

/// @notice Tests for YOUR token. Run: forge test --match-contract MyTokenTest -vvv
///
/// The `test_mint_*` tests FAIL until you implement `mint` in src/MyToken.sol.
/// That's expected: make them pass.
contract MyTokenTest is Test {
    MyToken internal token;

    address internal owner = address(this);
    address internal alice = address(0xA11CE);

    function setUp() public {
        token = new MyToken();
    }

    // --- Inherited from ERC20.sol (passes out of the box) ---

    function test_deployerOwnsInitialSupply() public view {
        assertEq(token.owner(), owner);
        assertGt(token.totalSupply(), 0, "pick an initial supply greater than zero");
        assertEq(token.balanceOf(owner), token.totalSupply());
    }

    function test_hasNameAndSymbol() public view {
        assertGt(bytes(token.name()).length, 0);
        assertGt(bytes(token.symbol()).length, 0);
    }

    // --- Your behavior: owner-only mint (fails until you implement it) ---

    function test_mint_ownerCanMint() public {
        uint256 supplyBefore = token.totalSupply();

        vm.expectEmit(true, true, false, true);
        emit IERC20.Transfer(address(0), alice, 500 ether);
        token.mint(alice, 500 ether);

        assertEq(token.balanceOf(alice), 500 ether);
        assertEq(token.totalSupply(), supplyBefore + 500 ether);
    }

    function test_mint_revert_notOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(MyToken.NotOwner.selector, alice, owner));
        token.mint(alice, 1 ether);
    }
}
