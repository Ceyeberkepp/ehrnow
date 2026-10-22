#!/usr/bin/env bash
# Debian 13 one-click prerequisite bootstrap. Does not alter LXC host configuration.
set -euo pipefail
if [ "$(id -u)" -ne 0 ]; then echo "Run as root on a fresh Debian server (or preinstall Docker as an administrator)." >&2; exit 1; fi
. /etc/os-release
if [ "${ID:-}" != debian ] || [ "${VERSION_ID:-}" != 13 ]; then
 echo "Automatic Docker installation currently supports Debian 13 only. Install Docker Engine + Compose manually on this OS." >&2
 exit 1
fi
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl gnupg openssl git
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
arch="$(dpkg --print-architecture)"
cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: trixie
Components: stable
Architectures: $arch
Signed-By: /etc/apt/keyrings/docker.asc
EOF
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker
docker info >/dev/null
docker compose version
if ! docker run --rm hello-world >/dev/null 2>&1; then
 echo "Docker installed but cannot run containers. If this is LXC, check nesting/cgroup/storage restrictions with the LXC host administrator. Do not disable host confinement automatically." >&2
 exit 1
fi
echo "Docker and Compose installed and container execution verified."
