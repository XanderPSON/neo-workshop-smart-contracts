// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PredictionMarket as PredictionMarketV1} from "../solutions/PredictionMarket.sol";
import {PredictionMarket as PredictionMarketV2} from "../solutions/PredictionMarketV2.sol";
import {MyToken as RescueToken} from "../solutions/MyToken.sol";

/// @notice Catch-up deploy for a participant who is behind.
/// Deploys the REFERENCE PredictionMarket V1 (ETH), the reference ERC-20 token,
/// and PredictionMarket V2 (wired to that token), then prints every address.
///
/// Market 0 is created on V1 and V2 with QUESTION (env, optional).
/// Usage:  make rescue          (reads PRIVATE_KEY and BASE_SEPOLIA_RPC from env or .env)
/// Dry run: make rescue-dry     (simulates only, nothing is sent)
contract Rescue is Script {
    uint256 internal constant BASE_SEPOLIA = 84532;
    uint256 internal constant ANVIL = 31337;

    struct Deployment {
        address deployer;
        address v1;
        address token;
        address v2;
    }

    function run() external returns (Deployment memory d) {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        require(block.chainid == BASE_SEPOLIA || block.chainid == ANVIL, "Rescue: testnet only (Base Sepolia 84532)");

        string memory question = vm.envOr("QUESTION", string("Will our pod ship a paid API by the end of Day 2?"));

        vm.startBroadcast(pk);
        d = deployAll(vm.addr(pk), question);
        vm.stopBroadcast();

        logDeployment(d);
    }

    /// @dev Separate from run() so tests can exercise the wiring without env vars.
    /// Seeds market 0 on V1 and V2 with `question` so the Day 2 dashboard has something to show.
    function deployAll(address deployer, string memory question) public returns (Deployment memory d) {
        d.deployer = deployer;
        PredictionMarketV1 v1 = new PredictionMarketV1(deployer);
        d.v1 = address(v1);
        d.token = address(new RescueToken("NEO Rescue Token", "RESCUE", 1_000_000 ether));
        PredictionMarketV2 v2 = new PredictionMarketV2(deployer, d.token);
        d.v2 = address(v2);
        v1.createMarket(question);
        v2.createMarket(question);
    }

    function logDeployment(Deployment memory d) internal view {
        console.log("");
        console.log("================ RESCUE DEPLOYMENT ================");
        console.log("Chain ID              ", block.chainid);
        console.log("Deployer / owner      ", d.deployer);
        console.log("PredictionMarket V1   ", d.v1);
        console.log("Token (ERC-20 RESCUE) ", d.token);
        console.log("PredictionMarket V2   ", d.v2);
        console.log("===================================================");
        if (block.chainid == BASE_SEPOLIA) {
            console.log("Explorer: https://sepolia.basescan.org/address/<address>");
        }
        console.log("Copy these addresses into your notes / frontend .env.");
    }
}
