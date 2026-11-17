#!/usr/bin/env python3
"""Instructor-only, disposable completion fixture and loopback-chain assertions."""
import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import socket
import subprocess
import tempfile
import time
import urllib.error
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
UNIT = 10**18
KEYS = [f"0x{n:064x}" for n in (1, 2)]  # Public synthetic keys: local Anvil ONLY.


def check(condition, message):
    if not condition:
        raise RuntimeError(message)


def body(source, name, kind="function"):
    start = source.index("{", source.index(f"{kind} {name}("))
    end, depth = start + 1, 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return start, end


def complete(work):
    # Keep starter class/storage/constructor structure (customize token arguments below). Reference V2's
    # class and reference token's constructor are intentionally different.
    path = work / "src/PredictionMarket.sol"
    source = path.read_text()
    ref = (work / "solutions/PredictionMarket.sol").read_text()
    marker = "    // TODO: Define an onlyOwner modifier that reverts with NotOwner if msg.sender != owner"
    check(source.count(marker) == 1, "V1 modifier scaffold changed")
    c, d = body(ref, "onlyOwner", "modifier")
    source = source.replace(marker, "    modifier onlyOwner() " + ref[c:d])
    for name in ("totalMarkets", "getOdds", "getMarket", "createMarket", "hasVoted", "vote", "resolveMarket"):
        a, b = body(source, name)
        c, d = body(ref, name)
        check('revert("Not implemented")' in source[a:b], f"V1 {name}: exercise body changed")
        source = source[:a] + ref[c:d] + source[b:]
        if name in ("createMarket", "resolveMarket"):
            start = source.index(f"function {name}(")
            header = source[start:a]
            check(header.count(" external") == 1, f"V1 {name}: signature changed")
            source = source[:start] + header.replace(" external", " external onlyOwner") + source[a:]
    path.write_text(source)
    for target, reference, function in [
        ("MyToken", "MyToken", "mint"),
        ("PredictionMarketV2", "PredictionMarketV2", "vote"),
    ]:
        path = work / f"src/{target}.sol"
        source = path.read_text()
        ref = (work / f"solutions/{reference}.sol").read_text()
        a, b = body(source, function)
        c, d = body(ref, function)
        check('revert("Not implemented")' in source[a:b],
              f"{target}: reference mode requires untouched exercise body")
        path.write_text(source[:a] + ref[c:d] + source[b:])
    token = work / "src/MyToken.sol"
    source = token.read_text()
    original = 'ERC20("MyToken", "MTK", 1_000_000 ether)'
    check(source.count(original) == 1, "Instructor token customization scaffold changed")
    token.write_text(source.replace(original, 'ERC20("RehearsalCoin", "RHR", 1_234_567 ether)'))


def copy_fixture(destination):
    """Copy only workshop inputs; never copy .env, accounts, build cache or git."""
    check(destination != ROOT and ROOT not in destination.parents,
          "Disposable destination must be outside the contracts checkout")
    destination.mkdir(parents=True, exist_ok=False)
    for name in ("src", "test", "script", "solutions"):
        shutil.copytree(ROOT / name, destination / name,
                        ignore=shutil.ignore_patterns("__pycache__"))
    shutil.copy2(ROOT / "foundry.toml", destination)
    shutil.copy2(ROOT / "Makefile", destination)
    (destination / "lib").mkdir()
    check((ROOT / "lib/forge-std/src/Test.sol").is_file(),
          "Initialize forge-std submodule before running offline checks")
    (destination / "lib/forge-std").symlink_to(ROOT / "lib/forge-std", target_is_directory=True)


class Rehearsal:
    def __init__(self, args, output):
        self.args, self.output = args, output
        self.work = output / "work"
        copy_fixture(self.work)
        # Explicit allowlist: no inherited RPC, PRIVATE_KEY, account or .env.
        self.env = {k: os.environ[k] for k in ("PATH", "HOME", "TMPDIR") if k in os.environ}
        self.env.update(FOUNDRY_OFFLINE="true", FOUNDRY_FUZZ_SEED="0x42",
                        FOUNDRY_FUZZ_RUNS="256", NO_COLOR="1")
        self.receipts, self.states = {}, {}
        self.rpc_url = None

    def run(self, *cmd, log=None):
        result = subprocess.run(cmd, cwd=self.work, env=self.env,
                                capture_output=True, text=True, timeout=180)
        if log:
            (self.output / log).write_text(result.stdout + result.stderr)
        check(result.returncode == 0, f"{' '.join(cmd[:3])} failed: {log or result.stderr[-1500:]}")
        return result.stdout.strip()

    def tests(self, starter=False):
        result = subprocess.run(["forge", "test", "--offline", "--json"], cwd=self.work,
                                env=self.env, capture_output=True, text=True, timeout=180)
        (self.output / "tests.json").write_text(result.stdout)
        (self.output / "tests.stderr").write_text(result.stderr)
        suites = json.loads(result.stdout)
        required = {"ERC20Test": 9, "MyTokenTest": 4, "PredictionMarketTest": 12,
                    "PredictionMarketV2Test": 11, "RescueTest": 5}
        check(set(required) <= {name.split(":")[-1] for name in suites}, "Missing required test suite")
        count = failed = expected = 0
        for suite, data in suites.items():
            contract = suite.split(":")[-1]
            check(len(data["test_results"]) >= required.get(contract, 0), f"Missing tests in {suite}")
            for name, test in data["test_results"].items():
                intentional = starter and (
                    contract == "PredictionMarketTest" or
                    (contract == "MyTokenTest" and name.startswith("test_mint_")) or
                    (contract == "PredictionMarketV2Test" and name.startswith("test_vote_")))
                count += 1
                if intentional:
                    expected += 1
                    reason = test.get("reason") or ""
                    event_todo = (contract, name) in {
                        ("MyTokenTest", "test_mint_ownerCanMint()"),
                        ("PredictionMarketV2Test", "test_vote_emitsVoted()"),
                    } and reason == "log != expected log"
                    check(test["status"] == "Failure" and ("Not implemented" in reason or event_todo),
                          f"Expected TODO failure, got {suite}:{name}: {test}")
                else:
                    check(test["status"] == "Success", f"Unexpected failure: {suite}:{name}: {test}")
                failed += test["status"] == "Failure"
        check(count >= 39, "Missing test suites/results")
        check(result.returncode == (1 if starter else 0), "Unexpected forge exit status")
        if starter:
            check(expected == 24 and failed == expected, "Starter TODO inventory changed; review explicitly")
        self.test_summary = {"total": count, "passed": count - failed, "expectedTodoFailures": expected}
        print(f"PASS tests: {self.test_summary}", flush=True)

    def rpc(self, method, *params):
        req = urllib.request.Request(self.rpc_url, json.dumps(
            {"jsonrpc": "2.0", "id": 1, "method": method, "params": list(params)}).encode(),
            {"Content-Type": "application/json"})
        # Ignore proxy environment even on hosts with corporate proxy settings.
        with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(req, timeout=5) as response:
            value = json.load(response)
        return value

    def result(self, method, *params):
        value = self.rpc(method, *params)
        check("error" not in value, f"{method}: {value}")
        return value["result"]

    def call(self, address, signature, *args):
        data = self.run("cast", "calldata", signature, *map(str, args))
        return self.result("eth_call", {"to": address, "data": data}, "latest")

    def number(self, address, signature, *args):
        return int(self.call(address, signature, *args), 16)

    def receipt(self, name, tx, success=True):
        for _ in range(100):
            receipt = self.result("eth_getTransactionReceipt", tx)
            if receipt:
                break
            time.sleep(.05)
        check(receipt and int(receipt["status"], 16) == int(success), f"{name}: unexpected receipt {receipt}")
        check(bool(receipt["logs"]) or name.startswith("deploy-") if success else not receipt["logs"],
              f"{name}: unexpected event logs")
        self.receipts[name] = receipt
        (self.output / "receipts.json").write_text(json.dumps(self.receipts, indent=2) + "\n")
        return receipt

    def send(self, name, who, address, signature, *args, success=True):
        # A fixed gas limit deliberately broadcasts negative cases; an estimate-only
        # rejection is NOT evidence of an onchain failed receipt.
        tx = self.run("cast", "send", address, signature, *map(str, args),
                      "--keystore", str(self.output / f"keystores/{who}"),
                      "--password-file", str(self.output / "password.txt"),
                      "--rpc-url", self.rpc_url, "--gas-limit", "3000000", "--async")
        receipt = self.receipt(name, tx, success)
        if success:
            events = {"transfer": "Transfer(address,address,uint256)",
                      "mint": "Transfer(address,address,uint256)",
                      "approve": "Approval(address,address,uint256)",
                      "createMarket": "MarketCreated(uint256,string)",
                      "vote": "Voted(uint256,address,bool,uint256)",
                      "resolveMarket": "MarketResolved(uint256,bool)"}
            topic = self.run("cast", "keccak", events[signature.split("(")[0]])
            check(any(log["address"].lower() == address.lower() and log["topics"][0] == topic
                      for log in receipt["logs"]), f"{name}: missing expected event")
        return receipt

    def refusal(self, name, who, address, signature, error, *args):
        before = self.snapshot()
        data = self.run("cast", "calldata", signature, *map(str, args))
        response = self.rpc("eth_call", {"from": self.addresses[who], "to": address, "data": data}, "latest")
        selector = self.run("cast", "sig", error)
        check("error" in response and selector in json.dumps(response["error"]),
              f"{name}: expected custom error {error}, got {response}")
        self.send(name, who, address, signature, *args, success=False)
        check(self.snapshot() == before, f"{name}: failed transaction changed token/market state")

    def deploy(self, name, script, label, who="owner"):
        text = self.run("forge", "script", script, "--offline", "--rpc-url", self.rpc_url,
                        "--keystore", str(self.output / f"keystores/{who}"),
                        "--password-file", str(self.output / "password.txt"),
                        "--sender", self.addresses[who], "--broadcast", log=f"deploy-{name}.log")
        address = text.split(label)[1].strip().split()[0]
        check(len(address) == 42 and self.result("eth_getCode", address, "latest") != "0x",
              f"{name}: missing deployment bytecode")
        path = self.work / "broadcast" / script.split("/")[-1].split(":")[0] / "31337/run-latest.json"
        broadcast = json.loads(path.read_text())
        for i, receipt in enumerate(broadcast["receipts"]):
            self.receipt(f"deploy-{name}-{i}", receipt["transactionHash"])
        return address

    def snapshot(self):
        a = self.addresses
        return {
            "ownerBalance": self.number(a["token"], "balanceOf(address)", a["owner"]),
            "peerBalance": self.number(a["token"], "balanceOf(address)", a["peer"]),
            "marketBalance": self.number(a["token"], "balanceOf(address)", a["v2"]),
            "supply": self.number(a["token"], "totalSupply()"),
            "allowance": self.number(a["token"], "allowance(address,address)", a["peer"], a["v2"]),
            "stake": self.number(a["v2"], "amountVoted(uint256,address)", 0, a["peer"]),
            "market": self.call(a["v2"], "getMarket(uint256)", 0),
        }

    def chain(self):
        a = self.addresses = dict(zip(("owner", "peer"), [
            self.run("cast", "wallet", "address", "--private-key", k) for k in KEYS]))
        check(int(self.result("eth_chainId"), 16) == 31337, "Local chain ID guard")
        (self.output / "keystores").mkdir(mode=0o700)
        (self.output / "password.txt").write_text("local-fixture-only\n")
        for who, key in zip(("owner", "peer"), KEYS):
            self.result("anvil_setBalance", a[who], hex(100 * UNIT))
            self.run("cast", "wallet", "import", who, "--private-key", key,
                     "--keystore-dir", str(self.output / "keystores"),
                     "--unsafe-password", "local-fixture-only")
        a["v1"] = self.deploy("v1", "script/Deploy.s.sol", "PredictionMarket deployed to:")
        a["token"] = self.deploy("token", "script/DeployToken.s.sol", "Token deployed to:")
        a["peerToken"] = self.deploy("peer-token", "script/DeployToken.s.sol", "Token deployed to:", "peer")
        self.env["WORKSHOP_TOKEN_ADDRESS"] = a["token"]
        a["v2"] = self.deploy("v2", "script/DeployV2.s.sol", "PredictionMarket V2 deployed to:")
        rescue_v1 = self.deploy("rescue", "script/Rescue.s.sol:Rescue", "PredictionMarket V1")
        check(self.number(rescue_v1, "owner()") == int(a["owner"], 16), "Rescue CLI sender ownership")
        check(self.number(rescue_v1, "totalMarkets()") == 1, "Rescue CLI seeded market")
        for market in (a["v1"], a["v2"]):
            check(self.number(market, "owner()") == int(a["owner"], 16), "Wrong market owner")
        check(self.number(a["v2"], "token()") == int(a["token"], 16), "Wrong V2 token")
        for who, token in (("owner", a["token"]), ("peer", a["peerToken"])):
            check(self.number(token, "owner()") == int(a[who], 16), "Wrong token owner")
            check(self.number(token, "balanceOf(address)", a[who]) == self.number(token, "totalSupply()"),
                  "Initial supply not owned by deployer")
        metadata = {}
        for token_name in ("token", "peerToken"):
            token = a[token_name]
            name = json.loads(self.run("cast", "abi-decode", "name()(string)", self.call(token, "name()")))
            symbol = json.loads(self.run("cast", "abi-decode", "symbol()(string)", self.call(token, "symbol()")))
            decimals = self.number(token, "decimals()")
            supply = self.number(token, "totalSupply()")
            check(name and symbol and decimals == 18 and supply > 0, "Invalid token metadata/supply")
            if self.args.mode == "reference":
                check((name, symbol, supply) == ("RehearsalCoin", "RHR", 1_234_567 * UNIT),
                      "Instructor customization was not deployed")
            metadata[token_name] = {"name": name, "symbol": symbol, "decimals": decimals, "initialSupply": str(supply)}
        check(metadata["token"] == metadata["peerToken"], "Two deployments disagree on metadata")
        self.send("v1-create", "owner", a["v1"], "createMarket(string)", "Local V1 rehearsal")
        self.send("create", "owner", a["v2"], "createMarket(string)", "Local V2 rehearsal")
        self.send("distribution", "owner", a["token"], "transfer(address,uint256)", a["peer"], 1000 * UNIT)
        self.send("peer-distribution", "peer", a["peerToken"], "transfer(address,uint256)", a["owner"], 1000 * UNIT)
        check(self.number(a["peerToken"], "balanceOf(address)", a["owner"]) == 1000 * UNIT, "Peer distribution")
        check(self.snapshot()["peerBalance"] == 1000 * UNIT, "Distribution")
        self.refusal("nonowner-mint", "peer", a["token"], "mint(address,uint256)",
                     "NotOwner(address,address)", a["peer"], UNIT)
        supply = self.snapshot()["supply"]
        self.send("owner-mint", "owner", a["token"], "mint(address,uint256)", a["peer"], UNIT)
        check(self.snapshot()["supply"] == supply + UNIT and self.snapshot()["peerBalance"] == 1001 * UNIT,
              "Owner mint balance/supply")
        self.refusal("no-allowance", "peer", a["v2"], "vote(uint256,bool,uint256)",
                     "InsufficientAllowance(uint256,uint256)", 0, "true", 10 * UNIT)
        for name, amount, side in (("first", 10 * UNIT, "true"), ("repeat", 5 * UNIT, "false")):
            self.send(f"approve-{name}", "peer", a["token"], "approve(address,uint256)", a["v2"], amount)
            check(self.snapshot()["allowance"] == amount, "Approval state")
            self.send(f"vote-{name}", "peer", a["v2"], "vote(uint256,bool,uint256)", 0, side, amount)
            check(self.snapshot()["allowance"] == 0, "Allowance not consumed")
        state = self.snapshot()
        odds = self.call(a["v2"], "getOdds(uint256)", 0)[2:]
        check([int(odds[i:i+64], 16) for i in (0, 64)] == [10 * UNIT, 5 * UNIT], "Pool accounting")
        check(state["stake"] == state["marketBalance"] == 15 * UNIT, "Repeated cumulative stake/escrow")
        check(state["peerBalance"] == 986 * UNIT, "Peer stake debit")
        self.send("resolve", "owner", a["v2"], "resolveMarket(uint256,bool)", 0, "true")
        # Grant enough allowance so the resolved-market guard, not allowance, is tested.
        self.send("approve-closed", "peer", a["token"], "approve(address,uint256)", a["v2"], UNIT)
        self.refusal("resolved-vote", "peer", a["v2"], "vote(uint256,bool,uint256)",
                     "MarketAlreadyResolved(uint256)", 0, "true", UNIT)
        decoded = self.run("cast", "abi-decode", "getMarket(uint256)(string,uint256,uint256,bool,bool)",
                           self.snapshot()["market"]).splitlines()
        check(decoded[-2:] == ["true", "true"], "Resolved outcome state")
        self.states["resolvedMarket0"] = self.snapshot()
        # Fresh open market for the fullstack consumer; market 0 remains evidence.
        self.send("create-open", "owner", a["v2"], "createMarket(string)", "Fullstack open market")
        self.manifest = {"schemaVersion": 1, "mode": self.args.mode, "rpcUrl": self.rpc_url,
                         "chainId": 31337, **a, "openMarketId": 1, "resolvedMarketId": 0,
                         "tests": self.test_summary, "state": self.states,
                         "receipts": "receipts.json", "syntheticKeysOnly": True}
        self.manifest["tokens"] = metadata
        (self.output / "fixture.env").write_text(
            f"RPC_URL={self.rpc_url}\nCHAIN_ID=31337\nWALLET_ADDRESS={a['owner']}\n"
            f"WORKSHOP_TOKEN_ADDRESS={a['token']}\nPREDICTION_MARKET_ADDRESS={a['v2']}\n")
        (self.output / "manifest.json").write_text(json.dumps(self.manifest, indent=2) + "\n")
        print(f"PASS chain: {len(self.receipts)} receipts; distribution, mint guards, approval, repeat stake, resolution", flush=True)


def interrupted(_signal, _frame):
    raise KeyboardInterrupt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("starter", "reference", "completed"))
    parser.add_argument("--output", type=Path, help="new directory for disposable source/logs/manifest")
    parser.add_argument("--serve", action="store_true", help="keep verified local chain alive until Ctrl-C")
    parser.add_argument("--port", type=int, default=0, help="loopback port; default chooses a free port")
    args = parser.parse_args()
    signal.signal(signal.SIGTERM, interrupted)
    check(not args.serve or (args.mode != "starter" and args.output), "--serve requires --output and reference/completed mode")
    output = args.output.resolve() if args.output else Path(tempfile.mkdtemp(prefix="neo-verify-"))
    if args.output:
        output.mkdir(parents=True, exist_ok=False)
    print(f"Evidence: {output}", flush=True)
    # Guarantee starter files stay unchanged even if a tool unexpectedly touches them.
    def hashes():
        return {str(p.relative_to(ROOT)): p.read_bytes()
                for folder in ("src", "test", "solutions") for p in (ROOT / folder).glob("*.sol")}
    before = hashes()
    node = None
    try:
        r = Rehearsal(args, output)
        if args.mode == "reference":
            complete(r.work)
        r.run("forge", "build", "--offline", "--sizes", log="build.log")
        r.tests(starter=args.mode == "starter")
        if args.mode != "starter":
            with socket.socket() as sock:
                sock.bind(("127.0.0.1", args.port))
                port = sock.getsockname()[1]
            r.rpc_url = f"http://127.0.0.1:{port}"
            with (output / "anvil.log").open("w") as log:
                node = subprocess.Popen(["anvil", "--host", "127.0.0.1", "--port", str(port),
                                         "--chain-id", "31337", "--hardfork", "cancun", "--silent"],
                                        env=r.env, stdout=log, stderr=log)
            for _ in range(100):
                check(node.poll() is None, "Anvil exited; inspect anvil.log")
                try:
                    r.result("web3_clientVersion")
                    break
                except (urllib.error.URLError, ConnectionError):
                    time.sleep(.05)
            r.chain()
            if args.serve:
                print(f"READY {output / 'manifest.json'}; Ctrl-C to stop Anvil", flush=True)
                while node.poll() is None:
                    time.sleep(1)
                raise RuntimeError("Anvil exited unexpectedly")
        check(hashes() == before, "Original contract/test files changed")
        print("PASS original contracts/tests unchanged; no public RPC or user signer used", flush=True)
    except KeyboardInterrupt:
        print("Stopped local fixture", flush=True)
        raise SystemExit(130)
    finally:
        if node and node.poll() is None:
            node.terminate()
            node.wait(timeout=10)
        check(hashes() == before, "Original contract/test files changed")
        # Keep explicit output for review; otherwise remove the disposable workspace.
        if not args.output:
            shutil.rmtree(output)


if __name__ == "__main__":
    main()
