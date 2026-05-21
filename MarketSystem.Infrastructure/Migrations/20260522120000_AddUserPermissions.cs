using System.Collections.Generic;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddUserPermissions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Owner RBAC — explicit per-user permission set.
            // text[] (empty by default). An empty array means "not customised":
            // the user falls back to its role default at runtime, so existing
            // rows need no data backfill and behaviour is unchanged.
            migrationBuilder.AddColumn<List<string>>(
                name: "Permissions",
                table: "Users",
                type: "text[]",
                nullable: false,
                defaultValueSql: "'{}'::text[]");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Permissions",
                table: "Users");
        }
    }
}
