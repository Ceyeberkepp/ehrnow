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

## Current delivery status
The existing Compose development stack and the Windows setup wrapper are **not** compliant with this contract. The wrapper still requires Docker, and no self-contained native binaries or fully functioning Linux package exist yet. Do not publish them as ready-for-clinical-use artifacts.

## Release gate
Do not handle actual PHI, expose EHRNow to the internet, or use EHRNow for patient care until production authentication, isolation, authorization, encryption, audit integrity, data protection, backup recovery, clinical safety, and regulatory controls have been independently tested and validated.
