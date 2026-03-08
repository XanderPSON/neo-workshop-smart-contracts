// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Starter contract for ERC-20 Token.
/// Reference: https://eips.ethereum.org/EIPS/eip-20
/// Part 2: Implement a custom token and integrate it with your Prediction Market.
contract ERC20 {
    // === STATE VARIABLES ===
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // === EVENTS ===
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // === ERRORS ===
    error InsufficientBalance(uint256 requested, uint256 available);
    error InsufficientAllowance(uint256 requested, uint256 available);

    // === CONSTRUCTOR ===
    // TODO: Accept name_, symbol_, and initialSupply_ as constructor arguments.
    // Mint the initial supply to msg.sender.
    constructor(string memory name_, string memory symbol_, uint256 initialSupply_) {
        name = name_;
        symbol = symbol_;
        totalSupply = initialSupply_;
        balanceOf[msg.sender] = initialSupply_;
        emit Transfer(address(0), msg.sender, initialSupply_);
    }

    // === FUNCTIONS ===

    /// @notice Transfer tokens to another address.
    // TODO: Implement transfer. Check sender balance, update balances, emit Transfer.
    function transfer(address to, uint256 amount) external returns (bool) {
        // Your implementation here
        return false;
    }

    /// @notice Approve a spender to transfer tokens on your behalf.
    // TODO: Implement approve. Set allowance, emit Approval.
    function approve(address spender, uint256 amount) external returns (bool) {
        // Your implementation here
        return false;
    }

    /// @notice Transfer tokens from one address to another (requires prior approval).
    // TODO: Implement transferFrom. Check balance AND allowance, update both, emit Transfer.
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        // Your implementation here
        return false;
    }
}
