// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

/// @notice Deploy your custom ERC-20 token (src/MyToken.sol).
/// Usage: forge script script/DeployToken.s.sol --private-key "$PRIVATE_KEY" --rpc-url "$BASE_SEPOLIA_RPC" --broadcast
contract DeployToken is Script {
    function run() external {
        vm.startBroadcast();

        MyToken token = new MyToken();
        console.log("Token deployed to:", address(token));
        console.log("Name / symbol:", token.name(), token.symbol());

        vm.stopBroadcast();
    }
}
