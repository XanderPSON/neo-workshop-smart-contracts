# Local testing and recovery

## Choose the right check

Prerequisites: Foundry **v1.3.5**, Python 3.9+, initialized `lib/forge-std`, and cached Solidity 0.8.28. Initial setup (`git submodule update --init --recursive`, `forge build`) can download dependencies/compiler. Everything below runs offline against copied sources and, where needed, a new loopback-only Anvil chain (31337). It does not source `.env`, load a global account, or contact Base Sepolia. Synthetic private keys 1 and 2 are public test fixtures, never real wallets.

```bash
make verify-starter    # unchanged template: 17 pass, exactly 24 intentional TODO failures
make verify-reference  # isolated completion: all 41 tests + local deployment/receipt/state assertions
make verify-completed  # same assertions, using YOUR current src without filling any TODO
python3 script/test_verification.py  # five injected defects must be rejected
```

The starter command checks every result, including the failing exercise names and reasons. Two event-expectation tests report `log != expected log` instead of the underlying TODO revert. Missing suites, unexpected failures, skipped tests, or an unexpected success fail the check. No learner tests are removed, marked expected-failure, or changed. `forge test` still fails on the unfinished starter; it becomes green when the exercises are complete. The template CI intentionally uses starter mode; after finishing both parts in a learner fork, replace that CI step's `starter` argument with `completed` (do not suppress failures).

Reference mode is **explicit instructor authorization** to use the references, not learner coaching. It completes only a disposable copy: V1's seven bodies plus owner modifier/usage as a prerequisite, MyToken's `mint`, and V2's `vote`. V2's reference class name and the reference token's constructor differ from the starter, so no entire source file is replaced. The fixture also exercises allowed token customization with `RehearsalCoin`, `RHR`, and `1_234_567 ether` initial supply. All other starter declarations/constructors and every learner source file stay intact. Completed mode never fills TODOs (existing Rescue tests still import reference contracts).

## Repeatable evidence and frontend handoff

Default runs remove their disposable workspace and stop their Anvil process on exit. To retain evidence, choose a **new** output directory for each run:

```bash
bash script/verify-workshop.sh reference --output /tmp/neo-proof-1
bash script/verify-workshop.sh reference --output /tmp/neo-proof-2
```

Each clean run requires all tests to pass, deploys V1, two tokens, V2 and the rescue bundle using encrypted **fixture-only** keystores, and checks:

- Selected owner, initial supply, token wiring, bytecode and successful deployment receipts. Read and assert token name/symbol/18 decimals/supply (reference mode requires the exact instructor customization; completed mode accepts learner metadata and records it).
- Mutual 1,000-token distribution between two synthetic wallets; owner mint increases balance/supply.
- Non-owner mint and no-allowance vote: exact custom-error selector, actual failed transaction receipt (not just a failed gas estimate), zero logs and unchanged token/market state.
- Approval state, successful vote events, allowance consumption, a repeated vote on the opposite side, cumulative 15-token stake, escrow balance, 10/5 pools and the peer's debit.
- Resolution state/outcome and a refused post-resolution vote even with sufficient allowance.
- A fresh open V2 market (ID 1) for the frontend; market 0 is retained as the resolved evidence.

`manifest.json` schema 1 exposes `rpcUrl`, `chainId`, `owner`, `peer`, `v1`, `token`, `peerToken`, `v2`, `openMarketId`, `resolvedMarketId`, test counts, state, and observed `tokens` metadata (`initialSupply` is a base-unit string). `receipts.json` retains receipts with status/logs/hash/block; build/test/deploy logs are beside it. `fixture.env` contains public configuration only. Retained output also includes disposable keystores and their public fixture password; keep it outside git. Receipt hashes, ports and timing may differ; asserted state and outcomes are deterministic.

For a frontend harness that owns its own Anvil/app lifecycle, reuse the **same** completion helper:

```bash
python3 /path/to/contracts/script/prepare-instructor.py /tmp/NEW-completed-contracts
# Run forge/cast in that directory, signing ONLY with your harness's synthetic accounts.
```

The destination must not exist and must be outside the contracts checkout. The helper copies only workshop inputs, links local forge-std, fills disposable exercise bodies/owner modifier, and customizes the fixture token constructor arguments. It starts no process and sends no transaction. The verifier uses the same functions. A scaffold-preservation test covers all other declarations/constructors. To check that copy without filling anything else, run `bash /tmp/NEW-completed-contracts/script/verify-workshop.sh completed`.

Alternatively `bash script/verify-workshop.sh reference --output /tmp/NEW-live-fixture --serve --port 18545` holds its verified chain alive until Ctrl-C. The default port is dynamically chosen. Wait for `READY`, then read the manifest; only `--serve` keeps its RPC usable after the check. Stop the harness before resetting; each invocation uses a fresh directory and chain, never `anvil_reset` on someone else's RPC.

## Failure and recovery

1. Read the first failing assertion and the named output log. A compile failure is not an expected TODO failure. Inspect `tests.json` for the precise test result; `tests.stderr` contains tool diagnostics.
2. Missing compiler while offline: run setup `forge build` once with network access, then rerun. Missing forge-std: initialize the submodule. Use the pinned Foundry version before changing tests or expectations. A broken Python installation should be repaired or replaced with a working Python 3.9+ on PATH.
3. Failed transaction: inspect the receipt status and custom error before changing logic. Wrong allowance means approve the **market** on the **matching token** with base-unit amounts. Pools and token balances must agree; never declare success solely from a transaction hash.
4. Rerun with a fresh output directory. Retain the failed evidence until diagnosed. Never copy a reference into the learner checkout to make CI green. The negative-injection suite proves that broken supplied ERC20 transfer, open mint, omitted transferFrom, overwritten repeated stake, and a removed rescue chain guard are detected.
5. For an AI-assisted fix, give the agent the failing assertion, non-secret source/tests, and allowed files. Require actual test output. Keep `.env`, user keys, keystores and passwords out of prompts. Request human help for wallet/account recovery; do not probe wallet or security APIs.

## Public testnet is a separate manual check

The local checks do not certify wallet funding, encrypted global `dev` setup/unlocking, RPC availability, BaseScan verification, or browser-wallet signing. A human follows README deployment commands with `--account dev --sender "$WALLET_ADDRESS"`, checks chain 84532, saves V1/token/V2 addresses in order, verifies sources for BaseScan interaction, distributes test tokens, approves and votes. Rescue retains its explicit 84532/31337 guard; unit tests simulate both permitted chains and reject chain 1. Never use real funds.

## Scope and lesson traceability

Checked against the Starforge working-copy lessons `apps/starforge/content/new-eng-offsite/01-smart-contracts.md` and `02-token-standards.md` (base revision `3ee1062`, read-only on 2026-11-17), especially “Deploy your prediction market”, token “Deploy”, and “Deploy the upgraded contract”. Parts 1/2 end with a fresh token-backed V2; Part 3 consumes its address for the frontend. The lessons use encrypted `--account dev`, explicit sender, optional-to-the-contract source verification, 18-decimal base units, and separate approval/vote transactions.

Evidence limits: this harness rehearses the ordered contract/CLI path with synthetic identities. It is not an actual BaseScan/browser or live Base Sepolia rehearsal. Lesson UI screenshots and cross-repo frontend verification are separate work; no visual/live completeness claim is made here. Self-review only until the parent reviews local commits.
