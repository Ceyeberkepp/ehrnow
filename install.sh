#!/usr/bin/env bash
set -Eeuo pipefail
cd "$(dirname "$0")"
printf '%s\n' 'EHRNow one-click LOCAL DEVELOPMENT installer (synthetic data only)'
if ! command -v docker >/dev/null 2>&1; then
  echo 'Docker is required. Install Docker Desktop or Docker Engine with Compose first.' >&2
  exit 1
fi
if ! docker info >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  echo 'Start Docker and enable the Docker Compose plugin, then retry.' >&2
  exit 1
fi
if [[ ! -f .env.installer ]]; then
  if ! command -v openssl >/dev/null 2>&1; then echo 'OpenSSL is required to generate secure local credentials.' >&2; exit 1; fi
  (umask 077; printf 'EHR_DEV_TOKEN=%s\nEHR_DB_PASSWORD=%s\n' "$(openssl rand -hex 32)" "$(openssl rand -hex 24)" > .env.installer)
  echo 'Created private .env.installer credentials.'
fi
if ! grep -q '^EHR_WEB_BIND_IP=' .env.installer; then
  printf 'EHR_WEB_BIND_IP=0.0.0.0\n' >> .env.installer
fi
docker compose --env-file .env.installer -f compose.installer.yaml up -d --build --wait
echo ''
echo "Open http://$(hostname -I | awk '{print $1}'):5173 from a trusted LAN device"
echo 'WARNING: HTTP is unencrypted. Development only; never use with real patient records.'
echo 'Development token is saved in .env.installer (keep this file private).'
echo 'Only fictional data; do NOT use for patient care or expose to the internet.'
