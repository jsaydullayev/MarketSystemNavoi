using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddProductNameUniquePerMarket : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Defensive dedup before the unique index — production may already
            // contain duplicate (MarketId, Name) rows from before this rule
            // existed. We rename the OLDER copies so the unique index can be
            // created safely. The newest (by CreatedAt) keeps the original
            // name; the rest get a "(dup-<id>)" suffix and stay queryable.
            migrationBuilder.Sql(@"
                WITH duplicates AS (
                    SELECT ""Id"",
                           ROW_NUMBER() OVER (
                               PARTITION BY ""MarketId"", ""Name""
                               ORDER BY ""CreatedAt"" DESC, ""Id""
                           ) AS rn
                    FROM ""Products""
                    WHERE ""IsDeleted"" = false
                )
                UPDATE ""Products"" p
                SET ""Name"" = LEFT(p.""Name"", 180) || ' (dup-' || LEFT(p.""Id""::text, 8) || ')'
                FROM duplicates d
                WHERE p.""Id"" = d.""Id"" AND d.rn > 1;
            ");

            migrationBuilder.CreateIndex(
                name: "IX_Products_MarketId_Name_Active",
                table: "Products",
                columns: new[] { "MarketId", "Name" },
                unique: true,
                filter: "\"IsDeleted\" = false");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_Products_MarketId_Name_Active",
                table: "Products");
        }
    }
}
