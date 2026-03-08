// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "../src/IERC20.sol";

/// @notice Reference implementation — Pari-Mutuel Prediction Market V2 (ERC-20).
/// Upgraded from V1 (ETH) to accept an ERC-20 token via the allowance pattern.
/// Constructor accepts owner_ and token_; vote() uses transferFrom instead of msg.value.
contract PredictionMarket {
    struct Market {
        string question;
        uint256 yesPool;
        uint256 noPool;
        bool resolved;
        bool outcome;
    }

    address public owner;
    IERC20 public token;
    Market[] public markets;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    event MarketCreated(uint256 indexed marketId, string question);
    event Voted(uint256 indexed marketId, address voter, bool side, uint256 amount);
    event MarketResolved(uint256 indexed marketId, bool outcome);

    error NotOwner(address sender, address owner);
    error MarketAlreadyResolved(uint256 marketId);
    error AlreadyVoted(uint256 marketId, address voter);
    error ZeroAmount();
    error InsufficientAllowance(uint256 amount, uint256 allowance);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender, owner);
        _;
    }

    constructor(address owner_, address token_) {
        owner = owner_;
        token = IERC20(token_);
    }

    function totalMarkets() external view returns (uint256) {
        return markets.length;
    }

    function getOdds(uint256 marketId) external view returns (uint256 yesPool, uint256 noPool) {
        Market storage m = markets[marketId];
        return (m.yesPool, m.noPool);
    }

    function createMarket(string calldata question) external onlyOwner returns (uint256 marketId) {
        marketId = markets.length;
        markets.push(Market({question: question, yesPool: 0, noPool: 0, resolved: false, outcome: false}));
        emit MarketCreated(marketId, question);
    }

    function vote(uint256 marketId, bool side, uint256 amount) external {
        Market storage m = markets[marketId];

        // CHECKS
        if (m.resolved) revert MarketAlreadyResolved(marketId);
        if (hasVoted[marketId][msg.sender]) revert AlreadyVoted(marketId, msg.sender);
        if (amount == 0) revert ZeroAmount();
        uint256 currentAllowance = token.allowance(msg.sender, address(this));
        if (currentAllowance < amount) revert InsufficientAllowance(amount, currentAllowance);

        // EFFECTS
        hasVoted[marketId][msg.sender] = true;
        if (side) {
            m.yesPool += amount;
        } else {
            m.noPool += amount;
        }

        // INTERACTIONS (external call last — CEI pattern)
        token.transferFrom(msg.sender, address(this), amount);

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
