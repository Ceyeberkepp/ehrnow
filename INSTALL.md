# EHRNow one-click installer — LOCAL DEVELOPMENT ONLY

This runs the existing React UI, Rust clinical API, Go operations process and PostgreSQL using Docker Compose. Docker Desktop (Windows/macOS) or Docker Engine with Compose (Linux) must already be installed and running. The first build downloads images and compiles services.

**Windows:** Double-click `install.cmd` in the repository checkout.  
**Linux/macOS:** From the repository checkout run `bash install.sh`.

Open **http://127.0.0.1:5173** on the same machine. The development token needed by the UI is in the private file `.env.installer`. It is created once and reused on subsequent starts. Never commit or share it. The UI is bound to the host loopback address, and the database/API/Go service are not directly published to the host.

To stop without deleting data:
```sh
docker compose --env-file .env.installer -f compose.installer.yaml down
```

To view logs:
```sh
docker compose --env-file .env.installer -f compose.installer.yaml logs -f
```

**Danger: destructive reset:** Adding `-v` to `down` deletes the database volume. Do not do so unless you intend to lose all local data.

**Not a production installer.** The application still lacks independently validated identity, RBAC, clinical safety, security, privacy, regulatory and recovery controls. Do not connect it to the internet, store real PHI, or use it in patient care. The additional MongoDB/Neo4j/NATS/Redis components are intentionally not installed here because they are not wired into existing clinical workflows.
