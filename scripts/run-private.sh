#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env.private ] || { echo "Run bash scripts/install-private.sh first." >&2; exit 1; }
docker compose --env-file .env.private -f compose.private.yml up -d --wait
docker compose --env-file .env.private -f compose.private.yml ps
echo "Private server started. Connect with SSH port forwarding for 5173 and 8080."
