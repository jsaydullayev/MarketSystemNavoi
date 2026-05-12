#!/usr/bin/env bash
# =============================================================================
#  PostgreSQL backup — runs against the docker-compose Postgres container
# =============================================================================
#
#  Produces a custom-format pg_dump archive every run, named with a UTC
#  timestamp. Old backups are pruned by retention policy.
#
#  Install (root):
#     # 02:30 UTC daily backup
#     0 2 * * * /root/MarketSystemNavoi/deployment/scripts/backup-db.sh >> /var/log/marketsystem-backup.log 2>&1
#
#  Required env (set in /etc/default/marketsystem-backup or root crontab):
#     BACKUP_DIR        absolute path on host  (default: /var/backups/marketsystem)
#     RETENTION_DAYS    days to keep          (default: 14)
#     DB_NAME / DB_USER from your .env
#     # Optional off-site copy — fill ONE of:
#     S3_BUCKET         s3://bucket/path       (uses aws-cli)
#     REMOTE_SSH_TARGET user@host:/dir         (uses scp)
# =============================================================================

set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-/var/backups/marketsystem}"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
CONTAINER_NAME="${CONTAINER_NAME:-market-system-db}"
DB_NAME="${DB_NAME:-MarketSystemDB}"
DB_USER="${DB_USER:-postgres}"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

STAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
TMP_FILE="${BACKUP_DIR}/marketsystem-${STAMP}.dump.partial"
FINAL_FILE="${BACKUP_DIR}/marketsystem-${STAMP}.dump"

log()  { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
fail() { log "ERROR: $*"; exit 1; }

log "Starting backup -> ${FINAL_FILE}"

# Custom-format dump (-Fc): compact, can be restored selectively with pg_restore.
# We write to a .partial file first, then atomically rename so a half-finished
# dump never looks like a usable backup.
if ! docker exec "$CONTAINER_NAME" pg_dump \
        --format=custom \
        --no-owner --no-acl \
        --username="$DB_USER" \
        --dbname="$DB_NAME" \
        > "$TMP_FILE"; then
    rm -f "$TMP_FILE"
    fail "pg_dump failed"
fi

# Sanity check — pg_dump custom format always starts with the magic bytes "PGDMP".
if ! head -c 5 "$TMP_FILE" | grep -q "PGDMP"; then
    rm -f "$TMP_FILE"
    fail "Dump file does not look like a pg_dump archive."
fi

mv "$TMP_FILE" "$FINAL_FILE"
chmod 600 "$FINAL_FILE"
SIZE="$(du -h "$FINAL_FILE" | cut -f1)"
log "Backup complete (${SIZE})"

# -----------------------------------------------------------------------------
# Optional off-site copy. Either of these is enough; both is fine.
# -----------------------------------------------------------------------------
if [[ -n "${S3_BUCKET:-}" ]]; then
    if ! command -v aws >/dev/null 2>&1; then
        log "WARN: S3_BUCKET set but aws CLI not installed; local copy retained."
    else
        log "Copying to S3: ${S3_BUCKET}"
        aws s3 cp "$FINAL_FILE" "${S3_BUCKET}/" --only-show-errors \
            || log "WARN: S3 upload failed; local copy retained."
    fi
fi
if [[ -n "${REMOTE_SSH_TARGET:-}" ]]; then
    if ! command -v scp >/dev/null 2>&1; then
        log "WARN: REMOTE_SSH_TARGET set but scp not installed; local copy retained."
    else
        log "Copying via scp: ${REMOTE_SSH_TARGET}"
        scp -q -o StrictHostKeyChecking=accept-new "$FINAL_FILE" "$REMOTE_SSH_TARGET" \
            || log "WARN: scp failed; local copy retained."
    fi
fi

# -----------------------------------------------------------------------------
# Retention — delete dumps older than RETENTION_DAYS.
# -----------------------------------------------------------------------------
log "Pruning backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -maxdepth 1 -type f -name 'marketsystem-*.dump' -mtime "+${RETENTION_DAYS}" -print -delete \
    | sed 's/^/  removed: /'

log "Done."
