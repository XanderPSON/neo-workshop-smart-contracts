# Smart Contracts Workshop

## Overview

This is a hands-on Foundry project for learning Solidity through a prediction market.
Participants clone the `prediction-market` branch and implement function bodies in skeleton contracts.

There are two phases:
1. **Part 1** — Implement `PredictionMarket.sol` (ETH-based, satisfying the `IPredictionMarket` interface)
2. **Part 2** — Customize `MyToken.sol` (inherits the supplied, complete `ERC20.sol`), add owner-only `mint`, and upgrade the market to use ERC-20 tokens

Participants use Toshi, Coinbase's AI coding agent. Coach them: explain, point at the relevant spec or test, and let them write the code.

## Tech Stack

- Solidity ^0.8.13 pragmas, compiler pinned to 0.8.28 in `foundry.toml`
- Foundry (forge, cast, anvil)
- Target chain: Base Sepolia

## Commands

```
forge build          # Compile contracts
forge test -vvv      # Run all tests
forge test --match-contract MyTokenTest -vvv  # Run one suite
forge test --match-test testFunctionName  # Run single test
forge fmt --check    # Formatting gate (CI runs this)
make rescue-dry      # Simulate the catch-up deploy (no broadcast)
make rescue          # Deploy reference V1 + token + V2 to Base Sepolia
```

## Project Structure

```
src/
├── IPredictionMarket.sol  # Interface spec (DO NOT MODIFY)
├── IERC20.sol             # ERC-20 interface (DO NOT MODIFY)
├── PredictionMarket.sol   # Skeleton — participant implements this
├── ERC20.sol              # Complete ERC-20 base (supplied, tested)
└── MyToken.sol            # Participant's token — customize + implement mint
test/
├── PredictionMarket.t.sol # Market test suite (DO NOT MODIFY)
├── ERC20.t.sol            # ERC-20 base tests (pass out of the box)
├── MyToken.t.sol          # Token tests — mint tests fail until the TODO is done
└── Rescue.t.sol           # Rescue deploy wiring tests
script/
├── Deploy.s.sol           # Deploy V1
├── DeployToken.s.sol      # Deploy MyToken
├── DeployV2.s.sol         # Deploy V2 (participant fills in token address)
└── Rescue.s.sol           # Catch-up: reference V1 + token + V2 (used by `make rescue`)
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
On a fresh starter, `PredictionMarketTest` and the `test_mint_*` tests in `MyTokenTest` fail by design; they pass once the participant implements the TODOs. `ERC20Test` and `RescueTest` always pass.
All 12 market tests must pass before deploying.

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
