#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
for tool in docker cargo npm openssl; do command -v "$tool" >/dev/null || { echo "Missing $tool. Install it before continuing." >&2; exit 1; }; done
docker compose version >/dev/null || { echo "Docker Compose v2 required" >&2; exit 1; }
if [ -e .env.private ]; then
  echo "Private credentials already exist. Refusing to overwrite .env.private."
else
  token="$(openssl rand -hex 32)"
  dbpass="$(openssl rand -hex 24)"
  {
    printf 'EHR_DEV_MODE=1\n'
    printf 'EHR_DEV_TOKEN=%s\n' "$token"
    printf 'EHR_DB_PASSWORD=%s\n' "$dbpass"
    printf 'DATABASE_URL=postgres://ehrdev:%s@127.0.0.1:15432/ehrnow\n' "$dbpass"
  } > .env.private
  chmod 600 .env.private
fi
set -a
# Generated values contain only hex characters and known literals.
source .env.private
set +a
docker compose --env-file .env.private -f compose.private.yml up -d --wait postgres
echo "Preparing Rust API ..."
(cd backend/rust/clinical-api && cargo build)
echo "Preparing React app ..."
(cd apps/clinician-web && npm ci)
echo "Private install ready. Run: bash scripts/run-private.sh"
echo "Credentials are in .env.private (owner-readable only). Do not share them."
