using Npgsql;
using System.Data;
using BCrypt.Net;

var connectionString = "Host=localhost;Port=5433;Database=MarketSystemDB;Username=postgres;Password=SuperSecur3MarketDB!2026";

// Test BCrypt hash first
Console.WriteLine("=== Testing BCrypt Hash ===");
var storedHash = "$2a$11$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj9SjKE.F4.G";
var password = "owner123";
Console.WriteLine($"Password: {password}");
Console.WriteLine($"Stored Hash: {storedHash}");

var isValid = BCrypt.Net.BCrypt.Verify(password, storedHash);
Console.WriteLine($"BCrypt Verification: {isValid}");

// Generate correct hash
var correctHash = BCrypt.Net.BCrypt.HashPassword(password, workFactor: 11);
Console.WriteLine($"Correct Hash for 'owner123': {correctHash}");
Console.WriteLine();

Console.WriteLine("Checking for owner user...");

// Check if owner user exists
using var connection = new NpgsqlConnection(connectionString);
await connection.OpenAsync();

using var checkCommand = new NpgsqlCommand("SELECT \"Id\", \"Username\", \"FullName\", \"Role\", \"Language\", \"IsActive\", \"IsDeleted\" FROM \"Users\" WHERE \"Username\" = 'owner'", connection);
using var reader = await checkCommand.ExecuteReaderAsync();

if (await reader.ReadAsync())
{
    Console.WriteLine("✅ Owner user found:");
    Console.WriteLine($"  ID: {reader.GetGuid(0)}");
    Console.WriteLine($"  Username: {reader.GetString(1)}");
    Console.WriteLine($"  Full Name: {reader.GetString(2)}");
    Console.WriteLine($"  Role: {reader.GetInt32(3)} (3=Owner)");
    Console.WriteLine($"  Language: {reader.GetInt32(4)} (2=Uzbek)");
    Console.WriteLine($"  IsActive: {reader.GetBoolean(5)}");
    Console.WriteLine($"  IsDeleted: {reader.GetBoolean(6)}");
}
else
{
    Console.WriteLine("❌ Owner user NOT found in database.");
    Console.WriteLine("\nInserting owner user...");
}

await reader.CloseAsync();

// If not found, insert the user
using var countCommand = new NpgsqlCommand("SELECT COUNT(*) FROM \"Users\" WHERE \"Username\" = 'owner'", connection);
var count = (long)(await countCommand.ExecuteScalarAsync() ?? 0);

if (count == 0)
{
    Console.WriteLine("Inserting owner user...");

    var insertSql = @"
        INSERT INTO ""Users"" (""Id"", ""Username"", ""PasswordHash"", ""FullName"", ""Role"", ""Language"", ""MarketId"", ""CreatedAt"", ""IsActive"", ""IsDeleted"")
        VALUES (
            '11111111-1111-1111-1111-111111111112',
            'owner',
            '$2a$11$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj9SjKE.F4.G',
            'Owner User',
            3,  -- Role: Owner
            2,  -- Language: Uzbek
            NULL,
            NOW(),
            true,
            false
        );";

    using var insertCommand = new NpgsqlCommand(insertSql, connection);
    await insertCommand.ExecuteNonQueryAsync();
    Console.WriteLine("✅ Owner user inserted successfully!");
}
else
{
    Console.WriteLine("Owner user already exists. Skipping insertion.");
}

// Verify after insertion
Console.WriteLine("\nFinal verification:");
using var finalCommand = new NpgsqlCommand("SELECT \"Username\", \"Role\", \"IsActive\" FROM \"Users\" WHERE \"Username\" = 'owner'", connection);
using var finalReader = await finalCommand.ExecuteReaderAsync();

if (await finalReader.ReadAsync())
{
    var username = finalReader.GetString(0);
    var role = finalReader.GetInt32(1);
    var isActive = finalReader.GetBoolean(2);
    Console.WriteLine($"✅ User: {username}, Role: {role} (Owner=3), Active: {isActive}");
}
else
{
    Console.WriteLine("❌ Still not found! Something went wrong.");
}

await finalReader.CloseAsync();

Console.WriteLine("\nUpdating owner password and role with correct values...");

var updateSql = @"
    UPDATE ""Users""
    SET ""PasswordHash"" = '$2a$11$HmfGrWOoeIywsDlqSGfjPuXbIFpMJz6J/pWbrE/7O6bOyeSXY7ASS',
        ""Role"" = 1  -- Owner = 1, not 3!
    WHERE ""Username"" = 'owner';";

using var updateCommand = new NpgsqlCommand(updateSql, connection);
var rowsAffected = await updateCommand.ExecuteNonQueryAsync();
Console.WriteLine($"✅ Password updated! Rows affected: {rowsAffected}");

// Verify new password hash
Console.WriteLine("\nVerifying updated password...");
using var verifyCommand = new NpgsqlCommand("SELECT \"PasswordHash\" FROM \"Users\" WHERE \"Username\" = 'owner'", connection);
var newHashFromDb = (await verifyCommand.ExecuteScalarAsync())?.ToString();
Console.WriteLine($"New hash from DB: {newHashFromDb}");

var finalVerify = BCrypt.Net.BCrypt.Verify("owner123", newHashFromDb!);
Console.WriteLine($"Final verification of 'owner123': {finalVerify}");

if (finalVerify)
{
    Console.WriteLine("\n✅✅✅ SUCCESS! Owner user can now login with owner/owner123 ✅✅✅");
}
