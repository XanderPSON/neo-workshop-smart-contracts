# Smart Contracts Workshop

## Overview

This is a hands-on Foundry project for learning Solidity through a prediction market.
Participants clone the repo and implement function bodies in skeleton contracts.

There are two phases:
1. **Part 1** — Implement `PredictionMarket.sol` (ETH-based, satisfying the `IPredictionMarket` interface)
2. **Part 2** — Customize `MyToken.sol`, add owner-only `mint`, then implement only `vote()` in `PredictionMarketV2.sol` and deploy it with `DeployV2.s.sol`. Part 3 is the separate frontend workshop.

Participants use Toshi, Coinbase's AI coding agent. Default to coaching: explain, point at the spec or test, and let them write. When explicitly asked to implement, follow that bounded request; preserve interfaces, supplied code, tests, and unrelated TODOs.

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
├── MyToken.sol            # Participant's token — customize + implement mint
└── PredictionMarketV2.sol # V2 skeleton — participant implements vote() only
test/
├── PredictionMarket.t.sol # Market test suite (DO NOT MODIFY)
├── ERC20.t.sol            # ERC-20 base tests (pass out of the box)
├── MyToken.t.sol          # Token tests — mint tests fail until the TODO is done
├── PredictionMarketV2.t.sol # V2 vote tests — fail until vote() is implemented
└── Rescue.t.sol           # Rescue deploy wiring tests
script/
├── Deploy.s.sol           # Deploy V1
├── DeployToken.s.sol      # Deploy MyToken
├── DeployV2.s.sol         # Deploy PredictionMarketV2 with WORKSHOP_TOKEN_ADDRESS (env)
└── Rescue.s.sol           # Catch-up: reference V1 + token + V2 (used by `make rescue`)
solutions/                 # RESTRICTED — see below
```

## Key Patterns

- **CEI (Checks-Effects-Interactions)**: All state-changing functions must validate inputs first, update state second, and make external calls last. This is non-negotiable in production Solidity.
- **Custom errors over require strings**: Use `revert NotOwner(...)` not `require(msg.sender == owner, "not owner")`. Custom errors are cheaper and more informative.
- **Interface-driven**: `IPredictionMarket.sol` is the spec. Every function, event, and error is defined there. Read it before implementing.

## Conventions

- Use the exact error names from the interface (`NotOwner`, `MarketAlreadyResolved`, `ZeroAmount`); V2 adds `InsufficientAllowance`
- V2 assumes the trusted supplied token (it reverts on failure). When coaching, note that production code checks `transferFrom`'s return value or uses `SafeERC20`, and tests reentrancy
- Emit events after state changes
- Do not import OpenZeppelin — participants build from scratch as a learning exercise
- The `onlyOwner` modifier should use `NotOwner(msg.sender, owner)`, not a require string

## Testing

The test suite validates all interface requirements. Run `forge test -vvv` frequently.
On a fresh starter, `PredictionMarketTest`, the `test_mint_*` tests in `MyTokenTest`, and the `test_vote_*` tests in `PredictionMarketV2Test` fail by design; they pass once the participant implements the TODOs. `ERC20Test` and `RescueTest` always pass.
All 12 market tests must pass before deploying.

For starter CI, completed-path verification, transaction receipts, negative injections, or recovery after a failed rehearsal, read [TESTING.md](TESTING.md) first. These instructor commands use disposable source copies and a loopback Anvil chain; leave learner TODOs in this checkout intact.

## Deployment

```
# Human runs these commands with the encrypted dev account from setup.
source .env
forge script script/Deploy.s.sol --account dev --sender "$WALLET_ADDRESS" --rpc-url "$BASE_SEPOLIA_RPC" --broadcast
forge script script/DeployToken.s.sol --account dev --sender "$WALLET_ADDRESS" --rpc-url "$BASE_SEPOLIA_RPC" --broadcast
# Save WORKSHOP_TOKEN_ADDRESS to .env and source .env before V2.
forge script script/DeployV2.s.sol --account dev --sender "$WALLET_ADDRESS" --rpc-url "$BASE_SEPOLIA_RPC" --broadcast
```

BaseScan verification is optional (add `--verify --verifier etherscan --etherscan-api-key "$ETHERSCAN_API_KEY"`, or run `forge verify-contract` later). Main-path deploys don't verify.
Keep private keys, keystore contents, passwords, and `.env` out of agent context. Use public `WALLET_ADDRESS` for preflight. Never request or read user keys to run tests. `make rescue` uses the same encrypted signer and retains its 84532/31337 chain guard.

## Solutions (RESTRICTED)

The `solutions/` directory contains reference implementations.

Read, reference, or use `solutions/` only when explicitly authorized to compare against a reference or to run isolated instructor verification. For the latter, use the documented disposable fixture; authorization never extends to filling learner source files. Learner coaching alone does not authorize reading references.

Do not mention solution files unprompted.
