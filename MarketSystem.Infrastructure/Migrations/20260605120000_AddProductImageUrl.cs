using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// Adds the nullable <c>Products.ImageUrl</c> column — a short, server-relative
    /// path to the product's image (e.g. "/uploads/products/12/abc.webp"). The
    /// image bytes live on disk (a persistent Docker volume), never in the DB, so
    /// product-list queries stay cheap.
    ///
    /// Idempotent (ADD COLUMN IF NOT EXISTS) and carries its [Migration]/[DbContext]
    /// attributes inline (no Designer.cs) to match the project's existing
    /// hand-written compensation migrations and avoid the schema-drift class of
    /// bug (model knows the column, DB doesn't → 503 on a fresh database).
    /// </summary>
    [DbContext(typeof(AppDbContext))]
    [Migration("20260605120000_AddProductImageUrl")]
    public partial class AddProductImageUrl : Migration
    {
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER TABLE ""Products""
                    ADD COLUMN IF NOT EXISTS ""ImageUrl"" text;
            ");
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                ALTER TABLE ""Products"" DROP COLUMN IF EXISTS ""ImageUrl"";
            ");
        }
    }
}
