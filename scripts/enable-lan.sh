#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[ -f .env.private ] || { echo "Run install-private.sh first." >&2; exit 1; }
ip="${1:-}"
if [ -z "$ip" ]; then
  echo "Specify the private IPv4 address assigned to this server."
  echo "Available addresses:"
  hostname -I
  echo "Usage: bash scripts/enable-lan.sh 192.168.1.50"
  exit 2
fi
case "$ip" in
  10.*|192.168.*|172.*) ;;
  *) echo "Refusing non-private address. Use a private server IP." >&2; exit 1 ;;
esac
python3 - "$ip" <<'PY'
import ipaddress,sys
ip=ipaddress.IPv4Address(sys.argv[1])
if not ip.is_private or ip.is_loopback or ip.is_link_local:
  raise SystemExit("Expected a private network address")
PY
if ! ip -o -4 addr show | grep -Fq "inet $ip/"; then
  echo "That IP is not assigned to this server." >&2
  exit 1
fi
chmod 600 .env.private
sed -i '/^EHR_WEB_BIND_IP=/d' .env.private
printf 'EHR_WEB_BIND_IP=%s\n' "$ip" >> .env.private
docker compose --env-file .env.private -f compose.private.yml up -d --no-deps --force-recreate web
echo "Open EHRNow at http://$ip:5173 on the same private network."
echo "Protect server access, never forward port 5173 to the Internet, and keep token private."
