using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddWithdrawTypeToCashWithdrawal : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "WithdrawType",
                table: "CashWithdrawals",
                type: "text",
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "WithdrawType",
                table: "CashWithdrawals");
        }
    }
}
