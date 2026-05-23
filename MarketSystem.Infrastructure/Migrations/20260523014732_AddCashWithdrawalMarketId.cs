using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// K2 — Add tenant scope to <c>CashWithdrawals</c>.
    ///
    /// Before this migration, <see cref="MarketSystem.Application.Services.CashRegisterService.GetCashRegisterAsync"/>
    /// inferred the tenant by joining to <c>Users</c> and treating <c>UserId IS NULL</c>
    /// as "ok" — meaning every other tenant's orphaned withdrawal (rows whose user was
    /// hard-deleted historically) leaked into this market's withdrawal list. We now
    /// require <c>CashWithdrawals.MarketId</c> on every row and filter by it directly.
    ///
    /// The Up migration is safe to run on existing data:
    ///   1. Add <c>MarketId</c> as nullable.
    ///   2. Backfill from <c>Users.MarketId</c> for rows that still have a live user FK.
    ///   3. For orphan rows (UserId NULL after a user hard-delete), assign the smallest
    ///      existing market id — this is a quarantine value, NOT a heuristic guess at the
    ///      original tenant. Operators with multi-tenant production data should inspect
    ///      these rows after migration runs and either reassign or delete them. We log
    ///      the affected ids via RAISE NOTICE so they show up in psql output.
    ///   4. Make the column NOT NULL.
    ///   5. Add the FK to <c>Markets</c> (Restrict — never silently cascade audit-adjacent
    ///      cash history) and the composite index for the per-market list query.
    ///
    /// If the <c>Markets</c> table is empty (fresh dev DB with no seed yet),
    /// step 3 short-circuits to a no-op because there are no rows to backfill.
    /// </summary>
    public partial class AddCashWithdrawalMarketId : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Add nullable column.
            migrationBuilder.AddColumn<int>(
                name: "MarketId",
                table: "CashWithdrawals",
                type: "integer",
                nullable: true);

            // 2. Backfill from the linked user.
            migrationBuilder.Sql(
                """
                UPDATE "CashWithdrawals" cw
                SET "MarketId" = u."MarketId"
                FROM "Users" u
                WHERE u."Id" = cw."UserId"
                  AND cw."MarketId" IS NULL;
                """);

            // 3. Quarantine remaining orphans (UserId NULL) into the smallest market.
            //    Logs the affected ids so operators can audit them after the fact.
            //    No-op when there are no markets yet (fresh dev DB).
            migrationBuilder.Sql(
                """
                DO $$
                DECLARE
                    fallback_market_id integer;
                    orphan_count integer;
                    orphan_ids text;
                BEGIN
                    SELECT MIN("Id") INTO fallback_market_id FROM "Markets";

                    IF fallback_market_id IS NULL THEN
                        -- No markets exist yet. Orphan rows are impossible because
                        -- CashWithdrawals references Users which references Markets.
                        RETURN;
                    END IF;

                    SELECT COUNT(*), string_agg("Id"::text, ', ')
                      INTO orphan_count, orphan_ids
                    FROM "CashWithdrawals"
                    WHERE "MarketId" IS NULL;

                    IF orphan_count > 0 THEN
                        RAISE NOTICE 'K2 backfill: quarantining % orphan CashWithdrawal row(s) into MarketId=%. Ids: %',
                            orphan_count, fallback_market_id, orphan_ids;

                        UPDATE "CashWithdrawals"
                        SET "MarketId" = fallback_market_id
                        WHERE "MarketId" IS NULL;
                    END IF;
                END $$;
                """);

            // 4. Make NOT NULL once every row has a value.
            migrationBuilder.AlterColumn<int>(
                name: "MarketId",
                table: "CashWithdrawals",
                type: "integer",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            // 5. Index + FK.
            migrationBuilder.CreateIndex(
                name: "IX_CashWithdrawals_MarketId_WithdrawalDate",
                table: "CashWithdrawals",
                columns: new[] { "MarketId", "WithdrawalDate" });

            migrationBuilder.AddForeignKey(
                name: "FK_CashWithdrawals_Markets_MarketId",
                table: "CashWithdrawals",
                column: "MarketId",
                principalTable: "Markets",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_CashWithdrawals_Markets_MarketId",
                table: "CashWithdrawals");

            migrationBuilder.DropIndex(
                name: "IX_CashWithdrawals_MarketId_WithdrawalDate",
                table: "CashWithdrawals");

            migrationBuilder.DropColumn(
                name: "MarketId",
                table: "CashWithdrawals");
        }
    }
}
