#!/usr/bin/env bash
# =============================================================================
#  Excel digest → Telegram "Daily" channel
# =============================================================================
#
#  Variant B strategy (see TELEGRAM_BACKUP.md):
#
#    Sunday              → COMPREHENSIVE report Excel (everything-so-far)
#    Monday … Saturday   → DAILY report Excel (yesterday only)
#
#  Both are pulled fresh from the live API as the Owner whose credentials
#  live in $BACKUP_API_USERNAME / $BACKUP_API_PASSWORD. Make this a real
#  Owner account with strong password; the .env must be chmod 600.
#
#  The Excel files are inherently business-readable (no encryption needed
#  to be useful on a phone), so we send them unencrypted. The channel is
#  private and the bot is admin-only — only your SuperAdmin team can read
#  the messages. If you want defense-in-depth, set DIGEST_ENCRYPT=1 and
#  the script will gpg-encrypt the .xlsx before upload.
#
#  Cron (host):
#    # 01:00 UTC daily = 06:00 Tashkent — owner sees yesterday's digest on
#    # the first morning open. Branches on weekday internally.
#    0 1 * * * /root/MarketSystemNavoi/deployment/scripts/send-digest.sh \
#               >> /var/log/marketsystem-digest.log 2>&1
#
#  Required env (.env or shell):
#    BACKUP_API_USERNAME      Owner login                  (REQUIRED)
#    BACKUP_API_PASSWORD      Owner password               (REQUIRED)
#    TELEGRAM_BOT_TOKEN       bot HTTP API token           (REQUIRED)
#    TELEGRAM_DAILY_CHAT_ID   private digest channel ID    (REQUIRED)
#
#  Optional env:
#    API_BASE_URL             default: http://localhost:8080/api
#    DIGEST_LANG              uz | ru   default: uz
#    DIGEST_ENCRYPT           1 to gpg-encrypt the .xlsx before upload
#    BACKUP_PASSPHRASE        required when DIGEST_ENCRYPT=1
#    TELEGRAM_RECOVERY_CHAT_ID where to send failure alerts (default: daily channel)
# =============================================================================

set -euo pipefail

API_BASE_URL="${API_BASE_URL:-http://localhost:8080/api}"
DIGEST_LANG="${DIGEST_LANG:-uz}"
DOW="$(date -u +%u)"                     # 1=Mon … 7=Sun
TARGET_DATE="$(date -u -d 'yesterday' +%Y-%m-%d)"

log()  { printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"; }
fail() { log "ERROR: $*"; tg_notify_failure "$*" || true; exit 1; }

# ----------------------------------------------------------------------------
# Env sanity. Telegram and API creds are required; failing fast is friendlier
# than producing a half-broken cron run.
# ----------------------------------------------------------------------------
for var in BACKUP_API_USERNAME BACKUP_API_PASSWORD TELEGRAM_BOT_TOKEN TELEGRAM_DAILY_CHAT_ID; do
    [[ -z "${!var:-}" ]] && fail "$var is not set"
done

# Failure notifications default to the daily channel; let the recovery
# channel handle them instead if it's configured.
ALERT_CHAT="${TELEGRAM_RECOVERY_CHAT_ID:-$TELEGRAM_DAILY_CHAT_ID}"

tg_notify_failure() {
    local msg="$1"
    curl -fsS -X POST \
         -d "chat_id=${ALERT_CHAT}" \
         -d "text=⚠️ send-digest.sh failed at $(date -u +'%Y-%m-%dT%H:%M:%SZ')%0A${msg}" \
         "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
         > /dev/null || true
}

tg_send_doc() {
    local file="$1" caption="$2"
    if curl -fsS -F document=@"$file" \
            -F chat_id="$TELEGRAM_DAILY_CHAT_ID" \
            -F caption="$caption" \
            "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument" \
            > /dev/null; then
        log "Telegram upload OK: $(basename "$file")"
    else
        fail "Telegram upload failed for $(basename "$file")"
    fi
}

# ----------------------------------------------------------------------------
# 1) Login → access token.
# ----------------------------------------------------------------------------
log "Authenticating against ${API_BASE_URL}/Auth/Login as ${BACKUP_API_USERNAME}"
LOGIN_BODY=$(jq -n \
    --arg u "$BACKUP_API_USERNAME" --arg p "$BACKUP_API_PASSWORD" \
    '{username: $u, password: $p}')

LOGIN_RESP=$(curl -fsS -X POST "${API_BASE_URL}/Auth/Login" \
    -H 'Content-Type: application/json' \
    -d "$LOGIN_BODY") \
    || fail "login HTTP call failed (network / 5xx)"

TOKEN=$(echo "$LOGIN_RESP" | jq -r '.accessToken // empty')
[[ -z "$TOKEN" || "$TOKEN" == "null" ]] && fail "login returned no accessToken (wrong credentials? account locked?)"

# ----------------------------------------------------------------------------
# 2) Pick endpoint by weekday + download the Excel.
# ----------------------------------------------------------------------------
TMP_XLSX="/tmp/digest-$(date -u +%Y%m%d%H%M%S).xlsx"
if [[ "$DOW" == "7" ]]; then
    # Sunday — comprehensive report, dated today (the cumulative view).
    REPORT_DATE="$(date -u +%Y-%m-%d)"
    URL="${API_BASE_URL}/Reports/comprehensive-report/export?date=${REPORT_DATE}&lang=${DIGEST_LANG}"
    LABEL="📊 HAFTALIK · ${REPORT_DATE}"
else
    # Mon-Sat — yesterday's daily report.
    URL="${API_BASE_URL}/Reports/daily/export?date=${TARGET_DATE}&lang=${DIGEST_LANG}"
    LABEL="📊 KUNLIK · ${TARGET_DATE}"
fi

log "Downloading $URL → $TMP_XLSX"
if ! curl -fsS -H "Authorization: Bearer ${TOKEN}" "$URL" -o "$TMP_XLSX"; then
    rm -f "$TMP_XLSX"
    fail "report download failed (HTTP error)"
fi

# Sanity: real xlsx files start with the ZIP magic bytes "PK\x03\x04".
if ! head -c 4 "$TMP_XLSX" | grep -q $'PK\x03\x04'; then
    PREVIEW=$(head -c 200 "$TMP_XLSX" | tr -d '\0')
    rm -f "$TMP_XLSX"
    fail "downloaded file is not a real .xlsx (got: ${PREVIEW:-empty})"
fi

# ----------------------------------------------------------------------------
# 3) (Optional) GPG-encrypt before upload. Off by default — Excel files are
#    designed to be read on the phone without unwrapping.
# ----------------------------------------------------------------------------
SEND_FILE="$TMP_XLSX"
if [[ "${DIGEST_ENCRYPT:-0}" == "1" ]]; then
    [[ -z "${BACKUP_PASSPHRASE:-}" ]] && fail "DIGEST_ENCRYPT=1 but BACKUP_PASSPHRASE is not set"
    ENC="${TMP_XLSX}.gpg"
    gpg --symmetric --cipher-algo AES256 --batch --yes \
        --passphrase "$BACKUP_PASSPHRASE" -o "$ENC" "$TMP_XLSX" \
        || fail "gpg encryption failed"
    rm -f "$TMP_XLSX"
    SEND_FILE="$ENC"
fi

SIZE_KB="$(du -k "$SEND_FILE" | cut -f1)"

# ----------------------------------------------------------------------------
# 4) Build a one-line caption with yesterday's headline stats. Best-effort —
#    if the stats endpoint hiccups, we still ship the file with a plain label.
# ----------------------------------------------------------------------------
CAPTION="${LABEL} · ${SIZE_KB}KB"
if [[ "$DOW" != "7" ]]; then
    STATS_JSON=$(curl -fsS -H "Authorization: Bearer ${TOKEN}" \
        "${API_BASE_URL}/Reports/daily?date=${TARGET_DATE}" 2>/dev/null || echo '{}')
    HEADLINE=$(echo "$STATS_JSON" | jq -r '
        if .totalRevenue or .saleCount or .customerCount then
            "💰 \((.totalRevenue // 0)|tonumber|tostring) UZS · 🧾 \(.saleCount // 0) chek · 👥 \(.customerCount // 0) mijoz"
        else empty end' 2>/dev/null || true)
    [[ -n "$HEADLINE" ]] && CAPTION="${LABEL}%0A${HEADLINE} · ${SIZE_KB}KB"
fi

# ----------------------------------------------------------------------------
# 5) Send + cleanup.
# ----------------------------------------------------------------------------
tg_send_doc "$SEND_FILE" "$CAPTION"
rm -f "$SEND_FILE"
log "Done."
