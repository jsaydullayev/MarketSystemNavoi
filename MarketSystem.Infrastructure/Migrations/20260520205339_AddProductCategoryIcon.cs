using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddProductCategoryIcon : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Safe for fresh databases: ProductCategories may not exist yet
            // (it is created with Icon already present by CompensateMissingColumns).
            migrationBuilder.Sql(@"
                ALTER TABLE IF EXISTS ""ProductCategories""
                    ADD COLUMN IF NOT EXISTS ""Icon"" character varying(32);
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER TABLE IF EXISTS ""ProductCategories""
                    DROP COLUMN IF EXISTS ""Icon"";
            ");
        }
    }
}
