// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "../src/ERC20.sol";

/// @notice Reference token for participants who fall behind in Part 2.
/// Inherits the supplied ERC-20 base and adds an owner-only `mint`.
/// `script/Rescue.s.sol` deploys this contract.
contract MyToken is ERC20 {
    address public owner;

    error NotOwner(address sender, address owner);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply_)
        ERC20(name_, symbol_, initialSupply_)
    {
        owner = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        if (msg.sender != owner) revert NotOwner(msg.sender, owner);
        _mint(to, amount);
    }
}
