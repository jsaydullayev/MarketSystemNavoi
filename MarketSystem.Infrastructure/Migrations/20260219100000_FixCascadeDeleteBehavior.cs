using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixCascadeDeleteBehavior : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Drop foreign keys with old cascade behavior
            migrationBuilder.DropForeignKey(
                name: "IX_SaleItem_ProductId",
                table: "SaleItems");

            migrationBuilder.DropForeignKey(
                name: "IX_Zakups_ProductId",
                table: "Zakups");

            migrationBuilder.DropForeignKey(
                name: "IX_Sales_SellerId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "IX_Sales_CustomerId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "IX_Debts_CustomerId",
                table: "Debts");

            migrationBuilder.DropForeignKey(
                name: "IX_DebtAuditLogs_SaleId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "IX_DebtAuditLogs_SaleItemId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "IX_DebtAuditLogs_ChangedByUserId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "IX_AuditLogs_UserId",
                table: "AuditLogs");

            migrationBuilder.DropForeignKey(
                name: "IX_Zakups_CreatedByAdminId",
                table: "Zakups");

            // Recreate foreign keys with Restrict behavior
            migrationBuilder.AddForeignKey(
                name: "IX_SaleItem_ProductId",
                table: "SaleItems",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_Zakups_ProductId",
                table: "Zakups",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_Sales_SellerId",
                table: "Sales",
                column: "SellerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_Sales_CustomerId",
                table: "Sales",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_Debts_CustomerId",
                table: "Debts",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_DebtAuditLogs_SaleId",
                table: "DebtAuditLogs",
                column: "SaleId",
                principalTable: "Sales",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_DebtAuditLogs_SaleItemId",
                table: "DebtAuditLogs",
                column: "SaleItemId",
                principalTable: "SaleItems",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_DebtAuditLogs_ChangedByUserId",
                table: "DebtAuditLogs",
                column: "ChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_AuditLogs_UserId",
                table: "AuditLogs",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "IX_Zakups_CreatedByAdminId",
                table: "Zakups",
                column: "CreatedByAdminId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Revert to old cascade behavior
            migrationBuilder.DropForeignKey(
                name: "IX_SaleItem_ProductId",
                table: "SaleItems");

            migrationBuilder.DropForeignKey(
                name: "IX_Zakups_ProductId",
                table: "Zakups");

            migrationBuilder.DropForeignKey(
                name: "IX_Sales_SellerId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "IX_Sales_CustomerId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "IX_Debts_CustomerId",
                table: "Debts");

            migrationBuilder.DropForeignKey(
                name: "IX_DebtAuditLogs_SaleId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "IX_DebtAuditLogs_SaleItemId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "IX_DebtAuditLogs_ChangedByUserId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "IX_AuditLogs_UserId",
                table: "AuditLogs");

            migrationBuilder.DropForeignKey(
                name: "IX_Zakups_CreatedByAdminId",
                table: "Zakups");

            // Recreate with default cascade behavior
            migrationBuilder.AddForeignKey(
                name: "IX_SaleItem_ProductId",
                table: "SaleItems",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "IX_Zakups_ProductId",
                table: "Zakups",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "IX_Sales_SellerId",
                table: "Sales",
                column: "SellerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "IX_Sales_CustomerId",
                table: "Sales",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "IX_Debts_CustomerId",
                table: "Debts",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "IX_DebtAuditLogs_SaleId",
                table: "DebtAuditLogs",
                column: "SaleId",
                principalTable: "Sales",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "IX_DebtAuditLogs_SaleItemId",
                table: "DebtAuditLogs",
                column: "SaleItemId",
                principalTable: "SaleItems",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "IX_DebtAuditLogs_ChangedByUserId",
                table: "DebtAuditLogs",
                column: "ChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "IX_AuditLogs_UserId",
                table: "AuditLogs",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "IX_Zakups_CreatedByAdminId",
                table: "Zakups",
                column: "CreatedByAdminId",
                principalTable: "Users",
                principalColumn: "Id");
        }
    }
}
