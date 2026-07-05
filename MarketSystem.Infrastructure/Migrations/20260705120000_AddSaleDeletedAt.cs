using System;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// Adds the nullable <c>DeletedAt</c> timestamp to <c>Sales</c> so an
    /// Owner data-cleanup soft-delete records WHEN a sale was removed (paired
    /// with the existing <c>IsDeleted</c> flag). Null for every active row.
    /// </summary>
    [DbContext(typeof(AppDbContext))]
    [Migration("20260705120000_AddSaleDeletedAt")]
    public partial class AddSaleDeletedAt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "DeletedAt",
                table: "Sales",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "DeletedAt",
                table: "Sales");
        }
    }
}
