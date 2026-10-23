# EHRNow native installation targets (Windows and Linux)

## Non-negotiable packaging contract
- Fresh installations work without Docker, Node, Rust, Go, or a separately installed PostgreSQL server.
- Distribute platform-specific signed packages for Windows x64 (Setup.exe), Linux amd64 (DEB and RPM), and eventually arm64 where binaries are validated.
- Bundle **built** Rust clinical API, Go operations service, React static assets, and a supported PostgreSQL distribution for each platform. Build-time compilers must not be present on the destination machine.
- Install and operate the database using a dedicated least-privilege OS account. Database must listen on a local-only socket/loopback and use generated credentials, never example passwords.
- Provide first-run admin creation, status checks, lifecycle management, backups/restore tests, data-preserving upgrades, secure uninstallation, and rollback.
- Treat PostgreSQL state as application data outside versioned binaries. Uninstall must never silently delete database files.
- Service starts with the OS (Windows Service, systemd) and remains loopback-bound until independent security certification and explicit safe networking configuration.
- Ensure API serves the built UI and same-origin API paths. Vite development server is not suitable for packaged deployment.
- Ensure `EHR_DEV_MODE` restrictions and existing unfinished authentication/multitenancy controls are not misrepresented as production readiness.
- Package and test on clean Windows 11 and Ubuntu/Debian and RHEL-compatible distributions; verify install, restart, upgrade, restore, removal, permissions, and log access.


## Container deployments (equal feature scope)
- Support Linux OCI containers under Docker Engine, Podman, and Kubernetes, as well as appropriately configured Proxmox LXC instances. Build images from the same versioned Rust/Go binaries and React assets used by native packages.
- Support Windows containers only with separately built Windows-compatible images and matched Windows host/container versions; Linux images cannot run as native Windows containers.
- Containers are deployed with images/manifests or container-compatible scripts, not a GUI installation wizard or an operating-system service manager.
- Package deployment templates for Compose and Kubernetes with persistent database volumes, health/readiness probes, non-root processes where possible, and generated secrets supplied through secret stores rather than baked into images.
- Do not embed a PostgreSQL data directory inside an ephemeral app container. Use a persistent managed/local database service or a dedicated stateful database container with durable volumes and verified backups.
- Proxmox LXC must pass explicit nesting, permissions, networking and database persistence preflight checks; do not assume Docker-in-LXC is required.
- Native and container deployments must use equivalent API/database migrations, release versions, setup flows and user-facing features.
- Verify Windows bare metal, Windows VM, Linux bare metal, Linux VM, Docker, Podman, Kubernetes and Proxmox LXC in a release-test matrix before claiming support.

## Current delivery status
The existing Compose development stack and the Windows setup wrapper are **not** compliant with this contract. The wrapper still requires Docker, and no self-contained native binaries or fully functioning Linux package exist yet. OCI/container deployment templates and Windows container builds also require validation. Do not publish them as ready-for-clinical-use artifacts.

## Release gate
Do not handle actual PHI, expose EHRNow to the internet, or use EHRNow for patient care until production authentication, isolation, authorization, encryption, audit integrity, data protection, backup recovery, clinical safety, and regulatory controls have been independently tested and validated.
