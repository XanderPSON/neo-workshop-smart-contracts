# Prediction Market Workshop - Smart Contracts

Hands-on Foundry workshop for building a pari-mutuel prediction market in Solidity.

## What's in the Repo

| File | Purpose |
|------|---------|
| `src/IPredictionMarket.sol` | **Interface (your spec)** — defines every function, event, and error your contract must implement |
| `src/PredictionMarket.sol` | **Skeleton (your starting point)** — inherits the interface, all function bodies revert "Not implemented" |
| `src/IERC20.sol` | **ERC-20 interface** — the standard every token implements |
| `src/ERC20.sol` | **ERC-20 base (supplied, complete, tested)** — read it against `IERC20.sol` |
| `src/MyToken.sol` | **Your token** — inherits `ERC20`; you customize it and add one behavior |
| `test/PredictionMarket.t.sol` | **Market tests** — 12 tests that validate your implementation |
| `test/ERC20.t.sol` | **ERC-20 base tests** — pass out of the box |
| `test/MyToken.t.sol` | **Your token's tests** — the `mint` tests fail until you finish the TODO |
| `script/Deploy.s.sol` | **Deploy script** — deploys your PredictionMarket to Base Sepolia |
| `script/DeployToken.s.sol` | **Deploy script** — deploys your `MyToken` |
| `script/Rescue.s.sol` + `Makefile` | **`make rescue`** — deploys reference V1, a token, and V2 if you fall behind |
| `solutions/` | **Reference solutions** — full implementations (don't peek unless stuck!) |

## Workflow

### Part 1: Prediction market (ETH)

1. Read the interface (`src/IPredictionMarket.sol`) to understand the spec
2. Implement all function bodies in `src/PredictionMarket.sol`
3. Run `forge test --match-contract PredictionMarketTest` — all 12 tests should pass
4. Deploy to Base Sepolia

### Part 2: Make your own token (about 45 minutes)

You get a complete ERC-20 base, so you spend your time on the parts that matter: reading the standard, making the token yours, and adding one rule.

1. Read `src/ERC20.sol` side by side with `src/IERC20.sol`. Find each interface function in the base. Pay attention to the allowance pattern: `approve` (the owner says "this spender may move up to N of my tokens"), then `transferFrom` (the spender pulls them). PredictionMarket V2 uses exactly this to take votes in your token.
2. Customize `src/MyToken.sol`: change the name, symbol, and initial supply in the constructor.
3. Add one behavior: implement `mint` so only the owner can create new tokens.
4. Run `forge test --match-contract MyTokenTest -vvv`. The two `test_mint_*` tests fail first; make them pass.
5. Deploy with `script/DeployToken.s.sol`, then upgrade your market to V2 using your token address.

<details>
<summary>Alternative behavior: a supply cap instead of owner-only mint</summary>

Add `uint256 public constant CAP = 2_000_000 ether;` and a custom error `CapExceeded(uint256 requested, uint256 cap)`. In `mint`, revert if `totalSupply + amount > CAP`, then call `_mint`. Update `test/MyToken.t.sol`: add a test that minting past the cap reverts with `CapExceeded`, and a test that minting up to the cap works.

</details>

<details>
<summary>Stretch: write transfer / approve / transferFrom yourself</summary>

Want the from-scratch version? In `src/ERC20.sol`, replace the bodies of `transfer`, `approve`, and `transferFrom` with `revert("Not implemented");` and write them again. `test/ERC20.t.sol` is your spec: run `forge test --match-contract ERC20Test -vvv` until all tests pass.

Hints:
- `transfer`: check the sender's balance (revert with `InsufficientBalance`), subtract, add, emit `Transfer`, return `true`.
- `approve`: set `allowance[msg.sender][spender]`, emit `Approval`, return `true`.
- `transferFrom`: check the allowance (revert with `InsufficientAllowance`) and the balance, reduce both, emit `Transfer`, return `true`.

</details>

### Behind? `make rescue`

If you're stuck and need working contracts to keep going (for example, for Day 2's frontend), deploy the reference contracts to Base Sepolia:

```bash
cp .env.example .env        # then set PRIVATE_KEY (testnet wallet only)
make rescue-dry             # simulate first, nothing is sent
make rescue                 # deploy V1, a token, and V2, and print the addresses
```

`make rescue` reads `PRIVATE_KEY` and `BASE_SEPOLIA_RPC` from your shell or `.env`, refuses to run on any chain other than Base Sepolia (84532) or local anvil, and prints the PredictionMarket V1, token, and PredictionMarket V2 addresses. Your deployer is the owner of all three.

## Working with an AI agent

Use Toshi, Coinbase's AI coding agent, as a pair: ask it to explain a function, review your CEI ordering, or read a failing test with you. `AGENTS.md` tells it to coach rather than hand over answers, and to stay out of `solutions/` unless you ask.

## Instructor Deployment

Reference instructor contract:
[`0x32593a9DFe40e4605A02A32BCFC7FEfF30BBDd94`](https://sepolia.basescan.org/address/0x32593a9DFe40e4605A02A32BCFC7FEfF30BBDd94#code)

## Setup

Install Foundry:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

The compiler is pinned in `foundry.toml` (`solc_version = "0.8.28"`), so everyone builds with the same version. Forge downloads it on the first build.

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
