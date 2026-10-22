#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
ip="${1:-127.0.0.1}"
mkdir -p .private-tls
chgrp 101 .private-tls
chmod 750 .private-tls
fix_tls_permissions() {
  chgrp 101 .private-tls/server.key .private-tls/server.crt
  chmod 640 .private-tls/server.key
  chmod 644 .private-tls/server.crt
}
# Reuse existing certificate when its SAN already contains the requested address.
if [ -f .private-tls/server.crt ] && [ -f .private-tls/server.key ] &&
  openssl x509 -in .private-tls/server.crt -noout -checkend 604800 >/dev/null 2>&1 &&
  openssl x509 -in .private-tls/server.crt -noout -ext subjectAltName 2>/dev/null | grep -Fq "IP Address:$ip"; then
  fix_tls_permissions
  exit 0
fi
umask 077
openssl req -x509 -nodes -newkey rsa:3072 -sha256 -days 365 \
  -keyout .private-tls/server.key -out .private-tls/server.crt \
  -subj "/CN=EHRNow private development" \
  -addext "subjectAltName=IP:127.0.0.1,IP:$ip"
fix_tls_permissions
echo "Generated private HTTPS certificate for $ip; browser trust must be configured separately."
