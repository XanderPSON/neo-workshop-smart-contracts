# Public addresses/RPC only. The encrypted dev account is unlocked by Foundry.
# Verification targets must not even parse a learner's local .env.
ifeq ($(filter verify-starter verify-reference verify-completed,$(MAKECMDGOALS)),)
-include .env
export
endif

.PHONY: build test fmt rescue rescue-dry check-env preflight verify-starter verify-reference verify-completed

preflight:
	@bash script/preflight.sh

build:
	forge build

test:
	forge test -vvv

fmt:
	forge fmt

verify-starter:
	bash script/verify-workshop.sh starter

verify-reference:
	bash script/verify-workshop.sh reference

verify-completed:
	bash script/verify-workshop.sh completed

check-env:
	@test -n "$(WALLET_ADDRESS)" || (echo "WALLET_ADDRESS is not set (your public dev address)"; exit 1)
	@test -n "$(BASE_SEPOLIA_RPC)" || (echo "BASE_SEPOLIA_RPC is not set (e.g. https://sepolia.base.org)"; exit 1)

## Behind? Deploy reference V1, a token, and V2. Chain guard permits only 84532/31337.
rescue: check-env
	forge script script/Rescue.s.sol:Rescue --account dev --sender "$(WALLET_ADDRESS)" --rpc-url "$(BASE_SEPOLIA_RPC)" --broadcast

## Simulation only (nothing sent onchain).
rescue-dry: check-env
	forge script script/Rescue.s.sol:Rescue --account dev --sender "$(WALLET_ADDRESS)" --rpc-url "$(BASE_SEPOLIA_RPC)"
