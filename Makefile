# Workshop helpers. Reads PRIVATE_KEY and BASE_SEPOLIA_RPC from your shell or a local .env.
-include .env
export

.PHONY: build test fmt rescue rescue-dry check-env

build:
	forge build

test:
	forge test -vvv

fmt:
	forge fmt

check-env:
	@test -n "$(PRIVATE_KEY)" || (echo "PRIVATE_KEY is not set (export it or add it to .env)"; exit 1)
	@test -n "$(BASE_SEPOLIA_RPC)" || (echo "BASE_SEPOLIA_RPC is not set (e.g. https://sepolia.base.org)"; exit 1)

## Behind? Deploys reference PredictionMarket V1, a token, and V2 to Base Sepolia and prints the addresses.
rescue: check-env
	forge script script/Rescue.s.sol:Rescue --rpc-url "$(BASE_SEPOLIA_RPC)" --broadcast

## Same as rescue, but simulation only (nothing is sent onchain).
rescue-dry: check-env
	forge script script/Rescue.s.sol:Rescue --rpc-url "$(BASE_SEPOLIA_RPC)"
