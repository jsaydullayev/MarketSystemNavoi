using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDebtAuditLog : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "DebtAuditLogs",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SaleId = table.Column<Guid>(type: "uuid", nullable: false),
                    SaleItemId = table.Column<Guid>(type: "uuid", nullable: false),
                    OldPrice = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    NewPrice = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    ChangedByUserId = table.Column<Guid>(type: "uuid", nullable: false),
                    Comment = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    MarketId = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_DebtAuditLogs", x => x.Id);
                    table.ForeignKey(
                        name: "FK_DebtAuditLogs_Markets_MarketId",
                        column: x => x.MarketId,
                        principalTable: "Markets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DebtAuditLogs_SaleItems_SaleItemId",
                        column: x => x.SaleItemId,
                        principalTable: "SaleItems",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DebtAuditLogs_Sales_SaleId",
                        column: x => x.SaleId,
                        principalTable: "Sales",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_DebtAuditLogs_Users_ChangedByUserId",
                        column: x => x.ChangedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DebtAuditLog_ChangedBy",
                table: "DebtAuditLogs",
                column: "ChangedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_DebtAuditLog_Sale_CreatedAt",
                table: "DebtAuditLogs",
                columns: new[] { "SaleId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_DebtAuditLog_SaleItem_CreatedAt",
                table: "DebtAuditLogs",
                columns: new[] { "SaleItemId", "CreatedAt" });

            migrationBuilder.CreateIndex(
                name: "IX_DebtAuditLogs_MarketId",
                table: "DebtAuditLogs",
                column: "MarketId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "DebtAuditLogs");
        }
    }
}
