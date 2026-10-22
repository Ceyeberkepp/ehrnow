# EHRNow — private, single-user developer deployment

**Synthetic data only. Not a clinical system, not suitable for PHI or real patient care.**

## Host prerequisites (Linux)
- Linux server or dedicated Linux VM, at least 4 vCPU, 8 GB RAM recommended, ample free disk.
- Docker Engine and Docker Compose v2 are installed automatically if missing on Debian 13, when run as root. Other operating systems require Docker to be preinstalled.
- Git, Bash, OpenSSL and curl on the host.
- Your server's SSH service and an SSH key allowing access for your account.
- Outbound Internet during first build to fetch PostgreSQL, Rust and Node images and dependencies.

**You do NOT need to install Rust, Cargo, Node.js, npm or PostgreSQL on the Linux host.** Their dependencies are included in the Docker build images. On Debian 13, the installer also automatically installs missing Docker Engine/Compose and basic command-line prerequisites. On restricted LXC hosts, the provider must allow nested containers.

## Installation

1. Clone the repository you own, preferably after changing GitHub visibility to **Private**.
2. From the repository root, run:

```bash
bash scripts/install-private.sh
```

This creates `.env.private` using OpenSSL-generated secrets and permissions 0600. It builds the React and Rust images, provisions a dedicated PostgreSQL container, starts the stack and checks localhost API + web responses. The `ehrnow-private-pgdata` volume persists across restarts. Avoid storing production patient data.

## Starting and stopping

Start the services after a reboot using:

```bash
bash scripts/run-private.sh
```

Stop services without deleting test records:

```bash
docker compose --env-file .env.private -f compose.private.yml stop
```

Do NOT run `down -v` unless intentionally deleting the test database.

## Access from your own computer via SSH tunnel

From your own computer, use:

```bash
ssh -N -L 5173:127.0.0.1:5173 -L 8080:127.0.0.1:8080 YOUR_USER@YOUR_SERVER_IP
```

Open `http://127.0.0.1:5173` on your computer. The React app calls the API at `http://127.0.0.1:8080` through the same tunnel. Enter the developer token from `.env.private` on the server (never paste it into chat).

Compose only publishes React and Rust ports on the **server loopback interface**. PostgreSQL is accessible to containers on the dedicated Compose network, not host TCP. Do not configure router forwards, public reverse proxies, Cloudflare tunnels, or public access.

## How to check installation

```bash
docker compose --env-file .env.private -f compose.private.yml ps
curl -fsS http://127.0.0.1:8080/health
curl -fsS http://127.0.0.1:5173/ >/dev/null
```

For errors:

```bash
docker compose --env-file .env.private -f compose.private.yml logs --tail 100 api web postgres
```

If the build fails on first installation, inspect logs and verify the server's RAM, free space, Docker connectivity and outbound network access. Script reruns preserve the generated credentials and database volume.

## Limitations

This is a **private sandbox** deployment, not complete user authentication. Any person holding the shared developer token and server access could operate the sandbox. Production OIDC/MFA, role enforcement, patient isolation, audit validation and clinical safety reviews are not ready. Use Linux SSH key access and server firewall/VPN controls.

Repository source confidentiality requires switching the currently public GitHub repository to Private; a proprietary license alone doesn't hide source files.

## Graphical PostgreSQL database administration

Adminer, a browser-based database manager similar to phpMyAdmin, is included as an optional Docker service. Run `bash scripts/db-admin.sh start`, then create an SSH tunnel forwarding local port 18080 to server localhost 18080 and open `http://127.0.0.1:18080`. See [Database Web GUI](DATABASE_WEB_GUI.md). Run `bash scripts/db-admin.sh stop` after use. Never expose it publicly.
