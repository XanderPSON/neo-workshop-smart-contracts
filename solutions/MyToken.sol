// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "../src/IERC20.sol";

/// @notice Reference ERC-20 implementation for participants who fall behind in Part 2.
/// Implements the full IERC20 interface with balance checks and allowance tracking.
contract MyToken is IERC20 {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    error InsufficientBalance(uint256 requested, uint256 available);
    error InsufficientAllowance(uint256 requested, uint256 available);

    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) {
        name = name_;
        symbol = symbol_;
        totalSupply = initialSupply_;
        balanceOf[msg.sender] = initialSupply_;
        emit Transfer(address(0), msg.sender, initialSupply_);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance(amount, balanceOf[msg.sender]);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (balanceOf[from] < amount) revert InsufficientBalance(amount, balanceOf[from]);
        if (allowance[from][msg.sender] < amount) revert InsufficientAllowance(amount, allowance[from][msg.sender]);
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
