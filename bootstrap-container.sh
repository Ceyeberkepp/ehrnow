#!/usr/bin/env bash
# EHRNow development-only one-command container bootstrap. No real patient data.
set -Eeuo pipefail
trap 'echo "EHRNow installer stopped at line $LINENO; inspect the error above." >&2' ERR
if [[ $(id -u) -ne 0 ]]; then echo "Must run as root (or with sudo)." >&2; exit 1; fi
if [[ ! -r /etc/os-release ]]; then echo "Unable to detect Linux distribution." >&2; exit 1; fi
. /etc/os-release
echo "EHRNow development bootstrap: ${PRETTY_NAME:-Linux}"
echo "WARNING: fictional test data only. NOT safe for clinical use or PHI."
export DEBIAN_FRONTEND=noninteractive
if command -v apt-get >/dev/null 2>&1; then
  apt-get update
  apt-get install -y ca-certificates curl git openssl iproute2
elif command -v dnf >/dev/null 2>&1; then
  dnf install -y ca-certificates curl git openssl iproute
else
  echo "Supported installers: Debian/Ubuntu apt or RHEL/Fedora-family dnf." >&2
  exit 1
fi
if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  echo "Installing Docker Engine and Compose..."
  if command -v apt-get >/dev/null 2>&1; then
    case "$ID" in
      debian|ubuntu)
        apt-get install -y docker.io || {
          echo "Distribution docker.io package unavailable. Install a supported Docker Engine package." >&2
          exit 1
        }
        if ! docker compose version >/dev/null 2>&1; then
          if apt-cache show docker-compose >/dev/null 2>&1; then
            apt-get install -y docker-compose
          elif apt-cache show docker-compose-v2 >/dev/null 2>&1; then
            apt-get install -y docker-compose-v2
          elif apt-cache show docker-compose-plugin >/dev/null 2>&1; then
            apt-get install -y docker-compose-plugin
          else
            echo "Docker Compose v2 not available from configured distribution repositories." >&2
            echo "Configure the official Docker repository and rerun this installer." >&2
            exit 1
          fi
        fi
        ;;
      *)
        echo "Automatic Docker installation on this apt distribution is unsupported." >&2
        exit 1
        ;;
    esac
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y moby-engine docker-compose-plugin || {
      echo "Engine/Compose packages not available in configured repositories." >&2
      exit 1
    }
  fi
fi
if command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; then
  systemctl enable --now docker || true
elif command -v service >/dev/null 2>&1; then
  service docker start || true
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker daemon cannot start. If this is Proxmox LXC, verify host nesting, keyctl, cgroups and device permissions." >&2
  echo "An installer inside LXC cannot change privileged settings on the Proxmox host." >&2
  exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
  echo "Docker Compose v2 is unavailable after package installation." >&2
  exit 1
fi
dest=/opt/ehrnow
if [[ -e "$dest" && ! -d "$dest/.git" ]]; then
  echo "$dest exists but is not a Git repository. Refusing to overwrite." >&2
  exit 1
fi
if [[ ! -d "$dest/.git" ]]; then
  git clone --depth=1 https://github.com/Ceyeberkepp/ehrnow.git "$dest"
else
  echo "Checking for repository updates..."
  if [[ -z "$(git -C "$dest" status --porcelain)" ]]; then
    git -C "$dest" pull --ff-only origin main
  else
    echo "Local modifications detected; preserving them and skipping update." >&2
  fi
fi
cd "$dest"
bash ./install.sh
echo "EHRNow local development stack installation completed."
