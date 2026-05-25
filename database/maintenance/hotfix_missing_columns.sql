-- ============================================================
-- HOTFIX: Missing columns from manually-created migrations
-- (migrations without Designer.cs that may have been skipped)
--
-- SAFE TO RUN MULTIPLE TIMES — all statements are idempotent.
--
-- Run this directly on the production PostgreSQL database:
--   docker exec -i marketsystem-db psql -U <user> -d <dbname> < hotfix_missing_columns.sql
-- ============================================================

BEGIN;

-- ─────────────────────────────────────────────────────────────────
-- 1. ProductCategories table
--    Migration: 20260410_CreateProductCategoriesTable
-- ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS "ProductCategories" (
    "Id"          SERIAL PRIMARY KEY,
    "Name"        TEXT    NOT NULL,
    "Description" TEXT,
    "MarketId"    INTEGER NOT NULL,
    "IsActive"    BOOLEAN NOT NULL DEFAULT true,
    "CreatedAt"   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "UpdatedAt"   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    "IsDeleted"   BOOLEAN NOT NULL DEFAULT false,
    "DeletedAt"   TIMESTAMP WITH TIME ZONE
);

CREATE INDEX IF NOT EXISTS "IX_ProductCategories_MarketId"
    ON "ProductCategories" ("MarketId");

CREATE INDEX IF NOT EXISTS "IX_ProductCategories_IsDeleted"
    ON "ProductCategories" ("IsDeleted");

-- ─────────────────────────────────────────────────────────────────
-- 2. ProductCategories.DeletedAt column
--    Migration: 20260409_FixProductCategoriesDeletedAt
--    (already included in CREATE TABLE above — this is a no-op guard)
-- ─────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'ProductCategories' AND column_name = 'DeletedAt'
    ) THEN
        ALTER TABLE "ProductCategories" ADD COLUMN "DeletedAt" TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added ProductCategories.DeletedAt';
    ELSE
        RAISE NOTICE 'ProductCategories.DeletedAt already exists — skipped';
    END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 3. Debts.DueDate column
--    Migration: 20260521120000_AddDueDateToDebt
-- ─────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Debts' AND column_name = 'DueDate'
    ) THEN
        ALTER TABLE "Debts" ADD COLUMN "DueDate" TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE 'Added Debts.DueDate';
    ELSE
        RAISE NOTICE 'Debts.DueDate already exists — skipped';
    END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 4. Users.Permissions column  ← THE CURRENT CRASH
--    Migration: 20260522120000_AddUserPermissions
-- ─────────────────────────────────────────────────────────────────
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'Users' AND column_name = 'Permissions'
    ) THEN
        ALTER TABLE "Users"
            ADD COLUMN "Permissions" TEXT[] NOT NULL DEFAULT '{}'::TEXT[];
        RAISE NOTICE 'Added Users.Permissions';
    ELSE
        RAISE NOTICE 'Users.Permissions already exists — skipped';
    END IF;
END;
$$;

-- ─────────────────────────────────────────────────────────────────
-- 5. Sync __EFMigrationsHistory
--    Insert records for any manually-created migrations that may be
--    missing from the history table (prevents MigrateAsync from
--    trying to re-run them and failing).
-- ─────────────────────────────────────────────────────────────────
INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES
    ('20260219100000_FixCascadeDeleteBehavior',    '9.0.0'),
    ('20260409_FixProductCategoriesDeletedAt',      '9.0.0'),
    ('20260410_CreateProductCategoriesTable',       '9.0.0'),
    ('20260521120000_AddDueDateToDebt',             '9.0.0'),
    ('20260522120000_AddUserPermissions',           '9.0.0')
ON CONFLICT ("MigrationId") DO NOTHING;

-- ─────────────────────────────────────────────────────────────────
-- Verify result
-- ─────────────────────────────────────────────────────────────────
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_name IN ('Users', 'Debts', 'ProductCategories')
  AND column_name IN ('Permissions', 'DueDate', 'DeletedAt')
ORDER BY table_name, column_name;

COMMIT;

RAISE NOTICE '✓ Hotfix complete. Restart the application now.';
