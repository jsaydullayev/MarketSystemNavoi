using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class RemoveBranchEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Drop foreign keys from SaleItems and Zakups referencing BranchProducts
            migrationBuilder.DropForeignKey(
                name: "FK_SaleItems_BranchProducts_ProductId_BranchId",
                table: "SaleItems");

            migrationBuilder.DropForeignKey(
                name: "FK_Zakups_Branches_BranchId",
                table: "Zakups");

            migrationBuilder.DropForeignKey(
                name: "FK_Sales_Branches_BranchId",
                table: "Sales");

            // Drop indexes
            migrationBuilder.DropIndex(
                name: "IX_SaleItems_BranchId_ProductId",
                table: "SaleItems");

            migrationBuilder.DropIndex(
                name: "IX_Zakups_BranchId",
                table: "Zakups");

            migrationBuilder.DropIndex(
                name: "IX_Sales_BranchId",
                table: "Sales");

            // Drop BranchId columns
            migrationBuilder.DropColumn(
                name: "BranchId",
                table: "Zakups");

            migrationBuilder.DropColumn(
                name: "BranchId",
                table: "Sales");

            migrationBuilder.DropColumn(
                name: "BranchId",
                table: "SaleItems");

            // Drop BranchProducts table
            migrationBuilder.DropTable(
                name: "BranchProducts");

            // Drop Branches table
            migrationBuilder.DropTable(
                name: "Branches");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Recreate Branches table
            migrationBuilder.CreateTable(
                name: "Branches",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "text", nullable: false),
                    Address = table.Column<string>(type: "text", nullable: true),
                    Phone = table.Column<string>(type: "text", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Branches", x => x.Id);
                });

            // Recreate BranchProducts table
            migrationBuilder.CreateTable(
                name: "BranchProducts",
                columns: table => new
                {
                    BranchId = table.Column<Guid>(type: "uuid", nullable: false),
                    ProductId = table.Column<Guid>(type: "uuid", nullable: false),
                    CostPrice = table.Column<decimal>(type: "numeric", nullable: false),
                    SalePrice = table.Column<decimal>(type: "numeric", nullable: false),
                    MinSalePrice = table.Column<decimal>(type: "numeric", nullable: false),
                    Quantity = table.Column<decimal>(type: "numeric", nullable: false),
                    MinThreshold = table.Column<decimal>(type: "numeric", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BranchProducts", x => new { x.BranchId, x.ProductId });
                    table.ForeignKey(
                        name: "FK_BranchProducts_Branches_BranchId",
                        column: x => x.BranchId,
                        principalTable: "Branches",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_BranchProducts_Products_ProductId",
                        column: x => x.ProductId,
                        principalTable: "Products",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            // Add BranchId columns back
            migrationBuilder.AddColumn<Guid>(
                name: "BranchId",
                table: "SaleItems",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "BranchId",
                table: "Sales",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "BranchId",
                table: "Zakups",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            // Recreate indexes
            migrationBuilder.CreateIndex(
                name: "IX_SaleItems_BranchId_ProductId",
                table: "SaleItems",
                columns: new[] { "BranchId", "ProductId" });

            migrationBuilder.CreateIndex(
                name: "IX_Sales_BranchId",
                table: "Sales",
                column: "BranchId");

            migrationBuilder.CreateIndex(
                name: "IX_Zakups_BranchId",
                table: "Zakups",
                column: "BranchId");

            // Recreate foreign keys
            migrationBuilder.AddForeignKey(
                name: "FK_SaleItems_BranchProducts_ProductId_BranchId",
                table: "SaleItems",
                columns: new[] { "ProductId", "BranchId" },
                principalTable: "BranchProducts",
                principalColumns: new[] { "ProductId", "BranchId" },
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Sales_Branches_BranchId",
                table: "Sales",
                column: "BranchId",
                principalTable: "Branches",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Zakups_Branches_BranchId",
                table: "Zakups",
                column: "BranchId",
                principalTable: "Branches",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
