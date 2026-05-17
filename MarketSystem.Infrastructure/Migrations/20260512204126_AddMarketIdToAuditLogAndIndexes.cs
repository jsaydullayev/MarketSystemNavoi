using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMarketIdToAuditLogAndIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "AuditLogs",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_AuditLog_MarketId",
                table: "AuditLogs",
                column: "MarketId");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Markets_MarketId",
                table: "AuditLogs",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.CreateIndex(
                name: "IX_Debt_SaleId",
                table: "Debts",
                column: "SaleId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Markets_MarketId",
                table: "AuditLogs");

            migrationBuilder.DropIndex(
                name: "IX_AuditLog_MarketId",
                table: "AuditLogs");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "AuditLogs");

            migrationBuilder.DropIndex(
                name: "IX_Debt_SaleId",
                table: "Debts");
        }
    }
}
