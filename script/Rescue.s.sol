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

        vm.startBroadcast(pk);
        d = deployAll(vm.addr(pk));
        vm.stopBroadcast();

        logDeployment(d);
    }

    /// @dev Separate from run() so tests can exercise the wiring without env vars.
    function deployAll(address deployer) public returns (Deployment memory d) {
        d.deployer = deployer;
        d.v1 = address(new PredictionMarketV1(deployer));
        d.token = address(new RescueToken("NEO Rescue Token", "RESCUE", 1_000_000 ether));
        d.v2 = address(new PredictionMarketV2(deployer, d.token));
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
