using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class MarketMigration5 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_DebtAuditLogs_SaleItems_SaleItemId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_DebtAuditLogs_Sales_SaleId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_DebtAuditLogs_Users_ChangedByUserId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_Debts_Customers_CustomerId",
                table: "Debts");

            migrationBuilder.DropForeignKey(
                name: "FK_SaleItems_Products_ProductId",
                table: "SaleItems");

            migrationBuilder.DropForeignKey(
                name: "FK_Sales_Customers_CustomerId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "FK_Sales_Users_SellerId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "FK_Zakups_Products_ProductId",
                table: "Zakups");

            migrationBuilder.DropForeignKey(
                name: "FK_Zakups_Users_CreatedByAdminId",
                table: "Zakups");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_DebtAuditLogs_SaleItems_SaleItemId",
                table: "DebtAuditLogs",
                column: "SaleItemId",
                principalTable: "SaleItems",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_DebtAuditLogs_Sales_SaleId",
                table: "DebtAuditLogs",
                column: "SaleId",
                principalTable: "Sales",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_DebtAuditLogs_Users_ChangedByUserId",
                table: "DebtAuditLogs",
                column: "ChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Debts_Customers_CustomerId",
                table: "Debts",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_SaleItems_Products_ProductId",
                table: "SaleItems",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Sales_Customers_CustomerId",
                table: "Sales",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Sales_Users_SellerId",
                table: "Sales",
                column: "SellerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Zakups_Products_ProductId",
                table: "Zakups",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Zakups_Users_CreatedByAdminId",
                table: "Zakups",
                column: "CreatedByAdminId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_DebtAuditLogs_SaleItems_SaleItemId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_DebtAuditLogs_Sales_SaleId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_DebtAuditLogs_Users_ChangedByUserId",
                table: "DebtAuditLogs");

            migrationBuilder.DropForeignKey(
                name: "FK_Debts_Customers_CustomerId",
                table: "Debts");

            migrationBuilder.DropForeignKey(
                name: "FK_SaleItems_Products_ProductId",
                table: "SaleItems");

            migrationBuilder.DropForeignKey(
                name: "FK_Sales_Customers_CustomerId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "FK_Sales_Users_SellerId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "FK_Zakups_Products_ProductId",
                table: "Zakups");

            migrationBuilder.DropForeignKey(
                name: "FK_Zakups_Users_CreatedByAdminId",
                table: "Zakups");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_DebtAuditLogs_SaleItems_SaleItemId",
                table: "DebtAuditLogs",
                column: "SaleItemId",
                principalTable: "SaleItems",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_DebtAuditLogs_Sales_SaleId",
                table: "DebtAuditLogs",
                column: "SaleId",
                principalTable: "Sales",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_DebtAuditLogs_Users_ChangedByUserId",
                table: "DebtAuditLogs",
                column: "ChangedByUserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Debts_Customers_CustomerId",
                table: "Debts",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_SaleItems_Products_ProductId",
                table: "SaleItems",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Sales_Customers_CustomerId",
                table: "Sales",
                column: "CustomerId",
                principalTable: "Customers",
                principalColumn: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Sales_Users_SellerId",
                table: "Sales",
                column: "SellerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Zakups_Products_ProductId",
                table: "Zakups",
                column: "ProductId",
                principalTable: "Products",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Zakups_Users_CreatedByAdminId",
                table: "Zakups",
                column: "CreatedByAdminId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
