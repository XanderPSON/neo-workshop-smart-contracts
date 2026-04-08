// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IPredictionMarket} from "./IPredictionMarket.sol";

/// @notice Pari-Mutuel Prediction Market — YOUR IMPLEMENTATION.
/// Winners split losers' tokens proportionally.
/// Part 1: Accepts ETH. Part 2: Upgrade to use ERC-20 token.
///
/// Your task: implement every function defined in IPredictionMarket.
/// The interface file (src/IPredictionMarket.sol) is your spec — read it first.
/// Run `forge test` to verify your implementation (all tests should pass).
///
/// Hints:
///   - Define a `Market` struct with: question, yesPool, noPool, resolved, outcome
///   - Use a `Market[]` array and a nested mapping to track each voter's cumulative stake
///   - The constructor should accept an `owner_` address
///   - Use the CEI (Checks-Effects-Interactions) pattern in `vote()`
///   - Use the custom errors defined in IPredictionMarket (not require strings)
contract PredictionMarket is IPredictionMarket {
    // === TYPES & STRUCTS ===
    struct Market {
        string question;       // e.g., "Will it rain tomorrow?"
        uint256 yesPool;       // Total wei staked on YES
        uint256 noPool;        // Total wei staked on NO
        bool resolved;         // Has the market been resolved?
        bool outcome;          // true = YES won, false = NO won
    }

    // === STORAGE VARIABLES ===
    address public owner;
    Market[] public markets;
    // Nested mapping: marketId -> voter -> total amount staked
    mapping(uint256 => mapping(address => uint256)) public amountVoted;

    // === MODIFIERS ===
    // TODO: Define an onlyOwner modifier that reverts with NotOwner if msg.sender != owner

    // === CONSTRUCTOR ===
    constructor(address owner_) {
        // TODO: Set the owner
        owner = owner_;
    }

    // === READ FUNCTIONS ===

    function totalMarkets() external view returns (uint256) {
        // TODO: Return the number of markets created
        revert("Not implemented");
    }

    function getOdds(uint256 marketId) external view returns (uint256 yesPool, uint256 noPool) {
        // TODO: Return the yesPool and noPool for the given market
        revert("Not implemented");
    }

    function getMarket(uint256 marketId)
        external
        view
        returns (string memory question, uint256 yesPool, uint256 noPool, bool resolved, bool outcome)
    {
        // TODO: Return all fields of the given market
        revert("Not implemented");
    }

    // === WRITE FUNCTIONS ===

    function createMarket(string calldata question) external returns (uint256 marketId) {
        // TODO: Only owner can create markets
        // TODO: Push a new Market to the array and emit MarketCreated
        revert("Not implemented");
    }

    function hasVoted(uint256 marketId, address voter) external view returns (bool) {
        // TODO: Return true if the voter has staked any amount on this market
        revert("Not implemented");
    }

    function vote(uint256 marketId, bool side) external payable {
        // TODO: Follow the CEI pattern:
        //   CHECKS  — market not resolved, amount > 0
        //   EFFECTS — track voter's cumulative stake, update pool
        //   INTERACTIONS — emit Voted event
        revert("Not implemented");
    }

    function resolveMarket(uint256 marketId, bool outcome) external {
        // TODO: Only owner can resolve
        // TODO: Market must not already be resolved
        // TODO: Set resolved = true and outcome, emit MarketResolved
        revert("Not implemented");
    }
}
