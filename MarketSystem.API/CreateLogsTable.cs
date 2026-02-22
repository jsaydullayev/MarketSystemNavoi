using Microsoft.EntityFrameworkCore;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.API.Migrations;

/// <summary>
/// Temporary script to create Logs table
/// Run this once to create the table, then you can delete this file
/// Usage: dotnet run --project MarketSystem.API --create-logs
/// </summary>
public class CreateLogsTableScript
{
    public static async Task Main(string[] args)
    {
        var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
        optionsBuilder.UseNpgsql("Host=localhost;Port=3030;Database=MarketSystemDB;Username=postgres;Password=postgres");

        using var context = new AppDbContext(optionsBuilder.Options);

        // Create Logs table
        var createTableSql = @"
            CREATE TABLE IF NOT EXISTS ""Logs"" (
                ""Id"" serial PRIMARY KEY,
                ""Timestamp"" timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'UTC'),
                ""Level"" varchar(10) NOT NULL,
                ""Message"" text,
                ""MessageTemplate"" text,
                ""Properties"" jsonb,
                ""UserName"" varchar(100),
                ""MarketId"" integer,
                ""UserId"" integer,
                ""Exception"" text,
                ""StackTrace"" text,
                CONSTRAINT ""FK_Logs_Users_UserId"" FOREIGN KEY (""UserId"") REFERENCES ""Users""(""Id"") ON DELETE SET NULL,
                CONSTRAINT ""FK_Logs_Markets_MarketId"" FOREIGN KEY (""MarketId"") REFERENCES ""Markets""(""Id"") ON DELETE SET NULL
            );
        ";

        // Create indexes
        var createIndexesSql = @"
            CREATE INDEX IF NOT EXISTS ""IX_Logs_Timestamp"" ON ""Logs""(""Timestamp"" DESC);
            CREATE INDEX IF NOT EXISTS ""IX_Logs_Level"" ON ""Logs""(""Level"");
            CREATE INDEX IF NOT EXISTS ""IX_Logs_UserId"" ON ""Logs""(""UserId"");
            CREATE INDEX IF NOT EXISTS ""IX_Logs_MarketId"" ON ""Logs""(""MarketId"");
            CREATE INDEX IF NOT EXISTS ""IX_Logs_UserName"" ON ""Logs""(""UserName"");
            CREATE INDEX IF NOT EXISTS ""IX_Logs_Properties"" ON ""Logs"" USING GIN (""Properties"");
            CREATE INDEX IF NOT EXISTS ""IX_Logs_UserId_Timestamp"" ON ""Logs""(""UserId"", ""Timestamp"" DESC);
            CREATE INDEX IF NOT EXISTS ""IX_Logs_MarketId_Timestamp"" ON ""Logs""(""MarketId"", ""Timestamp"" DESC);
            CREATE INDEX IF NOT EXISTS ""IX_Logs_Level_Timestamp"" ON ""Logs""(""Level"", ""Timestamp"" DESC);
        ";

        // Create cleanup function
        var createFunctionSql = @"
            CREATE OR REPLACE FUNCTION cleanup_old_logs(days integer DEFAULT 90)
            RETURNS integer AS $$
            DECLARE
                deleted_count integer;
            BEGIN
                DELETE FROM ""Logs""
                WHERE ""Timestamp"" < (now() AT TIME ZONE 'UTC' - (days || ' days')::interval);
                GET DIAGNOSTICS deleted_count = ROW_COUNT;
                RETURN deleted_count;
            END;
            $$ LANGUAGE plpgsql;
        ";

        try
        {
            Console.WriteLine("Creating Logs table...");
            await context.Database.ExecuteSqlRawAsync(createTableSql);
            Console.WriteLine("✓ Logs table created");

            Console.WriteLine("Creating indexes...");
            await context.Database.ExecuteSqlRawAsync(createIndexesSql);
            Console.WriteLine("✓ Indexes created");

            Console.WriteLine("Creating cleanup function...");
            await context.Database.ExecuteSqlRawAsync(createFunctionSql);
            Console.WriteLine("✓ Cleanup function created");

            Console.WriteLine("\n✅ SUCCESS! Logs table is ready for Serilog.");
            Console.WriteLine("You can now delete this file.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"\n❌ ERROR: {ex.Message}");
            Console.WriteLine($"Details: {ex.InnerException?.Message ?? ex.StackTrace}");
        }
    }
}
