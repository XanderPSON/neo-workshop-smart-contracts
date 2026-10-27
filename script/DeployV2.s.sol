// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {PredictionMarketV2} from "../src/PredictionMarketV2.sol";

/// @notice Deploy PredictionMarket V2 (ERC-20 version) wired to your token.
/// Reads WORKSHOP_TOKEN_ADDRESS from your shell or .env; you (msg.sender) become the owner.
/// Usage: forge script script/DeployV2.s.sol --private-key "$PRIVATE_KEY" --rpc-url "$BASE_SEPOLIA_RPC" --broadcast
contract DeployV2 is Script {
    function run() external returns (PredictionMarketV2 market) {
        address tokenAddress = vm.envAddress("WORKSHOP_TOKEN_ADDRESS");

        vm.startBroadcast();
        market = new PredictionMarketV2(msg.sender, tokenAddress);
        vm.stopBroadcast();

        console.log("PredictionMarket V2 deployed to:", address(market));
        console.log("Takes bets in token:", tokenAddress);
    }
}
