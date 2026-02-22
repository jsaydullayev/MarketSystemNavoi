using Npgsql;

namespace CreateLogsTable;

/// <summary>
/// Standalone script to create Logs table for Serilog
/// Usage: dotnet run --project MarketSystem.API --create-logs-only
/// </summary>
public class CreateLogsTableScript
{
    public static async Task Main(string[] args)
    {
        var connectionString = "Host=localhost;Port=3030;Database=MarketSystemDB;Username=postgres;Password=postgres";

        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync();

        Console.WriteLine("Creating Logs table...");

        try
        {
            // Create table
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
                    ""StackTrace"" text
                );
            ";

            using (var cmd = new NpgsqlCommand(createTableSql, connection))
            {
                await cmd.ExecuteNonQueryAsync();
                Console.WriteLine("✅ Logs table created");
            }

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

            using (var cmd = new NpgsqlCommand(createIndexesSql, connection))
            {
                await cmd.ExecuteNonQueryAsync();
                Console.WriteLine("✅ Indexes created");
            }

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

            using (var cmd = new NpgsqlCommand(createFunctionSql, connection))
            {
                await cmd.ExecuteNonQueryAsync();
                Console.WriteLine("✅ Cleanup function created");
            }

            Console.WriteLine("\n✅ SUCCESS! Logs table is ready for Serilog.");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"\n❌ ERROR: {ex.Message}");
            if (ex.InnerException != null)
            {
                Console.WriteLine($"Details: {ex.InnerException.Message}");
            }
        }
        finally
        {
            await connection.CloseAsync();
        }
    }
}
