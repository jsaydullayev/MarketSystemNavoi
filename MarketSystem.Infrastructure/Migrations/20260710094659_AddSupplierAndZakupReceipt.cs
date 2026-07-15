using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddSupplierAndZakupReceipt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "ReceiptId",
                table: "Zakups",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Suppliers",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    Name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Phone = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    Address = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    Comment = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    MarketId = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Suppliers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_Suppliers_Markets_MarketId",
                        column: x => x.MarketId,
                        principalTable: "Markets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "ZakupReceipts",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    SupplierId = table.Column<Guid>(type: "uuid", nullable: true),
                    InvoiceNumber = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    TotalAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    PaidAmount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    PaymentStatus = table.Column<int>(type: "integer", nullable: false),
                    Comment = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    CreatedByAdminId = table.Column<Guid>(type: "uuid", nullable: false),
                    MarketId = table.Column<int>(type: "integer", nullable: false),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ZakupReceipts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ZakupReceipts_Markets_MarketId",
                        column: x => x.MarketId,
                        principalTable: "Markets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ZakupReceipts_Suppliers_SupplierId",
                        column: x => x.SupplierId,
                        principalTable: "Suppliers",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                    table.ForeignKey(
                        name: "FK_ZakupReceipts_Users_CreatedByAdminId",
                        column: x => x.CreatedByAdminId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Zakups_ReceiptId",
                table: "Zakups",
                column: "ReceiptId");

            migrationBuilder.CreateIndex(
                name: "IX_Suppliers_MarketId",
                table: "Suppliers",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_Suppliers_MarketId_Name",
                table: "Suppliers",
                columns: new[] { "MarketId", "Name" });

            migrationBuilder.CreateIndex(
                name: "IX_ZakupReceipt_Market_CreatedAt_Desc",
                table: "ZakupReceipts",
                columns: new[] { "MarketId", "CreatedAt" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_ZakupReceipts_CreatedByAdminId",
                table: "ZakupReceipts",
                column: "CreatedByAdminId");

            migrationBuilder.CreateIndex(
                name: "IX_ZakupReceipts_MarketId",
                table: "ZakupReceipts",
                column: "MarketId");

            migrationBuilder.CreateIndex(
                name: "IX_ZakupReceipts_SupplierId",
                table: "ZakupReceipts",
                column: "SupplierId");

            // ── Back-fill: wrap every pre-existing single-line Zakup in its own
            // 1-item receipt so the whole history has one uniform shape and the
            // ReceiptId FK below validates. Legacy purchases are marked Paid
            // (PaymentStatus=2) with no supplier so they never create phantom
            // supplier debt. Idempotent: only rows with a NULL ReceiptId. ──
            migrationBuilder.Sql(@"
                CREATE EXTENSION IF NOT EXISTS pgcrypto;
                DO $$
                DECLARE r RECORD; new_id uuid;
                BEGIN
                    FOR r IN
                        SELECT ""Id"", ""MarketId"", ""CreatedByAdminId"", ""CreatedAt"", ""Quantity"", ""CostPrice""
                        FROM ""Zakups"" WHERE ""ReceiptId"" IS NULL
                    LOOP
                        new_id := gen_random_uuid();
                        INSERT INTO ""ZakupReceipts""
                            (""Id"", ""SupplierId"", ""InvoiceNumber"", ""TotalAmount"", ""PaidAmount"",
                             ""PaymentStatus"", ""Comment"", ""CreatedByAdminId"", ""MarketId"", ""CreatedAt"")
                        VALUES
                            (new_id, NULL, NULL, r.""Quantity"" * r.""CostPrice"", r.""Quantity"" * r.""CostPrice"",
                             2, NULL, r.""CreatedByAdminId"", r.""MarketId"", r.""CreatedAt"");
                        UPDATE ""Zakups"" SET ""ReceiptId"" = new_id WHERE ""Id"" = r.""Id"";
                    END LOOP;
                END $$;
            ");

            migrationBuilder.AddForeignKey(
                name: "FK_Zakups_ZakupReceipts_ReceiptId",
                table: "Zakups",
                column: "ReceiptId",
                principalTable: "ZakupReceipts",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Zakups_ZakupReceipts_ReceiptId",
                table: "Zakups");

            migrationBuilder.DropTable(
                name: "ZakupReceipts");

            migrationBuilder.DropTable(
                name: "Suppliers");

            migrationBuilder.DropIndex(
                name: "IX_Zakups_ReceiptId",
                table: "Zakups");

            migrationBuilder.DropColumn(
                name: "ReceiptId",
                table: "Zakups");
        }
    }
}
