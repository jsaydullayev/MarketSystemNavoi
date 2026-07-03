using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddHidePriceFromSellersToProduct : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "HidePriceFromSellers",
                table: "Products",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HidePriceFromSellers",
                table: "Products");
        }
    }
}
