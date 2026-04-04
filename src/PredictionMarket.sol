// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IPredictionMarket} from "./IPredictionMarket.sol";

/// @notice Pari-Mutuel Prediction Market — YOUR IMPLEMENTATION.
/// Winners split losers' tokens proportionally.
/// Part 1: Accepts ETH. Part 2: Upgrade to use ERC-20 token.
///
/// Your task: implement every function defined in IPredictionMarket.
/// The interface file (src/IPredictionMarket.sol) is your spec — read it first.
/// Run `forge test` to verify your implementation (all 12 tests should pass).
///
/// Hints:
///   - Define a `Market` struct with: question, yesPool, noPool, resolved, outcome
///   - Use a `Market[]` array and a nested mapping for vote tracking
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
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // === MODIFIERS ===
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender, owner);
        _;
    }

    // === CONSTRUCTOR ===
    constructor(address owner_) {
        // TODO: Set the owner
        owner = owner_;
    }

    // === READ FUNCTIONS ===
    function totalMarkets() external view returns (uint256) {
        return markets.length;
    }

    function getOdds(uint256 marketId) external view returns (uint256 yesPool, uint256 noPool) {
        Market storage m = markets[marketId];
        return (m.yesPool, m.noPool);
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
    function createMarket(string calldata question) external onlyOwner returns (uint256 marketId) {
        marketId = markets.length;
        markets.push(Market({
            question: question,
            yesPool: 0,
            noPool: 0,
            resolved: false,
            outcome: false
        }));
        emit MarketCreated(marketId, question);
    }

    function vote(uint256 marketId, bool side) external payable {
        // CHECKS
        Market storage m = markets[marketId];
        if (m.resolved) revert MarketAlreadyResolved(marketId);
        if (hasVoted[marketId][msg.sender]) revert AlreadyVoted(marketId, msg.sender);
        if (msg.value == 0) revert ZeroAmount();

        // EFFECTS
        hasVoted[marketId][msg.sender] = true;
        if (side) {
            m.yesPool += msg.value;
        } else {
            m.noPool += msg.value;
        }

        // INTERACTIONS
        emit Voted(marketId, msg.sender, side, msg.value);
    }

    function resolveMarket(uint256 marketId, bool outcome) external onlyOwner {
        Market storage m = markets[marketId];
        if (m.resolved) revert MarketAlreadyResolved(marketId);

        m.resolved = true;
        m.outcome = outcome;

        emit MarketResolved(marketId, outcome);
    }
}
