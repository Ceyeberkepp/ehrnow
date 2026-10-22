#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env.private ] || { echo "Missing .env.private. Run bash scripts/install-private.sh first." >&2; exit 1; }
case "${1:-start}" in
 start)
   docker compose --env-file .env.private -f compose.private.yml --profile db-admin up -d --no-deps adminer
   echo "Database console listening only on server 127.0.0.1:18080."
   echo "From your laptop: ssh -N -L 18080:127.0.0.1:18080 USER@SERVER"
   echo "Then open http://127.0.0.1:18080"
   echo "Login: System PostgreSQL, Server postgres, User ehrdev, Database ehrnow."
   echo "Read database password locally from .env.private; never paste it into chat."
   ;;
 stop)
   docker compose --env-file .env.private -f compose.private.yml --profile db-admin stop adminer
   echo "Database console stopped."
   ;;
 status)
   docker compose --env-file .env.private -f compose.private.yml --profile db-admin ps adminer
   ;;
 *)
   echo "Usage: bash scripts/db-admin.sh [start|stop|status]" >&2; exit 2;;
esac
