using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// Plan 07, Bosqich 5 — make the audit log truly append-only at the DB
    /// level. Two changes:
    ///   1. <c>AuditLogs.UserId</c> FK switches from SET NULL back to RESTRICT
    ///      so no cascade can ever rewrite an audit row. A user with audit
    ///      history can no longer be hard-deleted; UserService.DeleteUserAsync
    ///      soft-deletes instead.
    ///   2. A <c>BEFORE UPDATE OR DELETE</c> trigger raises an exception, so
    ///      even direct SQL (a leaked DB credential, a curious DBA) cannot
    ///      modify or remove an audit row. INSERTs are unaffected — the
    ///      application keeps writing rows normally.
    /// The trigger is PostgreSQL-only; the EF Core InMemory provider used by
    /// the test suite never runs migrations, so it is unaffected.
    /// </summary>
    public partial class AuditLogImmutability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            // Trigger function — raised by every direct UPDATE/DELETE attempt
            // on AuditLogs. INSERTs go nowhere near this and continue to work.
            // CREATE OR REPLACE makes the up migration idempotent if it ever
            // runs twice (e.g. after a partial failure / manual retry).
            migrationBuilder.Sql(
                """
                CREATE OR REPLACE FUNCTION audit_log_block_modify() RETURNS TRIGGER AS $$
                BEGIN
                    RAISE EXCEPTION 'AuditLogs is append-only — % blocked on id=%', TG_OP, OLD."Id";
                END;
                $$ LANGUAGE plpgsql;
                """);

            migrationBuilder.Sql("""DROP TRIGGER IF EXISTS audit_log_immutable ON "AuditLogs";""");

            migrationBuilder.Sql(
                """
                CREATE TRIGGER audit_log_immutable
                    BEFORE UPDATE OR DELETE ON "AuditLogs"
                    FOR EACH ROW EXECUTE FUNCTION audit_log_block_modify();
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""DROP TRIGGER IF EXISTS audit_log_immutable ON "AuditLogs";""");
            migrationBuilder.Sql("DROP FUNCTION IF EXISTS audit_log_block_modify();");

            migrationBuilder.DropForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs");

            migrationBuilder.AddForeignKey(
                name: "FK_AuditLogs_Users_UserId",
                table: "AuditLogs",
                column: "UserId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
