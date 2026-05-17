using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSaleXminConcurrency : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Drift cleanup: the DB ended up with TWO indexes on Debts.SaleId —
            //   IX_Debt_SaleId   (non-unique, added manually outside migrations)
            //   IX_Debts_SaleId  (UNIQUE, auto-created by the 1:1 Sale↔Debt FK).
            // The EF model wants a single index named IX_Debt_SaleId. We drop the
            // redundant non-unique one first, then rename the unique one into
            // place. Using IF EXISTS so re-running on a clean DB stays no-op.
            migrationBuilder.Sql(@"DROP INDEX IF EXISTS ""IX_Debt_SaleId"";");
            migrationBuilder.Sql(@"ALTER INDEX IF EXISTS ""IX_Debts_SaleId"" RENAME TO ""IX_Debt_SaleId"";");

            // NO DDL for xmin: PostgreSQL exposes xmin as a built-in system column
            // on every table. EF's scaffolder doesn't know that, so it tried to
            // ADD a column — we strip that out. The model-level concurrency token
            // mapping (in AppDbContext.OnModelCreating) is all that's needed.
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"ALTER INDEX IF EXISTS ""IX_Debt_SaleId"" RENAME TO ""IX_Debts_SaleId"";");
        }
    }
}
