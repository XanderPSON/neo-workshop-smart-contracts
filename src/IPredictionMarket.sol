// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @title IPredictionMarket — Pari-Mutuel Prediction Market Interface
/// @notice Defines the required interface for a prediction market contract.
/// Winners split losers' tokens proportionally based on pool sizes.
///
/// Your job: implement a contract that satisfies this interface.
/// Run `forge test` to verify your implementation against the test suite.
interface IPredictionMarket {
    // === TYPES ===

    /// @notice A single prediction market.
    /// @dev Solidity interfaces cannot define structs that the implementing contract
    /// must use internally, but your contract MUST store these fields per market:
    ///   - string question    — The market's question (e.g., "Will it rain tomorrow?")
    ///   - uint256 yesPool    — Total wei staked on YES
    ///   - uint256 noPool     — Total wei staked on NO
    ///   - bool resolved      — Whether the market has been resolved
    ///   - bool outcome       — The resolution outcome (true = YES won, false = NO won)

    // === EVENTS ===

    /// @notice Emitted when a new market is created.
    event MarketCreated(uint256 indexed marketId, string question);

    /// @notice Emitted when a user votes on a market.
    event Voted(uint256 indexed marketId, address voter, bool side, uint256 amount);

    /// @notice Emitted when a market is resolved by the owner.
    event MarketResolved(uint256 indexed marketId, bool outcome);

    // === ERRORS ===

    /// @notice Thrown when a non-owner tries to call an owner-only function.
    error NotOwner(address sender, address owner);

    /// @notice Thrown when trying to interact with a resolved market.
    error MarketAlreadyResolved(uint256 marketId);

    /// @notice Thrown when a user tries to vote twice on the same market.
    error AlreadyVoted(uint256 marketId, address voter);

    /// @notice Thrown when a vote is placed with zero ETH.
    error ZeroAmount();

    // === READ FUNCTIONS ===

    /// @notice Returns the address of the contract owner.
    function owner() external view returns (address);

    /// @notice Returns the total number of markets created.
    function totalMarkets() external view returns (uint256);

    /// @notice Returns the current pool sizes for a market.
    /// @param marketId The ID of the market to query.
    /// @return yesPool Total wei staked on YES.
    /// @return noPool Total wei staked on NO.
    function getOdds(uint256 marketId) external view returns (uint256 yesPool, uint256 noPool);

    /// @notice Returns whether a specific address has voted on a market.
    /// @param marketId The ID of the market.
    /// @param voter The address to check.
    /// @return True if the address has voted, false otherwise.
    function hasVoted(uint256 marketId, address voter) external view returns (bool);

    // === WRITE FUNCTIONS ===

    /// @notice Creates a new prediction market. Only callable by the owner.
    /// @param question The question for the market (e.g., "Will ETH hit $5k?").
    /// @return marketId The ID of the newly created market.
    function createMarket(string calldata question) external returns (uint256 marketId);

    /// @notice Places a vote on a market by sending ETH.
    /// @dev Must follow the Checks-Effects-Interactions (CEI) pattern.
    ///      - CHECKS: Market not resolved, user hasn't voted, amount > 0
    ///      - EFFECTS: Mark voter, update pool
    ///      - INTERACTIONS: (ETH received via msg.value, no external call needed)
    /// @param marketId The ID of the market to vote on.
    /// @param side true = YES, false = NO.
    function vote(uint256 marketId, bool side) external payable;

    /// @notice Resolves a market with a final outcome. Only callable by the owner.
    /// @param marketId The ID of the market to resolve.
    /// @param outcome true = YES won, false = NO won.
    function resolveMarket(uint256 marketId, bool outcome) external;
}
