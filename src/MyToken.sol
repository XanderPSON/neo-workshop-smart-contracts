// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "./ERC20.sol";

/// @notice YOUR TOKEN. It inherits the complete ERC-20 base in `src/ERC20.sol`,
/// so transfer / approve / transferFrom already work.
///
/// Your tasks:
///   1. Customize: change the name, symbol, and initial supply below.
///   2. Add one behavior: implement `mint` so ONLY the owner can create new tokens.
///      Run `forge test --match-contract MyTokenTest -vvv`. The mint tests fail
///      until you finish the TODO, then they pass.
///   3. Deploy it to Base Sepolia with `script/DeployToken.s.sol`.
///
/// Prefer a supply cap instead? See "Alternative behavior" in the README.
contract MyToken is ERC20 {
    // === STATE VARIABLES ===
    address public owner;

    // === ERRORS ===
    error NotOwner(address sender, address owner);

    // === CONSTRUCTOR ===
    // TODO (customize): pick your own name, symbol, and initial supply.
    // `1_000_000 ether` means 1,000,000 tokens with 18 decimals.
    constructor() ERC20("MyToken", "MTK", 1_000_000 ether) {
        owner = msg.sender;
    }

    // === YOUR BEHAVIOR ===

    /// @notice Create `amount` new tokens for `to`. Only the owner may call this.
    function mint(address to, uint256 amount) external {
        // TODO: Revert with NotOwner(msg.sender, owner) if the caller is not the owner.
        // TODO: Call the inherited `_mint(to, amount)` helper from ERC20.sol.
        revert("Not implemented");
    }
}
