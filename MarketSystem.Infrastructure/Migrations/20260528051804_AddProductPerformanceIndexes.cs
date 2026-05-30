using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddProductPerformanceIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Products_MarketId",
                table: "Products");

            migrationBuilder.CreateIndex(
                name: "IX_Products_LowStock",
                table: "Products",
                column: "MarketId",
                filter: "\"Quantity\" <= \"MinThreshold\" AND \"IsDeleted\" = false");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Products_LowStock",
                table: "Products");

            migrationBuilder.CreateIndex(
                name: "IX_Products_MarketId",
                table: "Products",
                column: "MarketId");
        }
    }
}
