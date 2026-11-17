#!/usr/bin/env bash
# Offline local verification. Never sources .env or uses a user signer.
set -euo pipefail
exec python3 "$(dirname "$0")/verify_workshop.py" "$@"
