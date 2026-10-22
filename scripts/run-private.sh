#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env.private ] || { echo "Run bash scripts/install-private.sh first" >&2; exit 1; }
umask 077
set -a
source .env.private
set +a
docker compose --env-file .env.private -f compose.private.yml up -d --wait postgres
cleanup(){ kill "${api_pid:-}" "${web_pid:-}" 2>/dev/null || true; wait 2>/dev/null || true; }
trap cleanup EXIT INT TERM
(cd backend/rust/clinical-api && cargo run) &
api_pid=$!
(cd apps/clinician-web && npm run dev -- --host 127.0.0.1 --port 5173 --strictPort) &
web_pid=$!
echo "EHRNow developer services are bound to 127.0.0.1 ON THE SERVER only."
echo "Use SSH port forwarding from your computer to open localhost:5173."
wait -n "$api_pid" "$web_pid" || true
