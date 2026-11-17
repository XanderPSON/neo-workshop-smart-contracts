// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC20} from "./IERC20.sol";

/// @notice Pari-Mutuel Prediction Market V2: takes bets in an ERC-20 instead of ETH.
///
/// Everything here is already wired up: the token is stored, the constructor sets it,
/// and the view and owner functions are done. YOUR TASK is the body of `vote()`.
/// Run `forge test --match-contract PredictionMarketV2Test -vvv` until it's green.
///
/// V1 (src/PredictionMarket.sol) stays untouched, just like V1 stays untouched onchain:
/// "upgrading" an immutable contract means deploying this one at a new address.
contract PredictionMarketV2 {
    // === TYPES & STRUCTS ===
    struct Market {
        string question;
        uint256 yesPool; // Total tokens staked on YES
        uint256 noPool; // Total tokens staked on NO
        bool resolved;
        bool outcome; // true = YES won, false = NO won
    }

    // === STORAGE VARIABLES ===
    address public owner;
    IERC20 public token; // The ERC-20 this market takes bets in
    Market[] public markets;
    // marketId -> voter -> total tokens staked
    mapping(uint256 => mapping(address => uint256)) public amountVoted;

    // === EVENTS ===
    event MarketCreated(uint256 indexed marketId, string question);
    event Voted(uint256 indexed marketId, address voter, bool side, uint256 amount);
    event MarketResolved(uint256 indexed marketId, bool outcome);

    // === ERRORS ===
    error NotOwner(address sender, address owner);
    error MarketAlreadyResolved(uint256 marketId);
    error ZeroAmount();
    error InsufficientAllowance(uint256 amount, uint256 allowance);

    // === MODIFIERS ===
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender, owner);
        _;
    }

    // === CONSTRUCTOR ===
    constructor(address owner_, address token_) {
        owner = owner_;
        token = IERC20(token_);
    }

    // === READ FUNCTIONS (done) ===

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

    // === OWNER FUNCTIONS (done) ===

    function createMarket(string calldata question) external onlyOwner returns (uint256 marketId) {
        marketId = markets.length;
        markets.push(Market({question: question, yesPool: 0, noPool: 0, resolved: false, outcome: false}));
        emit MarketCreated(marketId, question);
    }

    function resolveMarket(uint256 marketId, bool outcome) external onlyOwner {
        Market storage m = markets[marketId];
        if (m.resolved) revert MarketAlreadyResolved(marketId);
        m.resolved = true;
        m.outcome = outcome;
        emit MarketResolved(marketId, outcome);
    }

    // === YOUR TASK ===

    /// @notice Stake `amount` tokens on `side` (true = YES) of market `marketId`.
    /// The voter must first call `token.approve(address(this), amount)`.
    function vote(uint256 marketId, bool side, uint256 amount) external {
        // TODO: Follow Checks-Effects-Interactions:
        //   CHECKS:  revert MarketAlreadyResolved if resolved, ZeroAmount if amount == 0,
        //            and InsufficientAllowance(amount, allowance) if
        //            token.allowance(msg.sender, address(this)) < amount
        //   EFFECTS: add amount to amountVoted[marketId][msg.sender] and to yesPool or noPool
        //   INTERACTIONS (last): token.transferFrom(msg.sender, address(this), amount)
        //   Then emit Voted(marketId, msg.sender, side, amount).
        // Production note: our supplied token reverts on failure. Tokens in the wild may return
        // false instead, so real code checks transferFrom's return value (or uses SafeERC20).
        revert("Not implemented");
    }
}
