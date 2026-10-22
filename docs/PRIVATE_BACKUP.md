# Private EHRNow development database backup

Run as root on EHRNow:
```bash
cd /root/ehrnow
bash scripts/backup-private.sh
```
This creates a PostgreSQL custom-format logical backup in `/var/backups/ehrnow` (or `EHR_BACKUP_DIR`), validates the archive structure with `pg_restore -l`, records a SHA-256 checksum, and restricts file access to the invoking account. The script does not stop the app, delete records, alter database contents or automatically restore anything.

The archive is unencrypted on disk; keep the backup location private and use encrypted off-host storage if retaining any data. No real patient information is permitted in this development environment. Archive listing checks basic format only: they do not prove a successful restore. Perform periodic restore rehearsals into a separate disposable PostgreSQL instance before relying on these backups.

Never run `docker compose down -v` unless you intentionally intend to destroy test database volumes.
