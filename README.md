# Prediction Market Workshop - Smart Contracts

Hands-on Foundry workshop for building a pari-mutuel prediction market in Solidity.

## What's in the Repo

| File | Purpose |
|------|---------|
| `src/IPredictionMarket.sol` | **Interface (your spec)** — defines every function, event, and error your contract must implement |
| `src/PredictionMarket.sol` | **Skeleton (your starting point)** — inherits the interface, all function bodies revert "Not implemented" |
| `src/ERC20.sol` | **ERC-20 starter** — Part 2 token with TODOs for participants to complete |
| `test/PredictionMarket.t.sol` | **Test suite** — 12 tests that validate your implementation |
| `script/Deploy.s.sol` | **Deploy script** — deploys your PredictionMarket to Base Sepolia |
| `solutions/PredictionMarket.sol` | **Reference solution** — full implementation (don't peek unless stuck!) |

## Workflow

1. Read the interface (`src/IPredictionMarket.sol`) to understand the spec
2. Implement all function bodies in `src/PredictionMarket.sol`
3. Run `forge test` — all 12 tests should pass
4. Deploy to Base Sepolia

## Instructor Deployment

Reference instructor contract:
[`0x32593a9DFe40e4605A02A32BCFC7FEfF30BBDd94`](https://sepolia.basescan.org/address/0x32593a9DFe40e4605A02A32BCFC7FEfF30BBDd94#code)

## Setup

Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

## Build

```bash
forge build
```

## Test

```bash
forge test -vvv
```

## Deploy (Base Sepolia)

Create and import a deployer wallet:

```bash
cast wallet new
cast wallet import dev --private-key <PRIVATE_KEY>
```

Broadcast deployment:

```bash
forge script Deploy --account dev --rpc-url https://sepolia.base.org --broadcast --verify --verifier etherscan --etherscan-api-key $ETHERSCAN_API_KEY
```
