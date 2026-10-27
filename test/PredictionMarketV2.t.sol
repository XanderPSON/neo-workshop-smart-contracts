// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PredictionMarketV2} from "../src/PredictionMarketV2.sol";
import {ERC20} from "../src/ERC20.sol";

/// @dev A fixed-supply token so these tests don't depend on how you customized MyToken.
contract V2TestToken is ERC20 {
    constructor() ERC20("V2 Test Token", "V2T", 1_000_000 ether) {}
}

/// @notice Spec for `vote()` in src/PredictionMarketV2.sol. The vote tests fail until
/// you implement it; the wiring test passes out of the box.
contract PredictionMarketV2Test is Test {
    PredictionMarketV2 internal market;
    V2TestToken internal token;

    address internal owner = address(this);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    uint256 internal marketId;

    function setUp() public {
        token = new V2TestToken();
        market = new PredictionMarketV2(owner, address(token));
        marketId = market.createMarket("Will our pod ship V2?");
        token.transfer(alice, 100 ether);
        token.transfer(bob, 100 ether);
    }

    function test_constructor_wiresTokenAndOwner() public view {
        assertEq(address(market.token()), address(token));
        assertEq(market.owner(), owner);
        assertEq(market.totalMarkets(), 1);
    }

    function test_vote_revert_withoutAllowance() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(PredictionMarketV2.InsufficientAllowance.selector, 10 ether, 0));
        market.vote(marketId, true, 10 ether);
    }

    function test_vote_revert_allowanceTooLow() public {
        vm.startPrank(alice);
        token.approve(address(market), 5 ether);
        vm.expectRevert(abi.encodeWithSelector(PredictionMarketV2.InsufficientAllowance.selector, 10 ether, 5 ether));
        market.vote(marketId, true, 10 ether);
        vm.stopPrank();
    }

    function test_vote_movesBalance() public {
        vm.startPrank(alice);
        token.approve(address(market), 10 ether);
        market.vote(marketId, true, 10 ether);
        vm.stopPrank();

        assertEq(token.balanceOf(alice), 90 ether);
        assertEq(token.balanceOf(address(market)), 10 ether);
    }

    function test_vote_updatesPools() public {
        vm.startPrank(alice);
        token.approve(address(market), 10 ether);
        market.vote(marketId, true, 10 ether);
        vm.stopPrank();

        vm.startPrank(bob);
        token.approve(address(market), 4 ether);
        market.vote(marketId, false, 4 ether);
        vm.stopPrank();

        (uint256 yesPool, uint256 noPool) = market.getOdds(marketId);
        assertEq(yesPool, 10 ether);
        assertEq(noPool, 4 ether);
        assertEq(market.amountVoted(marketId, alice), 10 ether);
        assertTrue(market.hasVoted(marketId, bob));
    }

    function test_vote_repeatedVotesAccumulate() public {
        vm.startPrank(alice);
        token.approve(address(market), 10 ether);
        market.vote(marketId, true, 3 ether);
        market.vote(marketId, true, 7 ether);
        vm.stopPrank();

        (uint256 yesPool,) = market.getOdds(marketId);
        assertEq(yesPool, 10 ether);
        assertEq(market.amountVoted(marketId, alice), 10 ether);
    }

    function test_vote_allowanceReturnsToZero() public {
        vm.startPrank(alice);
        token.approve(address(market), 10 ether);
        market.vote(marketId, true, 10 ether);
        vm.stopPrank();

        assertEq(token.allowance(alice, address(market)), 0);
    }

    function test_vote_revert_resolvedMarket() public {
        market.resolveMarket(marketId, true);

        vm.startPrank(alice);
        token.approve(address(market), 10 ether);
        vm.expectRevert(abi.encodeWithSelector(PredictionMarketV2.MarketAlreadyResolved.selector, marketId));
        market.vote(marketId, true, 10 ether);
        vm.stopPrank();
    }

    function test_vote_revert_zeroAmount() public {
        vm.prank(alice);
        vm.expectRevert(PredictionMarketV2.ZeroAmount.selector);
        market.vote(marketId, true, 0);
    }

    function test_vote_emitsVoted() public {
        vm.startPrank(alice);
        token.approve(address(market), 10 ether);
        vm.expectEmit(true, false, false, true, address(market));
        emit PredictionMarketV2.Voted(marketId, alice, true, 10 ether);
        market.vote(marketId, true, 10 ether);
        vm.stopPrank();
    }
}
