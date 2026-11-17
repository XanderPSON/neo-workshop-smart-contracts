// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "./IERC20.sol";

/// @title ERC20 — complete, hand-written ERC-20 base (no external dependencies)
/// @notice Reference: https://eips.ethereum.org/EIPS/eip-20
///
/// This contract is SUPPLIED and fully tested (see test/ERC20.t.sol). You do not
/// need to change it. Read it side by side with `IERC20.sol`: every function in the
/// interface is implemented here.
///
/// Your token lives in `src/MyToken.sol`, which inherits from this contract,
/// picks a name/symbol/supply, and adds one behavior of your own.
///
/// The constructor mints `initialSupply_` to the deployer (`msg.sender`).
/// `_mint` is `internal` so child contracts (like MyToken) can create new tokens.
contract ERC20 is IERC20 {
    // === STATE VARIABLES ===
    string public name;
    string public symbol;
    // forge-lint: disable-next-line(screaming-snake-case-const)
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // === ERRORS ===
    error InsufficientBalance(uint256 requested, uint256 available);
    error InsufficientAllowance(uint256 requested, uint256 available);

    // === CONSTRUCTOR ===
    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) {
        name = name_;
        symbol = symbol_;
        _mint(msg.sender, initialSupply_);
    }

    // === EXTERNAL FUNCTIONS ===

    /// @notice Move `amount` tokens from the caller to `to`.
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Let `spender` move up to `amount` of the caller's tokens.
    /// This is step 1 of the allowance pattern (approve, then transferFrom).
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// @notice Move `amount` tokens from `from` to `to` using the caller's allowance.
    /// This is step 2 of the allowance pattern: a contract (like PredictionMarket V2)
    /// pulls tokens a user has already approved.
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance(amount, currentAllowance);
        allowance[from][msg.sender] = currentAllowance - amount;
        _transfer(from, to, amount);
        return true;
    }

    // === INTERNAL HELPERS (available to child contracts) ===

    /// @dev Move tokens between accounts, checking the sender's balance.
    function _transfer(address from, address to, uint256 amount) internal {
        uint256 fromBalance = balanceOf[from];
        if (fromBalance < amount) revert InsufficientBalance(amount, fromBalance);
        balanceOf[from] = fromBalance - amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    /// @dev Create `amount` new tokens for `to`. Emits Transfer from the zero address,
    /// which is how wallets and explorers recognize a mint.
    function _mint(address to, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
