using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class MultiTenancyAndConcurrency : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Replace global Users.Username unique index with two partial indexes
            //    (per-market for tenants, global for SuperAdmin / MarketId IS NULL).
            migrationBuilder.DropIndex(
                name: "IX_Users_Username",
                table: "Users");

            // 2. Replace global Customers.Phone unique index with composite (MarketId, Phone).
            migrationBuilder.DropIndex(
                name: "IX_Customers_Phone",
                table: "Customers");

            // 3. SaleItems: align with entity model (external-product fields, nullable ProductId).
            //    These columns reflect the IsExternal / ExternalProductName concept already in the entity.
            migrationBuilder.AlterColumn<Guid>(
                name: "ProductId",
                table: "SaleItems",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

            migrationBuilder.AddColumn<decimal>(
                name: "ExternalCostPrice",
                table: "SaleItems",
                type: "numeric(18,2)",
                precision: 18,
                scale: 2,
                nullable: false,
                defaultValue: 0m);

            migrationBuilder.AddColumn<string>(
                name: "ExternalProductName",
                table: "SaleItems",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsExternal",
                table: "SaleItems",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            // 4. Product optimistic concurrency: PostgreSQL exposes xmin as a built-in system column.
            //    We do NOT add a column — the EF model maps to it. No DDL needed here.

            // 5. Multi-tenancy for CashRegister.
            //    Strategy: add MarketId nullable, dedupe -> assign -> backfill -> NOT NULL + FK + unique.
            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "CashRegisters",
                type: "integer",
                nullable: true);

            // 5a. DE-DUPE first.
            //     If multiple CashRegister rows exist (test/seed accidents), collapse them into a single
            //     "winner" — the most recently updated row — to avoid violating the new unique index.
            //     The losers' balances are summed into the winner so no money is lost.
            migrationBuilder.Sql(@"
                WITH winner AS (
                    SELECT ""Id""
                    FROM ""CashRegisters""
                    ORDER BY ""LastUpdated"" DESC NULLS LAST
                    LIMIT 1
                ),
                loser_total AS (
                    SELECT COALESCE(SUM(""CurrentBalance""), 0) AS total
                    FROM ""CashRegisters""
                    WHERE ""Id"" NOT IN (SELECT ""Id"" FROM winner)
                )
                UPDATE ""CashRegisters""
                SET ""CurrentBalance"" = ""CashRegisters"".""CurrentBalance"" + (SELECT total FROM loser_total)
                WHERE ""Id"" IN (SELECT ""Id"" FROM winner);

                DELETE FROM ""CashRegisters""
                WHERE ""Id"" NOT IN (
                    SELECT ""Id"" FROM ""CashRegisters""
                    ORDER BY ""LastUpdated"" DESC NULLS LAST
                    LIMIT 1
                );
            ");

            // 5b. Assign the remaining (at most 1) register to the oldest market.
            migrationBuilder.Sql(@"
                UPDATE ""CashRegisters""
                SET ""MarketId"" = (SELECT ""Id"" FROM ""Markets"" ORDER BY ""CreatedAt"" ASC LIMIT 1)
                WHERE ""MarketId"" IS NULL;
            ");

            // 5c. Seed an empty register for every market that doesn't yet have one.
            migrationBuilder.Sql(@"
                INSERT INTO ""CashRegisters"" (""Id"", ""CurrentBalance"", ""LastUpdated"", ""LastWithdrawalId"", ""MarketId"")
                SELECT gen_random_uuid(), 0, NOW() AT TIME ZONE 'UTC', NULL, m.""Id""
                FROM ""Markets"" m
                LEFT JOIN ""CashRegisters"" cr ON cr.""MarketId"" = m.""Id""
                WHERE cr.""Id"" IS NULL;
            ");

            // 5d. Remove any orphan registers (e.g. database had no markets at all).
            migrationBuilder.Sql(@"DELETE FROM ""CashRegisters"" WHERE ""MarketId"" IS NULL;");

            // 5e. Enforce NOT NULL now that every row has a MarketId.
            migrationBuilder.AlterColumn<int>(
                name: "MarketId",
                table: "CashRegisters",
                type: "integer",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            // 6. New indexes (created AFTER data migration so they don't fail on duplicates).
            migrationBuilder.CreateIndex(
                name: "IX_Users_MarketId_Username_Unique",
                table: "Users",
                columns: new[] { "MarketId", "Username" },
                unique: true,
                filter: "\"MarketId\" IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Users_Username_GlobalUnique",
                table: "Users",
                column: "Username",
                unique: true,
                filter: "\"MarketId\" IS NULL");

            migrationBuilder.CreateIndex(
                name: "IX_Customers_MarketId_Phone",
                table: "Customers",
                columns: new[] { "MarketId", "Phone" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_CashRegisters_MarketId",
                table: "CashRegisters",
                column: "MarketId",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_CashRegisters_Markets_MarketId",
                table: "CashRegisters",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CashRegisters_Markets_MarketId",
                table: "CashRegisters");

            migrationBuilder.DropIndex(
                name: "IX_Users_MarketId_Username_Unique",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Users_Username_GlobalUnique",
                table: "Users");

            migrationBuilder.DropIndex(
                name: "IX_Customers_MarketId_Phone",
                table: "Customers");

            migrationBuilder.DropIndex(
                name: "IX_CashRegisters_MarketId",
                table: "CashRegisters");

            migrationBuilder.DropColumn(
                name: "ExternalCostPrice",
                table: "SaleItems");

            migrationBuilder.DropColumn(
                name: "ExternalProductName",
                table: "SaleItems");

            migrationBuilder.DropColumn(
                name: "IsExternal",
                table: "SaleItems");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "CashRegisters");

            migrationBuilder.AlterColumn<Guid>(
                name: "ProductId",
                table: "SaleItems",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_Username",
                table: "Users",
                column: "Username",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Customers_Phone",
                table: "Customers",
                column: "Phone",
                unique: true);
        }
    }
}
