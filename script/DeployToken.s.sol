// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

/// @notice Deploy your custom ERC-20 token.
/// Participants: replace "MyToken" import with your own contract name.
/// Usage: forge script DeployToken --account dev --rpc-url https://sepolia.base.org --broadcast --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
contract DeployToken is Script {
    function run() external {
        vm.startBroadcast();

        // TODO: Deploy your token here. Example:
        // MyToken token = new MyToken("PodCoin", "POD", 1_000_000 ether);
        // console.log("Token deployed to:", address(token));

        vm.stopBroadcast();
    }
}
