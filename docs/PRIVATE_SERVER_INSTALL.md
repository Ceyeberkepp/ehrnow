# EHRNow — private single-user server installation

**Development preview with synthetic records ONLY. Not for real patients or clinical decisions.** The development shared token is not a true user login and is insufficient for a patient-facing EHR.

## Supported host
A dedicated Linux server or Linux VM with Docker Engine + Compose v2, Rust/Cargo, Node.js/npm, OpenSSL and Git. Run under an ordinary dedicated account with Docker access. A member of the Docker group can administer the host: do not grant that access to untrusted users.

## Install once on the server
Clone your authorized repo checkout (prefer a PRIVATE GitHub repository), then:
```bash
cd ehrnow
bash scripts/install-private.sh
bash scripts/run-private.sh
```
The script generates distinct random credentials in `.env.private` (mode 0600); never commit or share it. It uses a dedicated PostgreSQL compose project, stored volume, and port `127.0.0.1:15432`. Existing data in the `ehrnow-private-pgdata` volume is not destroyed on reruns.

Keep the `run-private.sh` session running while using the UI. A controlled restart or reboot requires running that command again; this is not an unattended production service.

## Connect from your own laptop only
Establish an SSH connection from your own computer:
```bash
ssh -N -L 5173:127.0.0.1:5173 -L 8080:127.0.0.1:8080 YOUR_LINUX_USER@YOUR_SERVER
```
Then on that same computer open `http://127.0.0.1:5173`. The React app talks to the forwarded API on `127.0.0.1:8080`. Enter the locally generated `EHR_DEV_TOKEN` from `.env.private` through the UI. Don't paste it into chat, email, tickets or public logs. Only users who can access the server or possess both SSH access and the token can use this development instance; this is not hardened per-user authorization.

If another local service uses ports 5173/8080/15432, resolve the conflict before starting. Do not publish any of these ports using a public reverse proxy, CDN, tunnel, or router port forward.

## Security hardening
- Disable password-based SSH authentication where feasible; use SSH keys (prefer hardware-backed keys) and MFA, plus firewall allowlisting or your VPN.
- Restrict the server login to yourself and trusted administrators; the Docker socket gives root-equivalent host control.
- No remote access to PostgreSQL, MongoDB or Neo4j; this private setup launches PostgreSQL only.
- Set file permissions on the checkout; lock down local shells and backup volumes.
- Backup the private PostgreSQL volume securely. Do not commit .env.private or use real patient information.
- The repo may still be PUBLIC on GitHub despite a proprietary LICENSE. Change repository visibility to Private for source confidentiality.
- Don't interpret this as HIPAA compliance, clinical safety certification, or effective RBAC.

## Stopping
Terminate the `run-private.sh` terminal session. To stop PostgreSQL:
```bash
docker compose --env-file .env.private -f compose.private.yml stop postgres
```
Never run `docker compose down -v` unless you explicitly intend to erase the private test database.

## Troubleshooting
On the server check `curl http://127.0.0.1:8080/health` and Docker status with `docker compose --env-file .env.private -f compose.private.yml ps`. For browser problems check the SSH tunnel and the server Vite output. Check that no external network interfaces are listening on ports 5173, 8080 or 15432.
