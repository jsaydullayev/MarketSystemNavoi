using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// Compensation migration: ensures columns from manually-created migrations
    /// (those without Designer.cs) are present in the database.
    /// All statements are idempotent — safe on databases that already have
    /// these columns and on databases that are missing them.
    ///
    /// Covers:
    ///   20260410_CreateProductCategoriesTable   — ProductCategories table
    ///   20260409_FixProductCategoriesDeletedAt  — ProductCategories.DeletedAt
    ///   20260521120000_AddDueDateToDebt         — Debts.DueDate
    ///   20260522120000_AddUserPermissions       — Users.Permissions  ← crash cause
    /// </summary>
    public partial class CompensateMissingColumns : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ── ProductCategories table ──────────────────────────────────
            migrationBuilder.Sql(@"
                CREATE TABLE IF NOT EXISTS ""ProductCategories"" (
                    ""Id""          SERIAL PRIMARY KEY,
                    ""Name""        TEXT    NOT NULL,
                    ""Description"" TEXT,
                    ""MarketId""    INTEGER NOT NULL,
                    ""IsActive""    BOOLEAN NOT NULL DEFAULT true,
                    ""CreatedAt""   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
                    ""UpdatedAt""   TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
                    ""IsDeleted""   BOOLEAN NOT NULL DEFAULT false,
                    ""DeletedAt""   TIMESTAMP WITH TIME ZONE,
                    ""Icon""        TEXT
                );
                CREATE INDEX IF NOT EXISTS ""IX_ProductCategories_MarketId""
                    ON ""ProductCategories"" (""MarketId"");
                CREATE INDEX IF NOT EXISTS ""IX_ProductCategories_IsDeleted""
                    ON ""ProductCategories"" (""IsDeleted"");
            ");

            // ── ProductCategories.DeletedAt (guard if table pre-existed) ─
            migrationBuilder.Sql(@"
                ALTER TABLE ""ProductCategories""
                    ADD COLUMN IF NOT EXISTS ""DeletedAt"" TIMESTAMP WITH TIME ZONE;
            ");

            // ── ProductCategories.Icon (guard if table pre-existed) ──────
            migrationBuilder.Sql(@"
                ALTER TABLE ""ProductCategories""
                    ADD COLUMN IF NOT EXISTS ""Icon"" TEXT;
            ");

            // ── Debts.DueDate ────────────────────────────────────────────
            migrationBuilder.Sql(@"
                ALTER TABLE ""Debts""
                    ADD COLUMN IF NOT EXISTS ""DueDate"" TIMESTAMP WITH TIME ZONE;
            ");

            // ── Users.Permissions ────────────────────────────────────────
            migrationBuilder.Sql(@"
                ALTER TABLE ""Users""
                    ADD COLUMN IF NOT EXISTS ""Permissions"" TEXT[] NOT NULL DEFAULT '{}'::TEXT[];
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"ALTER TABLE ""Users"" DROP COLUMN IF EXISTS ""Permissions"";");
            migrationBuilder.Sql(@"ALTER TABLE ""Debts"" DROP COLUMN IF EXISTS ""DueDate"";");
            migrationBuilder.Sql(@"ALTER TABLE ""ProductCategories"" DROP COLUMN IF EXISTS ""Icon"";");
            migrationBuilder.Sql(@"ALTER TABLE ""ProductCategories"" DROP COLUMN IF EXISTS ""DeletedAt"";");
        }
    }
}
