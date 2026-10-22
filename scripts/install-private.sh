#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
if ! command -v docker >/dev/null || ! docker compose version >/dev/null 2>&1; then
  echo "Docker Engine/Compose missing. Installing automatically on supported Debian 13..."
  bash scripts/bootstrap-debian-docker.sh
fi
docker compose version >/dev/null || { echo "Docker Compose v2 unavailable." >&2; exit 1; }
command -v openssl >/dev/null || { echo "OpenSSL is required to generate credentials." >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required for health verification." >&2; exit 1; }
docker info >/dev/null || { echo "Docker daemon not reachable. Check systemctl status docker and LXC nesting restrictions." >&2; exit 1; }
if [ -e .env.private ]; then
  echo "Keeping existing .env.private credentials."
  [ "$(stat -c %a .env.private)" = "600" ] || chmod 600 .env.private
else
  { printf 'EHR_DEV_TOKEN=%s\n' "$(openssl rand -hex 32)"
    printf 'EHR_DB_PASSWORD=%s\n' "$(openssl rand -hex 24)"
  } > .env.private
  chmod 600 .env.private
fi
if ! grep -q '^EHR_SETUP_KEY=' .env.private; then
  printf 'EHR_SETUP_KEY=%s\n' "$(openssl rand -hex 32)" >> .env.private
fi
bash scripts/ensure-private-tls.sh "${EHR_WEB_BIND_IP:-127.0.0.1}"
echo "Building EHRNow (React and Rust) in isolated Docker stages..."
docker compose --env-file .env.private -f compose.private.yml build api web
echo "Starting private services..."
docker compose --env-file .env.private -f compose.private.yml up -d --wait
echo "Checking Rust API ..."
for i in $(seq 1 30); do
  if curl -fsS --max-time 2 http://127.0.0.1:8080/health >/dev/null; then break; fi
  sleep 2
done
curl -fsS --max-time 10 http://127.0.0.1:8080/health >/dev/null || { echo "API health check failed. Check docker compose logs." >&2; exit 1; }
curl -kfsS --max-time 10 https://127.0.0.1:5173/ >/dev/null || { echo "React UI check failed." >&2; exit 1; }
echo "Installed. On your laptop, SSH forward 5173 and 8080; then open https://127.0.0.1:5173."
echo "Token is stored in the server's .env.private file. Do not disclose it."
