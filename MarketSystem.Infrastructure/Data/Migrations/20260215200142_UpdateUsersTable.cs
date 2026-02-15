using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Data.Migrations
{
    /// <inheritdoc />
    public partial class UpdateUsersTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Add MarketId column to Users table
            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "Users",
                type: "integer",
                nullable: false,
                defaultValue: 1);

            // Create index on MarketId
            migrationBuilder.CreateIndex(
                name: "IX_Users_MarketId",
                table: "Users",
                column: "MarketId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Users_MarketId",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "Users");
        }
    }
}
