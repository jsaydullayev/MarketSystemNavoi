using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// Compensation migration: adds the <c>Products.CategoryId</c> column, its
    /// index, and the FK to <c>ProductCategories</c>.
    ///
    /// Why this is needed: the Product↔ProductCategory relationship
    /// (Product.CategoryId, nullable, ON DELETE SET NULL) was added to the
    /// entity model and the EF model snapshot, but NO migration ever emitted
    /// the physical column — exactly the same class of drift that
    /// <c>CompensateMissingColumns</c> (20260524) was created for, except that
    /// one created the ProductCategories table and forgot the FK column on
    /// Products. On a freshly-migrated database every query EF generates for
    /// Products selects p."CategoryId", which doesn't exist → Postgres 42703
    /// (undefined_column) → the GlobalExceptionHandler maps the unmapped
    /// SqlState to HTTP 503, breaking every market screen (Products,
    /// Categories, Zakups, Reports, New Sale) while login keeps working.
    ///
    /// All statements are idempotent (IF NOT EXISTS / guarded constraint add)
    /// so this is safe on databases that already have the column — including
    /// any instance where it was hot-patched by hand.
    ///
    /// Carries its [Migration]/[DbContext] attributes inline (no Designer.cs),
    /// matching the project's existing hand-written compensation migrations.
    /// Runs AFTER CompensateMissingColumns, so ProductCategories exists by the
    /// time the FK is created.
    /// </summary>
    [DbContext(typeof(AppDbContext))]
    [Migration("20260529120000_CompensateProductCategoryId")]
    public partial class CompensateProductCategoryId : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // ── Products.CategoryId (nullable FK) ────────────────────────
            migrationBuilder.Sql(@"
                ALTER TABLE ""Products""
                    ADD COLUMN IF NOT EXISTS ""CategoryId"" integer;
            ");

            // ── Index for category filtering ─────────────────────────────
            migrationBuilder.Sql(@"
                CREATE INDEX IF NOT EXISTS ""IX_Products_CategoryId""
                    ON ""Products"" (""CategoryId"");
            ");

            // ── FK → ProductCategories, ON DELETE SET NULL ───────────────
            // Guarded so re-running (or running after a manual hot-patch)
            // doesn't error with "constraint already exists".
            migrationBuilder.Sql(@"
                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM pg_constraint
                        WHERE conname = 'FK_Products_ProductCategories_CategoryId'
                    ) THEN
                        ALTER TABLE ""Products""
                            ADD CONSTRAINT ""FK_Products_ProductCategories_CategoryId""
                            FOREIGN KEY (""CategoryId"")
                            REFERENCES ""ProductCategories"" (""Id"")
                            ON DELETE SET NULL;
                    END IF;
                END $$;
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER TABLE ""Products""
                    DROP CONSTRAINT IF EXISTS ""FK_Products_ProductCategories_CategoryId"";
            ");
            migrationBuilder.Sql(@"DROP INDEX IF EXISTS ""IX_Products_CategoryId"";");
            migrationBuilder.Sql(@"
                ALTER TABLE ""Products"" DROP COLUMN IF EXISTS ""CategoryId"";
            ");
        }
    }
}
