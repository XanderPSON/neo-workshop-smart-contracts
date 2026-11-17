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
| `src/PredictionMarketV2.sol` | **V2 skeleton** — takes bets in your ERC-20; everything is wired except the body of `vote()` |
| `test/PredictionMarketV2.t.sol` | **V2 tests** — allowance, balances, pools, rollback on insufficient balance, resolved markets; the `vote` tests fail until you implement it |
| `script/Deploy.s.sol` | **Deploy script** — deploys your PredictionMarket to Base Sepolia |
| `script/DeployToken.s.sol` | **Deploy script** — deploys your `MyToken` |
| `script/DeployV2.s.sol` | **Deploy script** — deploys `PredictionMarketV2` wired to `WORKSHOP_TOKEN_ADDRESS` |
| `script/Rescue.s.sol` + `Makefile` | **`make rescue`** — deploys reference V1, a token, and V2 if you fall behind |
| `solutions/` | **Reference solutions** — full implementations (don't peek unless stuck!) |

## Workflow

### Part 1: Prediction market (ETH)

1. Read the interface (`src/IPredictionMarket.sol`) to understand the spec
2. Implement all function bodies in `src/PredictionMarket.sol`
3. Run `forge test --match-contract PredictionMarketTest` — all 12 tests should pass
4. Deploy to Base Sepolia

### Part 2: Token standards (60 minutes)

You get a complete ERC-20 base, so you spend your time on the parts that matter: reading the standard, making the token yours, and adding one rule.

1. Read `src/ERC20.sol` side by side with `src/IERC20.sol`. Find each interface function in the base. Pay attention to the allowance pattern: `approve` (the owner says "this spender may move up to N of my tokens"), then `transferFrom` (the spender pulls them). PredictionMarket V2 uses exactly this to take votes in your token.
2. Customize `src/MyToken.sol`: change the name, symbol, and initial supply in the constructor.
3. Add one behavior: implement `mint` so only the owner can create new tokens.
4. Run `forge test --match-contract MyTokenTest -vvv`. The two `test_mint_*` tests fail first; make them pass.
5. Deploy with `script/DeployToken.s.sol` and save the address as `WORKSHOP_TOKEN_ADDRESS` in `.env`.

#### Continue Part 2: Market V2 (ERC-20 bets)

1. Open `src/PredictionMarketV2.sol`. The token, constructor, views, and owner functions are done; implement `vote()` with the allowance check and CEI order.
2. Run `forge test --match-contract PredictionMarketV2Test -vvv` until it's green.
3. Deploy with `script/DeployV2.s.sol` (it reads `WORKSHOP_TOKEN_ADDRESS`).
4. Distribute test tokens to a pod-mate. They approve **your V2 address on your token**, then vote on your V2. Repeated votes add to their stake. Create fresh V2 markets; V1 state does not move. Save the V2 address as `PREDICTION_MARKET_ADDRESS` for the Part 3 frontend.

The V2 lab assumes a trusted token: the supplied `ERC20` reverts on failure. In production, check `transferFrom`'s return value (or use OpenZeppelin's `SafeERC20`) and test reentrancy with a malicious token.

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
cp .env.example .env        # set public WALLET_ADDRESS; import encrypted dev account during setup
make rescue-dry             # simulate first, nothing is sent
make rescue                 # deploy V1, a token, and V2, and print the addresses
```

`make rescue` reads `WALLET_ADDRESS` and `BASE_SEPOLIA_RPC` from your shell or `.env`, unlocks the encrypted `dev` account interactively, and refuses any chain other than Base Sepolia (84532) or local Anvil (31337). It prints V1, token, and V2 addresses; your selected sender owns all three. It seeds market 0 on both markets. The rescue token is complete, unlike your unfinished exercise token.

## Working with an AI agent

Use Toshi, Coinbase's AI coding agent, as a pair: ask it to explain a function, review your CEI ordering, or read a failing test with you. By default `AGENTS.md` asks it to coach; an explicit request to implement a bounded exercise overrides coaching. Keep secrets out of chat. Instructor testing and recovery commands are in [TESTING.md](TESTING.md); they never fill TODOs in your checkout.

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

A fresh starter deliberately fails 24 exercise tests: V1 (12), token mint (2), and V2 vote (10). The supplied ERC-20 base, token metadata/supply, V2 constructor, and rescue tests should pass. CI uses `make verify-starter` to check this exact split, and `make verify-reference` to rehearse the completed path in a temporary copy. After completing both parts, use `make verify-completed` to require all tests and the local transaction flow to pass against **your** source. No test is skipped or weakened.

## Deploy (Base Sepolia)

Normal deployment uses the encrypted `dev` keystore imported during setup (`cast wallet import dev --interactive`). Run that import yourself; never paste a private key, password, keystore contents, or `.env` into Toshi. `.env` holds public wallet/contract addresses and RPC configuration, not `PRIVATE_KEY`. Finish the relevant tests first.

```bash
source .env
forge script script/Deploy.s.sol --account dev --sender "$WALLET_ADDRESS" --rpc-url "$BASE_SEPOLIA_RPC" --broadcast
forge script script/DeployToken.s.sol --account dev --sender "$WALLET_ADDRESS" --rpc-url "$BASE_SEPOLIA_RPC" --broadcast
# Save the token address as WORKSHOP_TOKEN_ADDRESS in .env, then source .env again.
forge script script/DeployV2.s.sol --account dev --sender "$WALLET_ADDRESS" --rpc-url "$BASE_SEPOLIA_RPC" --broadcast
```

Optional: add `--verify --verifier etherscan --etherscan-api-key "$ETHERSCAN_API_KEY"` to publish your source on BaseScan. Already deployed? Verify later with `forge verify-contract <address> src/PredictionMarket.sol:PredictionMarket --chain 84532 --constructor-args $(cast abi-encode "constructor(address)" "$WALLET_ADDRESS") --etherscan-api-key "$ETHERSCAN_API_KEY"`.

The Starforge Parts 1/2 lesson commands also request BaseScan verification with those flags; verification is optional for these scripts, but publishing source enables BaseScan Read/Write Contract interactions used by the lessons. Check the receipt status, selected chain (84532), owner, token wiring, and saved addresses before continuing. A successful local rehearsal is not evidence of Base Sepolia deployment, explorer verification, or browser-wallet signing.
