# EHRNow one-command Debian/Ubuntu container installation

This installs dependencies, checks Docker Engine/Compose v2, checks out or safely fast-forwards EHRNow, builds services, and publishes the development-only web UI using the container IP.

For a minimal Debian/Ubuntu container run **one command** as root:

```sh
apt-get update && apt-get install -y ca-certificates curl && curl -fsSL --retry 3 https://raw.githubusercontent.com/Ceyeberkepp/ehrnow/main/bootstrap-container.sh -o /tmp/ehrnow-bootstrap.sh && bash /tmp/ehrnow-bootstrap.sh
```

The script will install git/openssl/docker.io and the available distribution Compose package (including Debian 13's `docker-compose`), then start EHRNow. Existing clean checkouts are safely fast-forwarded. Database volumes and existing credentials are preserved. The installer prints `http://<container-ip>:5173`, never `127.0.0.1` as the LAN URL. PostgreSQL and API remain internal to Compose. First-run setup secret and development credentials are stored in `/opt/ehrnow/.env.installer`, not emitted in the terminal.

**Security:** Port 5173 is published on all container interfaces by default, over unencrypted HTTP. Use this only on an isolated test network with synthetic records. Do not expose to the internet or use for patient care. LXC host restrictions, firewalls and unusual network interfaces may require administrator changes outside the container.
