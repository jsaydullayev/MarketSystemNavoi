using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MarketSystem.Infrastructure.Migrations
{
    /// <summary>
    /// K2 + K3 — Optimistic-concurrency tokens on CashRegister and Debt.
    ///
    /// PostgreSQL exposes <c>xmin</c> as a built-in SYSTEM column on every
    /// table — it's not a column we add. The EF model in AppDbContext maps
    /// each entity's <c>Xmin</c> property to that system column via
    /// <c>HasColumnName("xmin").HasColumnType("xid").IsConcurrencyToken()</c>.
    /// EF's auto-scaffold of this migration tried to <c>AddColumn xmin</c>,
    /// which would error <c>42701: column "xmin" of relation already exists</c>
    /// on PostgreSQL. So Up/Down are no-ops at the DDL level — we keep the
    /// migration so the model snapshot stays in sync with the EF mapping.
    ///
    /// Pattern is identical to the Sale.Xmin / Product.Xmin tokens added in
    /// <c>20260512084247_MultiTenancyAndConcurrency</c>; see that migration's
    /// in-line comment "we do NOT add a column" for the matching example.
    /// </summary>
    public partial class AddXminToCashRegisterAndDebt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // No DDL — xmin is a PostgreSQL system column, not a user-defined one.
            // The EF mapping in AppDbContext.OnModelCreating is what wires it
            // up to optimistic concurrency.
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // No DDL — dropping the EF mapping is done by reverting the model;
            // the xmin system column itself cannot be dropped.
        }
    }
}
