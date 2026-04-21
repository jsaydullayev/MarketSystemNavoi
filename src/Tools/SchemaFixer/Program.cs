using Npgsql;

namespace MarketSystem.Tools.SchemaFixer;

var connectionString = "Host=localhost;Port=5433;Database=MarketSystemDB;Username=postgres;Password=postgres";

var sql = @"
-- Add missing columns to Products table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Products' AND column_name = 'IsDeleted') THEN
        ALTER TABLE ""Products"" ADD COLUMN ""IsDeleted"" boolean NOT NULL DEFAULT false;
        RAISE NOTICE 'Added IsDeleted column to Products';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'Products' AND column_name = 'DeletedAt') THEN
        ALTER TABLE ""Products"" ADD COLUMN ""DeletedAt"" timestamp with time zone;
        RAISE NOTICE 'Added DeletedAt column to Products';
    END IF;
END $$;

-- Add missing columns to ProductCategories table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'ProductCategories' AND column_name = 'DeletedAt') THEN
        ALTER TABLE ""ProductCategories"" ADD COLUMN ""DeletedAt"" timestamp with time zone;
        RAISE NOTICE 'Added DeletedAt column to ProductCategories';
    END IF;
END $$;
";

Console.WriteLine("Connecting to database...");
using var conn = new NpgsqlConnection(connectionString);
await conn.OpenAsync();
Console.WriteLine("Connected!");

Console.WriteLine("Applying schema fixes...");
using var cmd = new NpgsqlCommand(sql, conn);
var result = await cmd.ExecuteNonQueryAsync();

Console.WriteLine("\n=== Schema fix completed successfully! ===");
Console.WriteLine("Press any key to exit...");
Console.ReadKey();
