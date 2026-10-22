#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ip="${1:-127.0.0.1}"
mkdir -p .private-tls
chmod 700 .private-tls
# Reuse existing certificate when its SAN already contains the requested address.
if [ -f .private-tls/server.crt ] && [ -f .private-tls/server.key ] &&
  openssl x509 -in .private-tls/server.crt -noout -checkend 604800 >/dev/null 2>&1 &&
  openssl x509 -in .private-tls/server.crt -noout -ext subjectAltName 2>/dev/null | grep -Fq "IP Address:$ip"; then
  exit 0
fi
umask 077
openssl req -x509 -nodes -newkey rsa:3072 -sha256 -days 365 \
  -keyout .private-tls/server.key -out .private-tls/server.crt \
  -subj "/CN=EHRNow private development" \
  -addext "subjectAltName=IP:127.0.0.1,IP:$ip"
chmod 600 .private-tls/server.key
chmod 644 .private-tls/server.crt
echo "Generated private HTTPS certificate for $ip; browser trust must be configured separately."
