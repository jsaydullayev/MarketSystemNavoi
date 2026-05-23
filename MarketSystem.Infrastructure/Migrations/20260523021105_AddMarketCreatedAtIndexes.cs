using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// P1 + P5 — replace the single-column (MarketId) indexes on Sales and
    /// AuditLogs with composite (MarketId, CreatedAt DESC) indexes.
    ///
    /// The hot list queries on both tables look like:
    ///   WHERE "MarketId" = @market [+ optional filters]
    ///   ORDER BY "CreatedAt" DESC
    ///   LIMIT @page
    ///
    /// With the old single-column index PostgreSQL did an index scan to
    /// find the matching rows, then a separate Sort node — expensive once a
    /// market accumulates 100k+ rows. The DESC composite lets the planner
    /// read the index in reverse order and stream the first @page rows out
    /// without a sort. MarketId stays as the leading column so existence
    /// checks (`AnyAsync(s => s.MarketId == x)`) still get index lookups.
    /// </summary>
    public partial class AddMarketCreatedAtIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Sales_MarketId",
                table: "Sales");

            migrationBuilder.DropIndex(
                name: "IX_AuditLog_MarketId",
                table: "AuditLogs");

            migrationBuilder.CreateIndex(
                name: "IX_Sale_Market_CreatedAt_Desc",
                table: "Sales",
                columns: new[] { "MarketId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_AuditLog_Market_CreatedAt_Desc",
                table: "AuditLogs",
                columns: new[] { "MarketId", "CreatedAt" },
                descending: new[] { false, true });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Sale_Market_CreatedAt_Desc",
                table: "Sales");

            migrationBuilder.DropIndex(
                name: "IX_AuditLog_Market_CreatedAt_Desc",
                table: "AuditLogs");

            migrationBuilder.CreateIndex(
                name: "IX_Sales_MarketId",
                table: "Sales",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_AuditLog_MarketId",
                table: "AuditLogs",
                column: "MarketId");
        }
    }
}
