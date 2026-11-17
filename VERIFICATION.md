# Contract workshop verification record

Checked locally on 2026-11-17. Implementation: `8980323` (based on `c7ff61b`). No push, PR edit, merge, public-chain transaction, user signer, or browser-wallet API was used.

## Acceptance results

- **pass — source preservation:** `git diff c7ff61b -- src solutions test/PredictionMarket.t.sol test/PredictionMarketV2.t.sol test/MyToken.t.sol test/ERC20.t.sol` is empty. All learner TODOs remain. Only the rescue suite changed, retaining its existing wiring/balance assertions and adding allowed/disallowed-chain checks.
- **pass — starter mode:** two new output directories each report `{'total': 41, 'passed': 17, 'expectedTodoFailures': 24}`. Every supplied-base test passes. An unfinished starter is rejected by completed mode (expected exit 1).
- **pass — completed reference:** two fresh source copies and Anvil chains each report 41/41 contract tests and 24 checked receipts: 21 successes and 3 deliberate reverts. No assertion depends on previous state, an old temporary artifact, or a global keystore.
- **pass — customization:** both token deployments read `RehearsalCoin`, `RHR`, 18 decimals and initial supply `1234567000000000000000000`. Learner constructor/class/storage scaffolds are retained except the explicitly allowed fixture token name/symbol/supply arguments.
- **pass — transaction state:** mutual 1,000-token distribution; owner mint; non-owner mint refusal; no-allowance refusal; approve/vote; repeat vote on the opposite side; cumulative stake and escrow both `15000000000000000000`; pools 10/5 tokens; peer balance 986 tokens; resolution and refused subsequent vote with sufficient allowance. Refusals check custom-error selectors, status-0 receipts, zero logs, and unchanged state.
- **pass — shared helper/completed mode:** preparing a new directory with `prepare-instructor.py`, then invoking that directory's verifier in `completed` mode, passes 41 tests and 24 receipts without additional source completion.
- **pass — regression detection:** the final Python suite has 9 tests and passed repeatedly. Five injected defects are caught: broken supplied transfer return, open mint, omitted transferFrom, overwritten repeat stake, removed rescue guard. Other tests cover scaffold preservation, existing-destination refusal, Make not parsing `.env` during verification, and public-address-only preflight (including missing address and wrong chain).
- **pass — process lifecycle:** serve mode reaches READY with reachable loopback RPC; SIGTERM returns 130 and its Anvil socket closes. All verification-owned processes stopped.
- **pass — build/format:** `forge fmt --check`, `forge build --offline --sizes`, `git diff --check`, and shell syntax checks pass. Existing unchecked ERC20-return lint warnings in test code remain; they are not new build failures.

## Reproduce and inspect

Foundry/Anvil: v1.3.5-stable (`9979a41`). Solidity: pinned 0.8.28. Runs use deterministic fuzz seed `0x42` and 256 cases. Python 3.9.6 and a working Homebrew Python were exercised. The machine's unrelated pyenv Python 3.11 installation printed missing BLAKE2-module warnings, so final proof used working interpreters; no environment repair was attempted.

```bash
for i in 1 2; do
  bash script/verify-workshop.sh starter --output "/tmp/NEW-starter-$i"
  bash script/verify-workshop.sh reference --output "/tmp/NEW-reference-$i"
  python3 script/test_verification.py
done
python3 script/prepare-instructor.py /tmp/NEW-completed
bash /tmp/NEW-completed/script/verify-workshop.sh completed
forge fmt --check
forge build --offline --sizes
```

Use unused directory names. Local retained evidence from the recorded runs:

- `/tmp/neo-custom-starter-{1,2}/tests.json`
- `/tmp/neo-custom-reference-{1,2}/{manifest.json,receipts.json,tests.json,deploy-*.log}`
- `/tmp/neo-custom-completed-proof/{manifest.json,receipts.json,tests.json}`
- `/tmp/neo-custom-unfinished.log` (intentional completed-mode rejection)
- `/tmp/neo-serve-parent-9y0_25a9/serve.log` (READY/termination proof)
- `/tmp/neo-solidity-coverage.log` and `/tmp/neo-python-measured.log`

These paths are local and ephemeral; this record contains the durable results. No keystore, password, private key, or broadcast cache is committed. The Python suite grew from 7 to 9 tests during final hardening; its final 9-test form passed both directly and under explicit trace execution. A naive `python -m trace script/test_verification.py` ran zero unittest cases and was discarded, not counted as proof.

## Coverage and review limits

`forge coverage --offline` on the disposable completed fixture reports line coverage: rescue 100% (29/29), ERC20 100% (27/27), MyToken 100% (5/5), V1 91.18% (31/34), V2 89.19% (33/37). Rescue branch coverage is 100% (3/3). Normal deployment scripts show zero unit-test coverage because their actual execution is measured separately by the Anvil deploy/receipt assertions. A stdlib trace running the actual 9-test suite plus starter/reference main functions measures verifier line coverage at 86% (343 executable lines); uncovered CLI/serve/error branches are not represented as a full coverage pass. The scaffold and negative tests protect the highest-risk paths; this is a self-review, not independent review.

- **pass — factual/local contract path:** instructions agree with supplied contracts and the read-only Parts 1/2 lesson working copy identified in TESTING.md.
- **not-run — live learner path:** Base Sepolia funding, real keystore import/unlocking, explorer source verification, and browser-wallet signing were intentionally excluded.
- **not-run — rendering:** no lesson app files were changed here; Starforge screenshots and real frontend browser integration belong to the parent/other checkout.
- **not-run — remote governance:** CI changes were exercised locally, not on GitHub. Existing PR was not edited and no branch was pushed. Parent review is the next gate.

The fullstack harness can reuse `python3 /path/to/contracts/script/prepare-instructor.py /absolute/NEW-destination` and own its own Anvil/app lifecycle. It must read deployed metadata instead of hardcoding token defaults. The contract verifier's served chain leaves market 0 resolved and market 1 open; the unmodified dashboard hardcodes market 0, so that chain is not a plug-and-play frontend fixture. Use the fullstack `test:e2e` rehearsal's fresh deployment with open market 0 instead. See TESTING.md for the manifest and signing boundaries.
