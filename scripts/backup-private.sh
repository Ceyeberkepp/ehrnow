#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
umask 077
[ -f .env.private ] || { echo "Missing .env.private; install EHRNow first." >&2; exit 1; }
command -v docker >/dev/null || { echo "Docker required" >&2; exit 1; }
backup_dir="${EHR_BACKUP_DIR:-/var/backups/ehrnow}"
mkdir -p "$backup_dir"
chmod 700 "$backup_dir"
if [ -L "$backup_dir" ]; then echo "Refusing symlink backup directory" >&2; exit 1; fi
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
file="$backup_dir/ehrnow-$stamp.dump"
[ ! -e "$file" ] || { echo "Backup path already exists" >&2; exit 1; }
tmp="$(mktemp "$backup_dir/.ehrnow-XXXXXXXX")"
trap 'rm -f "$tmp"' EXIT
echo "Creating PostgreSQL custom-format backup from EHRNow..."
docker compose --env-file .env.private -f compose.private.yml exec -T postgres pg_dump -U ehrdev -d ehrnow -Fc --no-owner --no-privileges > "$tmp"
[ -s "$tmp" ] || { echo "Empty backup; aborting" >&2; exit 1; }
docker compose --env-file .env.private -f compose.private.yml exec -T postgres pg_restore --version >/dev/null
# Host may not have PostgreSQL client. Validate archive with pg_restore in isolated Postgres container.
docker run --rm -i --entrypoint pg_restore postgres:17 -l < "$tmp" >/dev/null
chmod 600 "$tmp"
mv -n "$tmp" "$file"
trap - EXIT
echo "Backup archived: $file"
sha256sum "$file" > "$file.sha256"
chmod 600 "$file.sha256"
echo "Archive structure verified. This is a logical backup; restoration still requires a separate rehearsal."
