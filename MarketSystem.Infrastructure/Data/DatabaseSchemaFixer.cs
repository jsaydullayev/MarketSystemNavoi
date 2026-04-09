using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace MarketSystem.Infrastructure.Data;

public static class DatabaseSchemaFixer
{
    public static async Task FixMissingColumnsAsync(this AppDbContext dbContext, CancellationToken cancellationToken = default)
    {
        try
        {
            var connection = dbContext.Database.GetDbConnection() as NpgsqlConnection;
            if (connection == null) return;

            await connection.OpenAsync(cancellationToken);

            // Fix ProductCategories table
            await FixProductCategoriesTableAsync(connection, cancellationToken);

            // Fix Products table
            await FixProductsTableAsync(connection, cancellationToken);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[DatabaseSchemaFixer] Warning: {ex.Message}");
        }
        finally
        {
            var conn = dbContext.Database.GetDbConnection();
            if (conn.State == System.Data.ConnectionState.Open)
                await conn.CloseAsync();
        }
    }

    private static async Task FixProductCategoriesTableAsync(NpgsqlConnection connection, CancellationToken cancellationToken)
    {
        var command = connection.CreateCommand();
        command.CommandText = @"
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'ProductCategories'
            AND column_name = 'DeletedAt';";

        var exists = await command.ExecuteScalarAsync(cancellationToken) != null;

        if (!exists)
        {
            var addCmd = connection.CreateCommand();
            addCmd.CommandText = @"ALTER TABLE ""ProductCategories"" ADD COLUMN ""DeletedAt"" timestamp with time zone;";
            await addCmd.ExecuteNonQueryAsync(cancellationToken);
            Console.WriteLine("[DatabaseSchemaFixer] Added DeletedAt column to ProductCategories table");
        }
    }

    private static async Task FixProductsTableAsync(NpgsqlConnection connection, CancellationToken cancellationToken)
    {
        // Check and add IsDeleted column
        var checkCmd = connection.CreateCommand();
        checkCmd.CommandText = @"
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'Products'
            AND column_name = 'IsDeleted';";

        var hasIsDeleted = await checkCmd.ExecuteScalarAsync(cancellationToken) != null;

        if (!hasIsDeleted)
        {
            var addCmd = connection.CreateCommand();
            addCmd.CommandText = @"ALTER TABLE ""Products"" ADD COLUMN ""IsDeleted"" boolean NOT NULL DEFAULT false;";
            await addCmd.ExecuteNonQueryAsync(cancellationToken);
            Console.WriteLine("[DatabaseSchemaFixer] Added IsDeleted column to Products table");
        }

        // Check and add DeletedAt column
        checkCmd.CommandText = @"
            SELECT column_name
            FROM information_schema.columns
            WHERE table_name = 'Products'
            AND column_name = 'DeletedAt';";

        var hasDeletedAt = await checkCmd.ExecuteScalarAsync(cancellationToken) != null;

        if (!hasDeletedAt)
        {
            var addCmd = connection.CreateCommand();
            addCmd.CommandText = @"ALTER TABLE ""Products"" ADD COLUMN ""DeletedAt"" timestamp with time zone;";
            await addCmd.ExecuteNonQueryAsync(cancellationToken);
            Console.WriteLine("[DatabaseSchemaFixer] Added DeletedAt column to Products table");
        }
    }
}
