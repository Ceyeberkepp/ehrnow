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
if ! grep -q '^EHR_SETUP_KEY=' .env.installer; then
  (umask 077; printf 'EHR_SETUP_KEY=%s\n' "$(openssl rand -hex 32)" >> .env.installer)
fi
if ! grep -q '^EHR_WEB_BIND_IP=' .env.installer; then
  printf 'EHR_WEB_BIND_IP=0.0.0.0\n' >> .env.installer
fi
docker compose --env-file .env.installer -f compose.installer.yaml up -d --build --wait
echo ''
# Prefer the IPv4 address used by the container's default network route.
# Never report internal Docker bridges as the LAN address.
iface=$(ip -4 route show default 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="dev") {print $(i+1); exit}}')
ip=""
if [[ -n "$iface" && ! "$iface" =~ ^(docker|br-|veth|virbr|lo) ]]; then
  ip=$(ip -4 -o addr show dev "$iface" scope global 2>/dev/null | awk 'NR==1 {split($4,a,"/"); print a[1]}')
fi
if [[ -z "$ip" ]]; then
  ip=$(ip -4 -o addr show scope global 2>/dev/null | awk '$2 !~ /^(docker|br-|veth|virbr|lo)/ {split($4,a,"/"); print a[1]; exit}')
fi
if [[ -n "$ip" ]]; then
  echo "Open http://${ip}:5173 from a trusted LAN device"
else
  echo "Unable to detect container IP; use ip -4 addr to locate it."
fi
echo 'First administrator setup key is stored in /opt/ehrnow/.env.installer (keep private).'
echo 'WARNING: HTTP is unencrypted. Development only; never use with real patient records.'
echo 'Development token is saved in .env.installer (keep this file private).'
echo 'Only fictional data; do NOT use for patient care or expose to the internet.'
