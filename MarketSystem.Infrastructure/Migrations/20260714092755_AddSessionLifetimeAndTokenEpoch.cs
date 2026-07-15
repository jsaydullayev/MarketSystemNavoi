using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSessionLifetimeAndTokenEpoch : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "TokensInvalidBeforeUtc",
                table: "Users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "SessionStartedAt",
                table: "RefreshTokens",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UsedAt",
                table: "RefreshTokens",
                type: "timestamp with time zone",
                nullable: true);

            // BACK-FILL — MAJBURIY. EF yangi ustunga 0001-01-01 default qo'yadi.
            // Mutlaq sessiya limiti (SessionStartedAt + MaxSessionDays < now)
            // shartiga qaraydi — ya'ni deploy paytida MAVJUD har bir sessiya
            // darhol "muddati o'tgan" bo'lib qolar va hamma foydalanuvchi
            // tizimdan chiqib ketardi. Zanjir boshlanishini token yaratilgan
            // vaqtga tenglashtiramiz (semantik jihatdan ham to'g'ri).
            migrationBuilder.Sql(
                """
                UPDATE "RefreshTokens"
                SET "SessionStartedAt" = "CreatedAt"
                WHERE "SessionStartedAt" <= TIMESTAMPTZ '0001-01-02 00:00:00Z';
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "TokensInvalidBeforeUtc",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "SessionStartedAt",
                table: "RefreshTokens");

            migrationBuilder.DropColumn(
                name: "UsedAt",
                table: "RefreshTokens");
        }
    }
}
