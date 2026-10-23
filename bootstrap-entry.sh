#!/bin/sh
# Minimal entry point for clean Debian/Ubuntu/RHEL-family containers.
set -eu
if [ "$(id -u)" -ne 0 ]; then echo "Run as root." >&2; exit 1; fi
if ! command -v curl >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates curl
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y ca-certificates curl
  else
    echo "Cannot automatically install curl on this Linux distribution." >&2
    exit 1
  fi
fi
curl -fsSL --retry 3 https://raw.githubusercontent.com/Ceyeberkepp/ehrnow/main/bootstrap-container.sh -o /tmp/ehrnow-bootstrap.sh
exec bash /tmp/ehrnow-bootstrap.sh
