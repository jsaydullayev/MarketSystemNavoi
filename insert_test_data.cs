using System;
using Npgsql;
using System.Threading.Tasks;

class Program
{
    static async Task Main()
    {
        var connString = "Host=localhost;Port=5433;Database=MarketSystemDB;Username=postgres;Password=SuperSecur3MarketDB!2026";

        await using var conn = new NpgsqlConnection(connString);
        await conn.OpenAsync();

        // 1. Test Customer
        var customerSql = @"
            INSERT INTO ""Customers"" (""Id"", ""Phone"", ""FullName"", ""MarketId"", ""TotalDebt"", ""CreatedAt"", ""UpdatedAt"")
            VALUES ('11111111-1111-1111-1111-111111111111', '+998901234567', 'Test Mijoz', 4, 0, NOW(), NOW())
            ON CONFLICT (""Id"") DO NOTHING;";

        await using (var cmd = new NpgsqlCommand(customerSql, conn))
        {
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("✅ Customer created");
        }

        // 2. Test Products
        var productsSql = @"
            INSERT INTO ""Products"" (""Id"", ""Name"", ""SalePrice"", ""CostPrice"", ""Quantity"", ""MarketId"", ""CreatedAt"", ""UpdatedAt"")
            VALUES
                ('22222222-2222-2222-2222-222222222222', 'Test Mahsulot 1', 50000.00, 30000.00, 100, 4, NOW(), NOW()),
                ('33333333-3333-3333-3333-333333333333', 'Test Mahsulot 2', 75000.00, 50000.00, 50, 4, NOW(), NOW())
            ON CONFLICT (""Id"") DO NOTHING;";

        await using (var cmd = new NpgsqlCommand(productsSql, conn))
        {
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("✅ Products created");
        }

        // 3. Get Seller ID
        string sellerId = "";
        var getSellerSql = "SELECT ""Id"" FROM ""Users"" WHERE ""MarketId"" = 4 LIMIT 1;";
        await using (var cmd = new NpgsqlCommand(getSellerSql, conn))
        {
            var result = await cmd.ExecuteScalarAsync();
            sellerId = result?.ToString() ?? "";
            Console.WriteLine($"✅ Seller ID: {sellerId}");
        }

        if (string.IsNullOrEmpty(sellerId))
        {
            Console.WriteLine("❌ No seller found!");
            return;
        }

        // 4. Test Sale with products
        var sale1Sql = $@"
            INSERT INTO ""Sales"" (""Id"", ""CustomerId"", ""SellerId"", ""TotalAmount"", ""PaidAmount"", ""Status"", ""PaymentType"", ""MarketId"", ""CreatedAt"", ""UpdatedAt"")
            VALUES ('44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', '{sellerId}', 300000.00, 100000.00, 'Debt', 'Cash', 4, NOW(), NOW())
            ON CONFLICT (""Id"") DO NOTHING;";

        await using (var cmd = new NpgsqlCommand(sale1Sql, conn))
        {
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("✅ Sale 1 created");
        }

        // 5. Sale Items
        var saleItemsSql = @"
            INSERT INTO ""SaleItems"" (""Id"", ""SaleId"", ""ProductId"", ""Quantity"", ""SalePrice"", ""CostPrice"", ""CreatedAt"", ""UpdatedAt"")
            VALUES
                ('55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 3, 50000.00, 30000.00, NOW(), NOW()),
                ('66666666-6666-6666-6666-666666666666', '44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 2, 75000.00, 50000.00, NOW(), NOW())
            ON CONFLICT (""Id"") DO NOTHING;";

        await using (var cmd = new NpgsqlCommand(saleItemsSql, conn))
        {
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("✅ Sale items created");
        }

        // 6. Debt 1
        var debt1Sql = @"
            INSERT INTO ""Debts"" (""Id"", ""SaleId"", ""CustomerId"", ""TotalDebt"", ""RemainingDebt"", ""Status"", ""MarketId"", ""CreatedAt"", ""UpdatedAt"")
            VALUES ('77777777-7777-7777-7777-777777777777', '44444444-4444-4444-4444-444444444444', '11111111-1111-1111-1111-111111111111', 200000.00, 200000.00, 'Open', 4, NOW(), NOW())
            ON CONFLICT (""Id"") DO NOTHING;";

        await using (var cmd = new NpgsqlCommand(debt1Sql, conn))
        {
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("✅ Debt 1 created (with products)");
        }

        // 7. Sale 2 (without products)
        var sale2Sql = $@"
            INSERT INTO ""Sales"" (""Id"", ""CustomerId"", ""SellerId"", ""TotalAmount"", ""PaidAmount"", ""Status"", ""PaymentType"", ""MarketId"", ""CreatedAt"", ""UpdatedAt"")
            VALUES ('88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', '{sellerId}', 50000.00, 0.00, 'Debt', 'Cash', 4, NOW() - INTERVAL '5 days', NOW())
            ON CONFLICT (""Id"") DO NOTHING;";

        await using (var cmd = new NpgsqlCommand(sale2Sql, conn))
        {
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("✅ Sale 2 created (old debt)");
        }

        // 8. Debt 2
        var debt2Sql = @"
            INSERT INTO ""Debts"" (""Id"", ""SaleId"", ""CustomerId"", ""TotalDebt"", ""RemainingDebt"", ""Status"", ""MarketId"", ""CreatedAt"", ""UpdatedAt"")
            VALUES ('99999999-9999-9999-9999-999999999999', '88888888-8888-8888-8888-888888888888', '11111111-1111-1111-1111-111111111111', 50000.00, 50000.00, 'Open', 4, NOW() - INTERVAL '5 days', NOW())
            ON CONFLICT (""Id"") DO NOTHING;";

        await using (var cmd = new NpgsqlCommand(debt2Sql, conn))
        {
            await cmd.ExecuteNonQueryAsync();
            Console.WriteLine("✅ Debt 2 created (without products)");
        }

        Console.WriteLine("\n🎉 All test data inserted successfully!");
        Console.WriteLine("Customer: Test Mijoz (+998901234567)");
        Console.WriteLine("Total debts: 2 (250,000 so'm)");
        Console.WriteLine("  - Debt 1: 200,000 so'm (with 2 products)");
        Console.WriteLine("  - Debt 2: 50,000 so'm (old debt, no products)");
    }
}
