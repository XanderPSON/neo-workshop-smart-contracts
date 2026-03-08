// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PredictionMarket} from "../src/PredictionMarket.sol";

/// @notice Deploy PredictionMarket V2 (ERC-20 token version).
/// Requires a deployed ERC-20 token address as constructor arg.
/// Usage: forge script DeployV2 --account dev --rpc-url https://sepolia.base.org --broadcast --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
contract DeployV2 is Script {
    function run() external {
        vm.startBroadcast();

        // TODO: Replace with your deployed ERC-20 token address
        // address tokenAddress = 0x...;
        // PredictionMarket market = new PredictionMarket(msg.sender, tokenAddress);
        // console.log("PredictionMarket V2 deployed to:", address(market));

        vm.stopBroadcast();
    }
}
