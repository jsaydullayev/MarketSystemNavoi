# Database migrations runbook

Migrations are applied automatically at API startup — see the migration loop
in `MarketSystem.API/Program.cs`. This runbook covers the cases where you need
manual control: shipping a heavy migration, rolling one back, or recovering
from a half-applied state.

## Default flow (automatic, on every deploy)

1. `deployment/scripts/deploy.sh` rebuilds + starts the API container.
2. API startup runs `dbContext.Database.MigrateAsync()` inside a retry loop
   (5 attempts, 3 s apart) BEFORE binding the HTTP listener.
3. Healthcheck on `/health` only flips green after migration succeeds.
4. If startup never goes healthy, the deploy script tails logs and exits
   non-zero so the operator notices.

## Pre-deploy checklist for a heavy migration

Run through this when the migration touches a lot of rows, adds a NOT-NULL
column with backfill, or rewrites an index.

1. **Back up first.** `bash deployment/scripts/backup-db.sh` produces a
   timestamped pg_dump archive in `/var/backups/marketsystem/`. Verify the
   file size matches recent backups (sanity check it isn't empty).
2. **Dry-run on staging.** Apply the migration to a staging clone before
   production. Watch for long-running statements that would lock prod tables.
3. **Look at the Up()/Down() pair.** Some past migrations (e.g.
   `20260512084247_MultiTenancyAndConcurrency`) include data-migration SQL
   that ISN'T undone by `Down()` — make sure you can live with that if you
   ever roll back.
4. **Confirm `Cors:AllowedOrigins`, `Jwt:Key`, `DATABASE_URL`, and
   `SuperAdmin:ConsoleSegment` are still set** in the production `.env`. The
   sync-migrate loop fails fast if `Jwt:Key` is missing.

## Manual application (rare)

If you need to apply migrations without bringing the API up:

```bash
# From inside the project root, with `dotnet ef` installed locally
ConnectionStrings__DefaultConnection="$(grep DATABASE_URL .env | cut -d= -f2-)" \
    dotnet ef database update \
    --project MarketSystem.Infrastructure \
    --startup-project MarketSystem.API
```

## Rolling back a migration

Roll back to a specific migration name (the one BEFORE the bad one):

```bash
dotnet ef database update <PreviousMigrationName> \
    --project MarketSystem.Infrastructure \
    --startup-project MarketSystem.API
```

If `Down()` doesn't undo the data side (see point 3 above), restore the
pre-migration backup instead:

```bash
# 1. Bring down the API only so connections drain.
docker compose stop market-system-api

# 2. Restore the dump into the running Postgres container.
docker exec -i market-system-db pg_restore \
    --clean --if-exists --no-owner --no-acl \
    -U postgres -d MarketSystemDB \
    < /var/backups/marketsystem/marketsystem-YYYY-MM-DDTHH-MM-SSZ.dump

# 3. Bring the API back up (it'll re-run migrations to whatever HEAD is now).
docker compose up -d market-system-api
```

## Recovering from a partially-applied migration

Symptom: the startup loop fails repeatedly because a previous attempt left the
schema half-changed (e.g. table created but index missing).

1. Look at `__EFMigrationsHistory`:
   ```bash
   docker exec -it market-system-db \
       psql -U postgres -d MarketSystemDB \
       -c 'SELECT * FROM "__EFMigrationsHistory" ORDER BY "MigrationId";'
   ```
   If the failing migration ID is **already in the table**, EF won't retry it.
2. If the table state on disk doesn't match what `__EFMigrationsHistory` says
   was applied: restore the most recent backup (see "Rolling back" above) and
   redeploy.

## Past migrations with non-trivial data steps

These migrations include SQL beyond pure DDL — keep a note when you're
debugging old backups:

| Migration | Data step |
|---|---|
| `20260512084247_MultiTenancyAndConcurrency` | Dedupes `CashRegisters` (keeps newest), assigns each Market a register, fills `MarketId`. Down() does NOT re-split the deduped rows. |
| `20260512115341_AddRegistrationRequests` | None — pure schema. |
