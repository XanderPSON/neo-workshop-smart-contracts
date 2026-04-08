// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PredictionMarket} from "../src/PredictionMarket.sol";
import {IPredictionMarket} from "../src/IPredictionMarket.sol";

contract PredictionMarketTest is Test {
    PredictionMarket internal market;

    address internal owner = address(this);
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);
    address internal eve = address(0xE11E);

    function setUp() public {
        market = new PredictionMarket(owner);
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(eve, 10 ether);
    }

    function test_createMarket_success() public {
        uint256 marketId = market.createMarket("Will ETH close green today?");
        assertEq(marketId, 0);
        assertEq(market.totalMarkets(), 1);

        (string memory question, uint256 yesPool, uint256 noPool, bool resolved, bool outcome) =
            market.markets(marketId);
        assertEq(question, "Will ETH close green today?");
        assertEq(yesPool, 0);
        assertEq(noPool, 0);
        assertEq(resolved, false);
        assertEq(outcome, false);
    }

    function test_createMarket_revert_onlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IPredictionMarket.NotOwner.selector, alice, owner));
        market.createMarket("Unauthorized market");
    }

    function test_vote_success_yes() public {
        uint256 marketId = market.createMarket("Will it rain tomorrow?");

        vm.prank(alice);
        market.vote{value: 1 ether}(marketId, true);

        (uint256 yesPool, uint256 noPool) = market.getOdds(marketId);
        assertEq(yesPool, 1 ether);
        assertEq(noPool, 0);
        assertTrue(market.hasVoted(marketId, alice));
    }

    function test_vote_success_no() public {
        uint256 marketId = market.createMarket("Will it rain tomorrow?");

        vm.prank(bob);
        market.vote{value: 2 ether}(marketId, false);

        (uint256 yesPool, uint256 noPool) = market.getOdds(marketId);
        assertEq(yesPool, 0);
        assertEq(noPool, 2 ether);
        assertTrue(market.hasVoted(marketId, bob));
    }

    function test_vote_revert_ifResolved() public {
        uint256 marketId = market.createMarket("Will BTC break ATH?");
        market.resolveMarket(marketId, true);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IPredictionMarket.MarketAlreadyResolved.selector, marketId));
        market.vote{value: 1 ether}(marketId, true);
    }

    function test_vote_allowsMultipleVotes() public {
        uint256 marketId = market.createMarket("Will BTC break ATH?");

        vm.prank(alice);
        market.vote{value: 1 ether}(marketId, true);

        vm.prank(alice);
        market.vote{value: 2 ether}(marketId, true);

        (uint256 yesPool,) = market.getOdds(marketId);
        assertEq(yesPool, 3 ether);
        assertTrue(market.hasVoted(marketId, alice));
    }

    function test_vote_revert_ifZeroValue() public {
        uint256 marketId = market.createMarket("Will gas be below 20 gwei?");

        vm.prank(alice);
        vm.expectRevert(IPredictionMarket.ZeroAmount.selector);
        market.vote{value: 0}(marketId, true);
    }

    function test_resolveMarket_success() public {
        uint256 marketId = market.createMarket("Will L2 TPS grow this month?");
        market.resolveMarket(marketId, true);

        (,,, bool resolved, bool outcome) = market.markets(marketId);
        assertTrue(resolved);
        assertTrue(outcome);
    }

    function test_resolveMarket_revert_onlyOwner() public {
        uint256 marketId = market.createMarket("Will L2 TPS grow this month?");

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IPredictionMarket.NotOwner.selector, alice, owner));
        market.resolveMarket(marketId, true);
    }

    function test_resolveMarket_revert_alreadyResolved() public {
        uint256 marketId = market.createMarket("Will L2 TPS grow this month?");
        market.resolveMarket(marketId, false);

        vm.expectRevert(abi.encodeWithSelector(IPredictionMarket.MarketAlreadyResolved.selector, marketId));
        market.resolveMarket(marketId, true);
    }

    function test_getOdds_returnsCorrectValuesAfterVotes() public {
        uint256 marketId = market.createMarket("Will there be 3 Fed cuts?");

        vm.prank(alice);
        market.vote{value: 1.5 ether}(marketId, true);

        vm.prank(bob);
        market.vote{value: 0.5 ether}(marketId, true);

        vm.prank(eve);
        market.vote{value: 3 ether}(marketId, false);

        (uint256 yesPool, uint256 noPool) = market.getOdds(marketId);
        assertEq(yesPool, 2 ether);
        assertEq(noPool, 3 ether);
    }

    function test_totalMarkets_incrementsCorrectly() public {
        assertEq(market.totalMarkets(), 0);

        market.createMarket("Q1");
        assertEq(market.totalMarkets(), 1);

        market.createMarket("Q2");
        assertEq(market.totalMarkets(), 2);

        market.createMarket("Q3");
        assertEq(market.totalMarkets(), 3);
    }
}
