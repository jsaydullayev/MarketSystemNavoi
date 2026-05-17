using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddMarketBlockFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "BlockedAt",
                table: "Markets",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "BlockedByUserId",
                table: "Markets",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BlockedReason",
                table: "Markets",
                type: "character varying(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsBlocked",
                table: "Markets",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_Markets_Blocked",
                table: "Markets",
                columns: new[] { "Id", "IsBlocked" },
                filter: "\"IsBlocked\" = TRUE");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Markets_Blocked",
                table: "Markets");

            migrationBuilder.DropColumn(
                name: "BlockedAt",
                table: "Markets");

            migrationBuilder.DropColumn(
                name: "BlockedByUserId",
                table: "Markets");

            migrationBuilder.DropColumn(
                name: "BlockedReason",
                table: "Markets");

            migrationBuilder.DropColumn(
                name: "IsBlocked",
                table: "Markets");
        }
    }
}
