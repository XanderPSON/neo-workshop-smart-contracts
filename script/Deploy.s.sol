// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PredictionMarket} from "../src/PredictionMarket.sol";

/// @notice Deploy PredictionMarket V1 (ETH-based).
/// Usage: forge script Deploy --account dev --rpc-url https://sepolia.base.org --broadcast --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
contract Deploy is Script {
    function run() external {
        address deployer = msg.sender;
        vm.startBroadcast(deployer);

        PredictionMarket market = new PredictionMarket(deployer);
        console.log("PredictionMarket deployed to:", address(market));

        vm.stopBroadcast();
    }
}
