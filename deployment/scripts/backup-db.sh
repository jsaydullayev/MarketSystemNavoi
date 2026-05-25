#!/usr/bin/env bash
# =============================================================================
#  PostgreSQL backup — weekly full + daily incremental delta
# =============================================================================
#
#  Variant B strategy (see TELEGRAM_BACKUP.md for the design rationale):
#
#    Sunday              → FULL pg_dump (custom format, gpg-encrypted)
#    Monday … Saturday   → CSV delta of yesterday's rows from time-stamped
#                          tables (Sales, SaleItems, Payments, Customers,
#                          Debts, …), tarred + gzipped + gpg-encrypted.
#
#  Both file kinds are:
#    * dropped on the host under $BACKUP_DIR (14-day retention)
#    * shipped to the private Telegram "recovery" channel via the bot API
#    * encrypted with AES-256 — passphrase only lives in .env on the server
#      and in your SuperAdmin's password manager. Lose it and the backups
#      are useless. Don't lose it.
#
#  Restore (broad strokes — full procedure in TELEGRAM_BACKUP.md):
#    1) decrypt the most recent Sunday FULL into a fresh DB.
#    2) for each newer DELTA in date order, decrypt + tar -xz, then
#       `\copy` each table CSV back in.
#
#  Cron (host):
#    # 02:30 UTC daily — branches on weekday internally.
#    30 2 * * * /root/MarketSystemNavoi/deployment/scripts/backup-db.sh \
#                >> /var/log/marketsystem-backup.log 2>&1
#
#  Required env (.env or shell):
#    DB_NAME              database name                (default: MarketSystemDB)
#    DB_USER              postgres user                (default: postgres)
#    BACKUP_DIR           absolute host path           (default: /var/backups/marketsystem)
#    BACKUP_PASSPHRASE    GPG symmetric passphrase     (REQUIRED)
#    RETENTION_DAYS       local retention              (default: 14)
#    CONTAINER_NAME       docker-compose db container  (default: market-system-db)
#
#  Optional env (Telegram delivery — skipped if either is unset):
#    TELEGRAM_BOT_TOKEN          bot HTTP API token from @BotFather
#    TELEGRAM_RECOVERY_CHAT_ID   private channel ID (negative number, e.g. -1001234567890)
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
DOW="$(date -u +%u)"   # 1 = Monday, 7 = Sunday
log()  { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
fail() { log "ERROR: $*"; tg_notify_failure "$*" || true; exit 1; }

# Telegram notify helpers — silent no-op when bot is not configured.
tg_send_doc() {
    local file="$1" caption="$2"
    [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_RECOVERY_CHAT_ID:-}" ]] && return 0
    if curl -fsS -F document=@"$file" \
         -F chat_id="$TELEGRAM_RECOVERY_CHAT_ID" \
         -F caption="$caption" \
         "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
         > /dev/null; then
        log "Telegram upload OK: $(basename "$file")"
    else
        log "WARN: Telegram upload failed for $(basename "$file"); local copy retained."
    fi
}

tg_notify_failure() {
    [[ -z "${TELEGRAM_BOT_TOKEN:-}" || -z "${TELEGRAM_RECOVERY_CHAT_ID:-}" ]] && return 0
    local msg="$1"
    curl -fsS -X POST \
         -d "chat_id=${TELEGRAM_RECOVERY_CHAT_ID}" \
         -d "text=⚠️ backup-db.sh failed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')%0A${msg}" \
         "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
         > /dev/null || true
}

# Sanity: refuse to run without the GPG passphrase. Unencrypted backups must
# NOT travel through Telegram — the dump contains every password hash, JWT
# secret, audit row, and customer phone number.
[[ -z "${BACKUP_PASSPHRASE:-}" ]] && fail "BACKUP_PASSPHRASE is not set; refusing to produce unencrypted backups."

# ----------------------------------------------------------------------------
# Sunday → FULL pg_dump (custom format).
# ----------------------------------------------------------------------------
do_full_backup() {
    local raw="${BACKUP_DIR}/full-${STAMP}.dump"
    local enc="${raw}.gpg"
    log "Starting FULL backup → ${raw}"

    if ! docker exec "$CONTAINER_NAME" pg_dump \
            --format=custom \
            --no-owner --no-acl \
            --username="$DB_USER" \
            --dbname="$DB_NAME" \
            > "${raw}.partial"; then
        rm -f "${raw}.partial"
        fail "pg_dump failed"
    fi
    if ! head -c 5 "${raw}.partial" | grep -q "PGDMP"; then
        rm -f "${raw}.partial"
        fail "pg_dump produced a non-archive file"
    fi
    mv "${raw}.partial" "$raw"
    chmod 600 "$raw"

    gpg --symmetric --cipher-algo AES256 --batch --yes \
        --passphrase "$BACKUP_PASSPHRASE" -o "$enc" "$raw" \
        || fail "gpg encryption failed for full backup"
    chmod 600 "$enc"

    local size; size="$(du -h "$enc" | cut -f1)"
    log "FULL backup encrypted: $enc ($size)"

    # 50 MB Telegram limit guard — leave a margin for caption/headers.
    local size_mb; size_mb="$(du -m "$enc" | cut -f1)"
    if (( size_mb > 49 )); then
        log "WARN: FULL backup is ${size_mb}MB — exceeds 50MB Telegram limit. Local copy retained, Telegram skipped."
        tg_notify_failure "FULL backup ${size_mb}MB exceeds 50MB Telegram limit. Time to plan the WAL-PITR migration."
    else
        tg_send_doc "$enc" "📦 FULL · $(date -u +'%Y-%m-%d') · ${size_mb}MB · GPG/AES256"
    fi
}

# ----------------------------------------------------------------------------
# Mon-Sat → DELTA: per-table CSV of yesterday's CreatedAt rows.
# ----------------------------------------------------------------------------
# Restore: psql `\copy "Table" FROM '<file>.csv' WITH (FORMAT csv, HEADER true)`
# in the order the tables are listed below (parent → child for FK respect).
#
# UPDATE / DELETE operations are NOT captured here — those live in AuditLogs
# (which is itself in the delta), so the human operator can review and
# re-apply manually for the rare reconstruction case. For full automated
# replay-fidelity, move to WAL archiving (see TELEGRAM_BACKUP.md).
DELTA_TABLES=(
    "Markets"
    "Users"
    "ProductCategories"
    "Products"
    "Customers"
    "Sales"
    "SaleItems"
    "Payments"
    "Debts"
    "DebtAuditLogs"
    "Zakups"
    "CashRegisters"
    "CashWithdrawals"
    "Shifts"
    "RegistrationRequests"
    "AuditLogs"
)

do_delta_backup() {
    local from_utc to_utc workdir tarball enc
    # Yesterday in UTC, [00:00, 24:00). Same window every Mon-Sat run so a
    # missed day stays missed (don't extend the window — pulling 48h on
    # Tuesday would silently overlap Monday's delta).
    from_utc="$(date -u -d 'yesterday' +%Y-%m-%dT00:00:00Z)"
    to_utc="$(date -u +%Y-%m-%dT00:00:00Z)"
    workdir="${BACKUP_DIR}/delta-${STAMP}"
    tarball="${BACKUP_DIR}/delta-${STAMP}.tar.gz"
    enc="${tarball}.gpg"
    mkdir -p "$workdir"
    log "Starting DELTA backup [${from_utc} .. ${to_utc}) → ${workdir}"

    local total_rows=0
    for tbl in "${DELTA_TABLES[@]}"; do
        local out="${workdir}/${tbl}.csv"
        # \copy runs client-side via psql so we don't need a server-side
        # writable directory. Quoted identifier preserves PascalCase.
        if ! docker exec -i "$CONTAINER_NAME" psql \
                --username="$DB_USER" \
                --dbname="$DB_NAME" \
                --quiet --no-align --tuples-only \
                -c "\\copy (SELECT * FROM \"${tbl}\" WHERE \"CreatedAt\" >= '${from_utc}' AND \"CreatedAt\" < '${to_utc}') TO STDOUT WITH (FORMAT csv, HEADER true)" \
                > "$out" 2>/dev/null; then
            log "WARN: delta export failed for ${tbl} (table may not exist on this schema yet); skipping"
            rm -f "$out"
            continue
        fi
        local rows; rows=$(($(wc -l < "$out") - 1))   # subtract header
        if (( rows < 0 )); then rows=0; fi
        if (( rows == 0 )); then
            rm -f "$out"   # don't ship empty per-table files
        else
            total_rows=$((total_rows + rows))
        fi
    done

    # Manifest: one tiny JSON describing which tables were captured.
    # Helpful in restore so the operator can verify the delta covers the
    # expected window.
    cat > "${workdir}/manifest.json" <<EOF
{
  "type": "delta",
  "format": "csv",
  "window": { "fromUtc": "${from_utc}", "toUtc": "${to_utc}" },
  "tables": [$(ls "$workdir"/*.csv 2>/dev/null | xargs -I{} basename {} .csv | awk '{printf "%s\"%s\"", (NR>1?",":""), $0}')],
  "totalRows": ${total_rows},
  "producedAtUtc": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

    tar -czf "$tarball" -C "$BACKUP_DIR" "$(basename "$workdir")" \
        || fail "tar failed"
    rm -rf "$workdir"
    chmod 600 "$tarball"

    gpg --symmetric --cipher-algo AES256 --batch --yes \
        --passphrase "$BACKUP_PASSPHRASE" -o "$enc" "$tarball" \
        || fail "gpg encryption failed for delta"
    rm -f "$tarball"
    chmod 600 "$enc"

    local size_mb; size_mb="$(du -m "$enc" | cut -f1)"
    log "DELTA backup encrypted: $enc (${size_mb}MB, ${total_rows} rows)"

    if (( size_mb > 49 )); then
        log "WARN: DELTA ${size_mb}MB exceeds 50MB Telegram limit; local copy retained, Telegram skipped."
        tg_notify_failure "DELTA ${size_mb}MB exceeds 50MB Telegram limit on $(date -u +'%Y-%m-%d')."
    else
        tg_send_doc "$enc" "🧩 DELTA · $(date -u -d 'yesterday' +'%Y-%m-%d') · ${total_rows} rows · ${size_mb}MB"
    fi
}

# ----------------------------------------------------------------------------
# Dispatch by weekday: Sunday → full, otherwise delta.
# Override via env BACKUP_FORCE=full|delta for the first run / disaster drills.
# ----------------------------------------------------------------------------
case "${BACKUP_FORCE:-auto}" in
    full)  do_full_backup ;;
    delta) do_delta_backup ;;
    auto)
        if [[ "$DOW" == "7" ]]; then
            do_full_backup
        else
            do_delta_backup
        fi
        ;;
    *) fail "Invalid BACKUP_FORCE='${BACKUP_FORCE}' (use full|delta|auto)" ;;
esac

# ----------------------------------------------------------------------------
# Retention — delete encrypted backups older than RETENTION_DAYS.
# Both full-*.dump.gpg and delta-*.tar.gz.gpg are pruned by the same rule.
# ----------------------------------------------------------------------------
log "Pruning backups older than ${RETENTION_DAYS} days"
find "$BACKUP_DIR" -maxdepth 1 -type f \
    \( -name 'full-*.dump.gpg' -o -name 'delta-*.tar.gz.gpg' -o -name '*.dump' \) \
    -mtime "+${RETENTION_DAYS}" -print -delete \
    | sed 's/^/  removed: /' || true

log "Done."
