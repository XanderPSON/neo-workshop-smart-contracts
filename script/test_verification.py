#!/usr/bin/env python3
"""Negative injections: existing assertions must reject broken temporary fixtures."""
import argparse
from pathlib import Path
import tempfile
import subprocess
import unittest
from verify_workshop import ROOT, Rehearsal, body, complete, copy_fixture


class VerificationTest(unittest.TestCase):
    def rejected(self, file, old, new, starter=False):
        with tempfile.TemporaryDirectory(prefix="neo-negative-") as directory:
            rehearsal = Rehearsal(argparse.Namespace(mode="starter" if starter else "reference"), Path(directory))
            if not starter:
                complete(rehearsal.work)
            path = rehearsal.work / file
            text = path.read_text()
            self.assertIn(old, text, "injection point changed; update this test explicitly")
            path.write_text(text.replace(old, new, 1))
            with self.assertRaisesRegex(RuntimeError, "Unexpected failure"):
                rehearsal.tests(starter=starter)

    def test_completion_preserves_starter_scaffolds(self):
        with tempfile.TemporaryDirectory(prefix="neo-scaffold-") as directory:
            work = Path(directory) / "completed"
            copy_fixture(work)
            complete(work)
            for name in ("MyToken", "PredictionMarketV2"):
                original = (ROOT / f"src/{name}.sol").read_text()
                completed = (work / f"src/{name}.sol").read_text()
                function = "mint" if name == "MyToken" else "vote"
                a, b = body(original, function)
                if name == "MyToken":
                    self.assertIn('ERC20("RehearsalCoin", "RHR", 1_234_567 ether)', completed)
                    completed = completed.replace('ERC20("RehearsalCoin", "RHR", 1_234_567 ether)',
                                                  'ERC20("MyToken", "MTK", 1_000_000 ether)')
                c, d = body(completed, function)
                self.assertEqual(original[:a] + original[b:], completed[:c] + completed[d:])
            original = (ROOT / "src/PredictionMarket.sol").read_text()
            completed = (work / "src/PredictionMarket.sol").read_text()
            self.assertEqual(original.split("// === MODIFIERS")[0], completed.split("// === MODIFIERS")[0])
            def constructor(source):
                return source[source.index("    constructor("):source.index("    // === READ FUNCTIONS")]
            self.assertEqual(constructor(original), constructor(completed))

    def test_existing_destination_is_refused(self):
        with tempfile.TemporaryDirectory(prefix="neo-existing-") as directory:
            path = Path(directory)
            (path / "sentinel").write_text("unchanged")
            with self.assertRaises(FileExistsError):
                copy_fixture(path)
            self.assertEqual((path / "sentinel").read_text(), "unchanged")

    def test_make_verification_never_parses_dotenv(self):
        with tempfile.TemporaryDirectory(prefix="neo-dotenv-") as directory:
            path = Path(directory)
            (path / "Makefile").write_text((ROOT / "Makefile").read_text())
            (path / ".env").write_text("$(error verification must not parse .env)\n")
            (path / "script").mkdir()
            (path / "script/verify-workshop.sh").write_text("exit 0\n")
            result = subprocess.run(["make", "verify-starter", "verify-reference", "verify-completed"],
                                    cwd=path, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_preflight_uses_only_public_address(self):
        with tempfile.TemporaryDirectory(prefix="neo-preflight-") as directory:
            path = Path(directory)
            mocks = {"forge": "echo forge-fixture", "node": "echo 22", "git": "echo git version fixture",
                     "cast": 'case "$1" in chain-id) echo "${MOCK_CHAIN:-84532}";; balance) echo 1;; *) exit 97;; esac'}
            for name, command in mocks.items():
                target = path / name
                target.write_text("#!/bin/bash\n" + command + "\n")
                target.chmod(0o755)
            env = {"PATH": f"{path}:/usr/bin:/bin", "WALLET_ADDRESS": "0x" + "1" * 40}
            for overrides, status in (({}, 0), ({"WALLET_ADDRESS": ""}, 1), ({"MOCK_CHAIN": "1"}, 1)):
                result = subprocess.run(["bash", str(ROOT / "script/preflight.sh")],
                                        env={**env, **overrides}, capture_output=True, text=True)
                self.assertEqual(result.returncode, status, result.stdout + result.stderr)
                if status == 0:
                    self.assertIn("All set", result.stdout)

    def test_starter_catches_supplied_base_regression(self):
        self.rejected("src/ERC20.sol", "return true;", "return false;", starter=True)

    def test_completed_catches_nonowner_mint(self):
        self.rejected("src/MyToken.sol", "if (msg.sender != owner) revert NotOwner(msg.sender, owner);", "")

    def test_completed_catches_missing_transfer(self):
        self.rejected("src/PredictionMarketV2.sol", "token.transferFrom(msg.sender, address(this), amount);", "")

    def test_completed_catches_replaced_repeat_stake(self):
        self.rejected("src/PredictionMarketV2.sol", "amountVoted[marketId][msg.sender] += amount;",
                      "amountVoted[marketId][msg.sender] = amount;")

    def test_catches_removed_rescue_chain_guard(self):
        self.rejected("script/Rescue.s.sol",
                      'require(block.chainid == BASE_SEPOLIA || block.chainid == ANVIL, "Rescue: testnet only (Base Sepolia 84532)");', "")


if __name__ == "__main__":
    unittest.main(verbosity=2)
