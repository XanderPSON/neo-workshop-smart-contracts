#!/usr/bin/env bash
# Day 1 preflight: `make preflight`. Read-only: checks tools, env, Base Sepolia, and your wallet balance.
set -u
fails=0
ok()   { echo "  ✅ $1"; }
warn() { echo "  ⚠️  $1"; }
bad()  { echo "  ❌ $1"; fails=$((fails+1)); }

echo
echo "NEO Day 1 preflight"
echo

if command -v forge >/dev/null; then ok "$(forge --version | head -1)"; else bad "Foundry missing: install it from https://getfoundry.sh then run foundryup"; fi
if command -v node >/dev/null; then
  major=$(node -p 'process.versions.node.split(".")[0]')
  if [ "$major" -ge 22 ]; then ok "Node $(node -v)"; else bad "Node $(node -v): install Node 22+ (nvm install 22)"; fi
else bad "Node missing: install Node 22+"; fi
if command -v git >/dev/null; then ok "git $(git --version | awk '{print $3}')"; else bad "git missing"; fi

rpc="${BASE_SEPOLIA_RPC:-https://sepolia.base.org}"
chain=$(cast chain-id --rpc-url "$rpc" 2>/dev/null || echo "")
if [ "$chain" = "84532" ]; then ok "Base Sepolia RPC reachable ($rpc)"; else bad "RPC $rpc is not Base Sepolia (got '${chain:-no answer}')"; fi

if [ -z "${PRIVATE_KEY:-}" ]; then
  bad "PRIVATE_KEY not set: add your dev wallet key to .env (never a wallet with real funds)"
else
  addr=$(cast wallet address --private-key "$PRIVATE_KEY" 2>/dev/null || echo "")
  if [ -z "$addr" ]; then bad "PRIVATE_KEY is not a valid private key"; else
    bal=$(cast balance "$addr" --rpc-url "$rpc" -e 2>/dev/null || echo 0)
    if awk "BEGIN{exit !($bal >= 0.001)}"; then ok "Dev wallet $addr has $bal ETH"
    else warn "Dev wallet $addr has $bal ETH: grab Base Sepolia ETH from a faucet (need ~0.001)"; fi
  fi
fi

echo
if [ "$fails" -gt 0 ]; then echo "$fails problem(s) to fix before the session."; exit 1; fi
echo "All set. See you on Day 1."
