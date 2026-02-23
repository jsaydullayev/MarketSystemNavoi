-- Test qarzlar yaratish
-- MarketId = 4 bo'yicha test data

-- 1. Test Customer (agar yo'q bo'lsa)
INSERT INTO "Customers" ("Id", "Phone", "FullName", "MarketId", "TotalDebt", "CreatedAt", "UpdatedAt")
VALUES (
    '11111111-1111-1111-1111-111111111111',
    '+998901234567',
    'Test Mijoz',
    4,
    0,
    NOW(),
    NOW()
)
ON CONFLICT ("Id") DO NOTHING;

-- 2. Test Product (agar yo'q bo'lsa)
INSERT INTO "Products" ("Id", "Name", "SalePrice", "CostPrice", "Quantity", "MarketId", "CreatedAt", "UpdatedAt")
VALUES (
    '22222222-2222-2222-2222-222222222222',
    'Test Mahsulot 1',
    50000.00,
    30000.00,
    100,
    4,
    NOW(),
    NOW()
)
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO "Products" ("Id", "Name", "SalePrice", "CostPrice", "Quantity", "MarketId", "CreatedAt", "UpdatedAt")
VALUES (
    '33333333-3333-3333-3333-333333333333',
    'Test Mahsulot 2',
    75000.00,
    50000.00,
    50,
    4,
    NOW(),
    NOW()
)
ON CONFLICT ("Id") DO NOTHING;

-- 3. Test Sale with Debt
INSERT INTO "Sales" ("Id", "CustomerId", "SellerId", "TotalAmount", "PaidAmount", "Status", "PaymentType", "MarketId", "CreatedAt", "UpdatedAt")
VALUES (
    '44444444-4444-4444-4444-444444444444',
    '11111111-1111-1111-1111-111111111111',
    (SELECT "Id" FROM "Users" WHERE "MarketId" = 4 LIMIT 1),
    250000.00,
    100000.00,
    'Debt',
    'Cash',
    4,
    NOW(),
    NOW()
)
ON CONFLICT ("Id") DO NOTHING;

-- 4. Sale Items
INSERT INTO "SaleItems" ("Id", "SaleId", "ProductId", "Quantity", "SalePrice", "CostPrice", "CreatedAt", "UpdatedAt")
VALUES
    ('55555555-5555-5555-5555-555555555555', '44444444-4444-4444-4444-444444444444', '22222222-2222-2222-2222-222222222222', 3, 50000.00, 30000.00, NOW(), NOW()),
    ('66666666-6666-6666-6666-666666666666', '44444444-4444-4444-4444-444444444444', '33333333-3333-3333-3333-333333333333', 2, 75000.00, 50000.00, NOW(), NOW())
ON CONFLICT ("Id") DO NOTHING;

-- 5. Debt Record
INSERT INTO "Debts" ("Id", "SaleId", "CustomerId", "TotalDebt", "RemainingDebt", "Status", "MarketId", "CreatedAt", "UpdatedAt")
VALUES (
    '77777777-7777-7777-7777-777777777777',
    '44444444-4444-4444-4444-444444444444',
    '11111111-1111-1111-1111-111111111111',
    150000.00,
    150000.00,
    'Open',
    4,
    NOW(),
    NOW()
)
ON CONFLICT ("Id") DO NOTHING;

-- 6. Yana bir test qarz (mahsulotsiz)
INSERT INTO "Sales" ("Id", "CustomerId", "SellerId", "TotalAmount", "PaidAmount", "Status", "PaymentType", "MarketId", "CreatedAt", "UpdatedAt")
VALUES (
    '88888888-8888-8888-8888-888888888888',
    '11111111-1111-1111-1111-111111111111',
    (SELECT "Id" FROM "Users" WHERE "MarketId" = 4 LIMIT 1),
    50000.00,
    0.00,
    'Debt',
    'Cash',
    4,
    NOW() - INTERVAL '5 days',
    NOW()
)
ON CONFLICT ("Id") DO NOTHING;

INSERT INTO "Debts" ("Id", "SaleId", "CustomerId", "TotalDebt", "RemainingDebt", "Status", "MarketId", "CreatedAt", "UpdatedAt")
VALUES (
    '99999999-9999-9999-9999-999999999999',
    '88888888-8888-8888-8888-888888888888',
    '11111111-1111-1111-1111-111111111111',
    50000.00,
    50000.00,
    'Open',
    4,
    NOW() - INTERVAL '5 days',
    NOW()
)
ON CONFLICT ("Id") DO NOTHING;

-- Natijalarni ko'rsatish
SELECT 'Test Customer' as Type, "Id", "FullName", "Phone" FROM "Customers" WHERE "Id" = '11111111-1111-1111-1111-111111111111'
UNION ALL
SELECT 'Test Sale 1', "Id", "TotalAmount"::text, "Status" FROM "Sales" WHERE "Id" = '44444444-4444-4444-4444-444444444444'
UNION ALL
SELECT 'Test Sale 2', "Id", "TotalAmount"::text, "Status" FROM "Sales" WHERE "Id" = '88888888-8888-8888-8888-888888888888'
UNION ALL
SELECT 'Test Debt 1', "Id", "TotalDebt"::text, "Status" FROM "Debts" WHERE "Id" = '77777777-7777-7777-7777-777777777777'
UNION ALL
SELECT 'Test Debt 2', "Id", "TotalDebt"::text, "Status" FROM "Debts" WHERE "Id" = '99999999-9999-9999-9999-999999999999';
