// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IPredictionMarket} from "../src/IPredictionMarket.sol";

/// @notice Reference implementation — Pari-Mutuel Prediction Market.
/// Winners split losers' tokens proportionally.
/// Part 1: Accepts ETH. Part 2: Upgrade to use ERC-20 token.
contract PredictionMarket is IPredictionMarket {
    // === TYPES & STRUCTS ===
    struct Market {
        string question; // e.g., "Will it rain tomorrow?"
        uint256 yesPool; // Total wei staked on YES
        uint256 noPool; // Total wei staked on NO
        bool resolved; // Has the market been resolved?
        bool outcome; // true = YES won, false = NO won
    }

    // === STORAGE VARIABLES ===
    address public owner;

    Market[] public markets;

    // Nested mapping: marketId -> voter -> total amount staked
    mapping(uint256 => mapping(address => uint256)) public amountVoted;

    // === MODIFIERS ===
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender, owner);
        _;
    }

    // === CONSTRUCTOR ===
    constructor(address owner_) {
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
        Market storage m = markets[marketId];
        return (m.question, m.yesPool, m.noPool, m.resolved, m.outcome);
    }

    function hasVoted(uint256 marketId, address voter) external view returns (bool) {
        return amountVoted[marketId][voter] > 0;
    }

    // === WRITE FUNCTIONS ===
    function createMarket(string calldata question) external onlyOwner returns (uint256 marketId) {
        marketId = markets.length;
        markets.push(Market({question: question, yesPool: 0, noPool: 0, resolved: false, outcome: false}));
        emit MarketCreated(marketId, question);
    }

    function vote(uint256 marketId, bool side) external payable {
        Market storage m = markets[marketId];
        uint256 amount = msg.value;

        // CHECKS
        if (m.resolved) revert MarketAlreadyResolved(marketId);
        if (amount == 0) revert ZeroAmount();

        // EFFECTS
        amountVoted[marketId][msg.sender] += amount;
        if (side) {
            m.yesPool += amount;
        } else {
            m.noPool += amount;
        }

        // INTERACTIONS (ETH is already in contract via msg.value; no external call needed)
        emit Voted(marketId, msg.sender, side, amount);
    }

    function resolveMarket(uint256 marketId, bool outcome) external onlyOwner {
        Market storage m = markets[marketId];
        if (m.resolved) revert MarketAlreadyResolved(marketId);

        m.resolved = true;
        m.outcome = outcome;

        emit MarketResolved(marketId, outcome);
    }
}
