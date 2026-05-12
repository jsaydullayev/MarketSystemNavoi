using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// Adds the RegistrationRequest table (anonymous sign-up queue managed by
    /// SuperAdmin), gives User a Phone column for owners created from a request,
    /// and enforces a partial unique index so a single phone can have at most
    /// one Pending request at a time. xmin is wired as a concurrency token so
    /// two SuperAdmins can't approve the same request concurrently without
    /// the second one getting a 409.
    /// </summary>
    public partial class AddRegistrationRequests : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "Phone",
                table: "Users",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.CreateTable(
                name: "RegistrationRequests",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uuid", nullable: false),
                    FullName = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Phone = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Status = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ProcessedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ProcessedByUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedUserId = table.Column<Guid>(type: "uuid", nullable: true),
                    CreatedMarketId = table.Column<int>(type: "integer", nullable: true),
                    RejectReason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RegistrationRequests", x => x.Id);
                    table.ForeignKey(
                        name: "FK_RegistrationRequests_Markets_CreatedMarketId",
                        column: x => x.CreatedMarketId,
                        principalTable: "Markets",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_RegistrationRequests_Users_CreatedUserId",
                        column: x => x.CreatedUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_RegistrationRequests_Users_ProcessedByUserId",
                        column: x => x.ProcessedByUserId,
                        principalTable: "Users",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_RegistrationRequests_CreatedAt",
                table: "RegistrationRequests",
                column: "CreatedAt");

            migrationBuilder.CreateIndex(
                name: "IX_RegistrationRequests_CreatedMarketId",
                table: "RegistrationRequests",
                column: "CreatedMarketId");

            migrationBuilder.CreateIndex(
                name: "IX_RegistrationRequests_CreatedUserId",
                table: "RegistrationRequests",
                column: "CreatedUserId");

            // Partial unique index — only ACTIVE pending requests are deduplicated.
            // Rejected applicants can re-apply; approved entries leave behind audit
            // rows that don't block new submissions from the same phone.
            migrationBuilder.CreateIndex(
                name: "IX_RegistrationRequests_Phone_Pending",
                table: "RegistrationRequests",
                column: "Phone",
                unique: true,
                filter: "\"Status\" = 0");

            migrationBuilder.CreateIndex(
                name: "IX_RegistrationRequests_ProcessedByUserId",
                table: "RegistrationRequests",
                column: "ProcessedByUserId");

            migrationBuilder.CreateIndex(
                name: "IX_RegistrationRequests_Status",
                table: "RegistrationRequests",
                column: "Status");

            // xmin is a built-in PostgreSQL system column on every table — we do NOT
            // declare it in the CREATE TABLE, we only map it in the EF model so EF
            // treats it as an optimistic-concurrency token. No DDL required.
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RegistrationRequests");

            migrationBuilder.DropColumn(
                name: "Phone",
                table: "Users");
        }
    }
}
