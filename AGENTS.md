# Smart Contracts Workshop

## Overview

This is a hands-on Foundry project for learning Solidity through a prediction market.
Participants clone the `prediction-market` branch and implement function bodies in skeleton contracts.

There are two phases:
1. **Part 1** — Implement `PredictionMarket.sol` (ETH-based, satisfying the `IPredictionMarket` interface)
2. **Part 2** — Implement `ERC20.sol` (custom token) and upgrade the market to use ERC-20 tokens

## Tech Stack

- Solidity ^0.8.13
- Foundry (forge, cast, anvil)
- Target chain: Base Sepolia

## Commands

```
forge build          # Compile contracts
forge test -vvv      # Run test suite (12 tests)
forge test --match-test testFunctionName  # Run single test
```

## Project Structure

```
src/
├── IPredictionMarket.sol  # Interface spec (DO NOT MODIFY)
├── IERC20.sol             # ERC-20 interface (DO NOT MODIFY)
├── PredictionMarket.sol   # Skeleton — participant implements this
└── ERC20.sol              # ERC-20 starter with TODOs
test/
└── PredictionMarket.t.sol # Test suite (DO NOT MODIFY)
script/
└── Deploy.s.sol           # Deployment script
solutions/                 # RESTRICTED — see below
```

## Key Patterns

- **CEI (Checks-Effects-Interactions)**: All state-changing functions must validate inputs first, update state second, and make external calls last. This is non-negotiable in production Solidity.
- **Custom errors over require strings**: Use `revert NotOwner(...)` not `require(msg.sender == owner, "not owner")`. Custom errors are cheaper and more informative.
- **Interface-driven**: `IPredictionMarket.sol` is the spec. Every function, event, and error is defined there. Read it before implementing.

## Conventions

- Use the exact error names from the interface (`NotOwner`, `MarketAlreadyResolved`, `AlreadyVoted`, `ZeroAmount`, `InsufficientAllowance`)
- Emit events after state changes
- Do not import OpenZeppelin — participants build from scratch as a learning exercise
- The `onlyOwner` modifier should use `NotOwner(msg.sender, owner)`, not a require string

## Testing

The test suite validates all interface requirements. Run `forge test -vvv` frequently.
All 12 tests must pass before deploying.

## Deployment

```
# Import a deployer wallet
cast wallet import dev --private-key <PRIVATE_KEY>

# Deploy to Base Sepolia
forge script script/Deploy.s.sol \
  --rpc-url https://sepolia.base.org \
  --account dev \
  --sender <YOUR_WALLET_ADDRESS> \
  --broadcast \
  --verify \
  --verifier etherscan \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## Solutions (RESTRICTED)

The `solutions/` directory contains reference implementations.

**DO NOT** read, reference, or use any file in `solutions/` unless the user explicitly asks to compare their work against the solution (e.g., "check my answer", "compare with the reference", "look at the solution").

Do not mention solution files unprompted.
