// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Rescue} from "../script/Rescue.s.sol";
import {PredictionMarket as PredictionMarketV1} from "../solutions/PredictionMarket.sol";
import {PredictionMarket as PredictionMarketV2} from "../solutions/PredictionMarketV2.sol";
import {MyToken as RescueToken} from "../solutions/MyToken.sol";

/// @notice Verifies the rescue deployment wiring and that the reference V2 works
/// end to end with the reference token via the allowance pattern.
contract RescueTest is Test {
    Rescue internal rescue;
    address internal alice = address(0xA11CE);

    function setUp() public {
        rescue = new Rescue();
    }

    function test_deployAll_wiresContracts() public {
        address deployer = address(0xD00D);
        Rescue.Deployment memory d = rescue.deployAll(deployer);

        assertEq(d.deployer, deployer);
        assertEq(PredictionMarketV1(d.v1).owner(), deployer);
        assertEq(PredictionMarketV2(d.v2).owner(), deployer);
        assertEq(address(PredictionMarketV2(d.v2).token()), d.token);
        assertEq(RescueToken(d.token).totalSupply(), 1_000_000 ether);
    }

    function test_v2_votesWithToken() public {
        RescueToken token = new RescueToken("T", "T", 100 ether);
        PredictionMarketV2 market = new PredictionMarketV2(address(this), address(token));
        uint256 id = market.createMarket("Will it ship?");

        token.transfer(alice, 10 ether);
        vm.startPrank(alice);
        token.approve(address(market), 4 ether);
        market.vote(id, true, 4 ether);
        vm.stopPrank();

        (uint256 yesPool,) = market.getOdds(id);
        assertEq(yesPool, 4 ether);
        assertEq(token.balanceOf(address(market)), 4 ether);
        assertEq(token.allowance(alice, address(market)), 0);
    }

    function test_run_simulatesOnAnvilChain() public {
        vm.setEnv("PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
        Rescue.Deployment memory d = rescue.run();
        assertEq(PredictionMarketV1(d.v1).owner(), d.deployer);
        assertEq(RescueToken(d.token).balanceOf(d.deployer), 1_000_000 ether);
        assertEq(RescueToken(d.token).owner(), d.deployer);
    }
}
