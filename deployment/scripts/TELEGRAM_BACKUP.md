# Telegram backup pipeline — operator guide

**Audience:** the SuperAdmin team (whoever has root on the production server).
**Strategy:** Variant B — *weekly full + daily delta*, delivered to two
private Telegram channels via one bot.

```
Sun 02:30 UTC      → 📦 FULL pg_dump.gpg          → recovery channel
Mon-Sat 02:30 UTC  → 🧩 CSV-delta.tar.gz.gpg      → recovery channel

Sun 01:00 UTC      → 📊 Comprehensive Excel        → daily channel
Mon-Sat 01:00 UTC  → 📊 Daily Excel (yesterday)    → daily channel
                       (caption: "💰 X UZS · 🧾 N chek · 👥 M mijoz")
```

`.gpg` files are encrypted with AES-256 using `BACKUP_PASSPHRASE` from
`.env`. Excel files are sent unwrapped by default so they open straight on
the phone (set `DIGEST_ENCRYPT=1` for defense-in-depth — you'll have to
decrypt before opening).

---

## 1 — Bot + channel setup (one-time, ~15 minutes)

### 1.1 Create the bot

1. Open Telegram, search `@BotFather`, send `/newbot`.
2. Name it (e.g. `Strotech Admin Bot`).
3. Username (e.g. `strotech_admin_bot`).
4. BotFather prints a token — looks like `7234234234:AAHabc…`. **Save it**;
   you'll paste this into `.env` as `TELEGRAM_BOT_TOKEN`.

### 1.2 Create the two private channels

For each channel:

1. Telegram → ☰ → **New Channel**.
2. **Channel type: PRIVATE** (no username, no public link). This is the
   security boundary — even if the bot token leaks, an attacker can only
   *post* to the channel, never *read* its history without a member join.
3. Recommended names:
   - `Strotech Recovery` — encrypted `.gpg` backups
   - `Strotech Daily` — readable Excel digests
4. Add the bot as **Administrator** with only **Post Messages** rights
   (no Edit / Delete / Pin / Invite Users — minimum privilege).

### 1.3 Get the channel IDs

A Telegram channel ID looks like `-1001234567890` (negative).

Easiest way:

1. Add `@userinfobot` to the channel temporarily.
2. It prints the channel ID. Save it.
3. Remove `@userinfobot` from the channel.

Alternative (no third-party bot):

```bash
# Forward any message from the channel to @RawDataBot — it prints the
# "forward_from_chat.id" field. That's your channel ID.
```

You should end up with two IDs:
- `TELEGRAM_RECOVERY_CHAT_ID` → recovery channel
- `TELEGRAM_DAILY_CHAT_ID` → daily channel

---

## 2 — Server prerequisites (~5 minutes)

```bash
# GPG for encryption (Ubuntu/Debian).
apt-get install -y gnupg jq

# Verify versions.
gpg --version | head -1     # gpg (GnuPG) 2.x
jq --version                 # jq-1.x

# Generate a strong passphrase. SAVE THIS IN A PASSWORD MANAGER —
# without it the encrypted backups are useless.
openssl rand -hex 32
```

---

## 3 — Wire up `.env` (~5 minutes)

On the production server:

```bash
cd /root/MarketSystemNavoi
cp .env.example .env   # if you haven't already
chmod 600 .env         # only root can read — important
nano .env
```

Fill in the new block at the bottom:

```bash
TELEGRAM_BOT_TOKEN=7234234234:AAH…              # from step 1.1
TELEGRAM_RECOVERY_CHAT_ID=-1001234567890        # from step 1.3 (recovery)
TELEGRAM_DAILY_CHAT_ID=-1009876543210           # from step 1.3 (daily)
BACKUP_PASSPHRASE=<the openssl rand -hex 32 string>
RETENTION_DAYS=14

# Digest authenticates as a real Owner. Use a strong password.
BACKUP_API_USERNAME=strotech_owner
BACKUP_API_PASSWORD=<strong password>
```

---

## 4 — First-run smoke test (~10 minutes)

Force a FULL backup right now (not on a Sunday):

```bash
# Use the same .env the cron will use.
set -a; source /root/MarketSystemNavoi/.env; set +a

BACKUP_FORCE=full bash /root/MarketSystemNavoi/deployment/scripts/backup-db.sh
```

Expected output: a log line like `Telegram upload OK: full-2026-05-25….dump.gpg`
and a new message in your *Recovery* channel:
`📦 FULL · 2026-05-25 · 4MB · GPG/AES256` with the file attached.

Then a DELTA run:

```bash
BACKUP_FORCE=delta bash /root/MarketSystemNavoi/deployment/scripts/backup-db.sh
```

You should see `🧩 DELTA · 2026-05-24 · N rows · NKB` in the same channel.

And the digest:

```bash
bash /root/MarketSystemNavoi/deployment/scripts/send-digest.sh
```

A new message in your *Daily* channel: `📊 KUNLIK · 2026-05-24` (or
`📊 HAFTALIK · …` on Sunday), with the `.xlsx` attached.

If any step fails, the script writes an `⚠️ … failed at …` message to the
recovery channel so you'll notice at a glance.

---

## 5 — Install the cron schedule (~2 minutes)

```bash
crontab -e
```

Append:

```cron
# 02:30 UTC — full on Sunday, delta Mon-Sat. Script branches internally.
30 2 * * * /root/MarketSystemNavoi/deployment/scripts/backup-db.sh >> /var/log/marketsystem-backup.log 2>&1

# 01:00 UTC = 06:00 Tashkent — Excel digest before the owner opens shop.
0 1 * * * /root/MarketSystemNavoi/deployment/scripts/send-digest.sh >> /var/log/marketsystem-digest.log 2>&1
```

Make sure the cron environment can read `.env`. The simplest way:

```bash
# Top of /etc/cron.d/marketsystem (or wrap each command):
SHELL=/bin/bash
BASH_ENV=/root/MarketSystemNavoi/.env
```

…or wrap each entry:

```cron
30 2 * * * . /root/MarketSystemNavoi/.env && /root/MarketSystemNavoi/deployment/scripts/backup-db.sh >> /var/log/marketsystem-backup.log 2>&1
```

---

## 6 — Restore procedure

### Disaster: the production VPS is gone, you have a new server

1. Spin up the new host, install docker, clone the repo, fill `.env`.
2. `docker compose up -d` — the API will create the schema via EF migrations
   and come up with an EMPTY database.
3. Pull the latest **FULL** from the Recovery channel (most recent
   `full-….dump.gpg`). Decrypt:

   ```bash
   gpg --decrypt --batch --passphrase "$BACKUP_PASSPHRASE" \
       -o full.dump full-2026-05-25T02-30-00Z.dump.gpg
   ```

4. Restore it (this overwrites the freshly-created schema with the snapshot):

   ```bash
   docker exec -i market-system-db pg_restore \
       --clean --if-exists \
       --no-owner --no-acl \
       -U postgres -d MarketSystemDB \
       < full.dump
   ```

5. Pull every DELTA newer than the FULL, in date order. For each:

   ```bash
   gpg --decrypt --batch --passphrase "$BACKUP_PASSPHRASE" \
       -o delta.tar.gz delta-2026-05-26T02-30-00Z.tar.gz.gpg
   tar -xzf delta.tar.gz                    # → delta-2026-05-26T…/

   # Each table CSV maps to its PostgreSQL table. Apply parent → child:
   for tbl in Markets Users ProductCategories Products Customers Sales \
              SaleItems Payments Debts DebtAuditLogs Zakups CashRegisters \
              CashWithdrawals Shifts RegistrationRequests AuditLogs; do
       f="delta-2026-05-26T*/$tbl.csv"
       [[ ! -f $f ]] && continue
       docker exec -i market-system-db psql -U postgres -d MarketSystemDB \
           -c "\\copy \"$tbl\" FROM STDIN WITH (FORMAT csv, HEADER true)" < "$f"
   done
   ```

   The `manifest.json` inside each delta tarball lists the window and the
   row count per table — use it to verify nothing was skipped.

6. Restart the API so the in-memory caches (revoked tokens, login-attempt
   tracker) rehydrate from the freshly-restored tables:

   ```bash
   docker compose restart market-system-api
   ```

### Partial: I deleted one record by mistake

You don't need a full restore. Find the row in the latest delta CSV (or
in the FULL via `pg_restore --table=…`), then `\copy` just that one CSV
into the live DB.

### Read a delta without restoring

The CSVs are plain text. After decrypt + tar -xz, open them in Excel /
LibreOffice / VS Code directly.

---

## 7 — Known limits + future work

| Limit | When it bites | Remediation |
|---|---|---|
| Telegram `sendDocument` 50 MB cap | When the encrypted FULL crosses ~50 MB. With current data shape, ~3-5 years away. | Switch the FULL channel to **Variant C** (PostgreSQL WAL archiving + `pg_basebackup`) — see `docs/` (not written yet). |
| DELTA misses UPDATE / DELETE | A row mutated *yesterday* (not inserted) doesn't appear in the CSV. The change still shows in `AuditLogs.csv` (which IS in the delta), but auto-replay isn't possible. | Same — WAL archiving. For now, audit-log review is the manual recovery path. |
| Single bot, single team | All channel members can read every backup. | Telegram channels don't support per-member ACLs. If you need granular access, set up two bots and send distinct subsets. |
| Telegram operators technically see the bytes | They see `<random>.gpg` — opaque without the passphrase. | Already mitigated by the GPG layer. |

---

## 8 — Disabling the pipeline (temporary)

Comment out the Telegram lines in `.env` (or clear `TELEGRAM_BOT_TOKEN`).
The scripts still produce local `.gpg` / `.xlsx` files under
`$BACKUP_DIR`; only the upload step is skipped. Cron entries can stay
running.

---

## 9 — Troubleshooting

```bash
# Tail the logs while a run is happening (or run by hand with the same env).
tail -f /var/log/marketsystem-backup.log
tail -f /var/log/marketsystem-digest.log

# Confirm the bot can reach the channel:
curl -fsS "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
     -d chat_id="${TELEGRAM_RECOVERY_CHAT_ID}" -d text="ping"

# 401 from /Auth/Login → BACKUP_API_USERNAME / PASSWORD wrong.
# 429 from /Auth/Login → the brute-force tracker locked the account.
#                        Wait 15 minutes or reset via DB (TRUNCATE LoginAttempts).
# 403 from /Reports/...  → the user lacks the ReportsAccess permission.
```
