using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace MarketSystem.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class newmigration92921 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "Zakups",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "Sales",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "Products",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "Debts",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "Customers",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "CashRegisters",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "Markets",
                columns: table => new
                {
                    Id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Subdomain = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Markets", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Zakups_MarketId",
                table: "Zakups",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_Users_MarketId",
                table: "Users",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_Sales_MarketId",
                table: "Sales",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_Products_MarketId",
                table: "Products",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_Debts_MarketId",
                table: "Debts",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_Customers_MarketId",
                table: "Customers",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_CashRegisters_MarketId",
                table: "CashRegisters",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_Markets_Subdomain",
                table: "Markets",
                column: "Subdomain",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_CashRegisters_Markets_MarketId",
                table: "CashRegisters",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Customers_Markets_MarketId",
                table: "Customers",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Debts_Markets_MarketId",
                table: "Debts",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Products_Markets_MarketId",
                table: "Products",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Sales_Markets_MarketId",
                table: "Sales",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Users_Markets_MarketId",
                table: "Users",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Zakups_Markets_MarketId",
                table: "Zakups",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CashRegisters_Markets_MarketId",
                table: "CashRegisters");

            migrationBuilder.DropForeignKey(
                name: "FK_Customers_Markets_MarketId",
                table: "Customers");

            migrationBuilder.DropForeignKey(
                name: "FK_Debts_Markets_MarketId",
                table: "Debts");

            migrationBuilder.DropForeignKey(
                name: "FK_Products_Markets_MarketId",
                table: "Products");

            migrationBuilder.DropForeignKey(
                name: "FK_Sales_Markets_MarketId",
                table: "Sales");

            migrationBuilder.DropForeignKey(
                name: "FK_Users_Markets_MarketId",
                table: "Users");

            migrationBuilder.DropForeignKey(
                name: "FK_Zakups_Markets_MarketId",
                table: "Zakups");

            migrationBuilder.DropTable(
                name: "Markets");

            migrationBuilder.DropIndex(
                name: "IX_Zakups_MarketId",
                table: "Zakups");

            migrationBuilder.DropIndex(
                name: "IX_Users_MarketId",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Sales_MarketId",
                table: "Sales");

            migrationBuilder.DropIndex(
                name: "IX_Products_MarketId",
                table: "Products");

            migrationBuilder.DropIndex(
                name: "IX_Debts_MarketId",
                table: "Debts");

            migrationBuilder.DropIndex(
                name: "IX_Customers_MarketId",
                table: "Customers");

            migrationBuilder.DropIndex(
                name: "IX_CashRegisters_MarketId",
                table: "CashRegisters");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "Zakups");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "Sales");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "Products");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "Debts");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "Customers");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "CashRegisters");
        }
    }
}
