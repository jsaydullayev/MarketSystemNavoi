-- Test qarzlar yaratish uchun SQL script
-- Avval mavjud mijozlarni topamiz
SELECT "Id", "FullName", "Phone" FROM "Customers" WHERE "MarketId" = 4 LIMIT 5;

-- Mahsulotlarni topamiz
SELECT "Id", "Name", "SalePrice" FROM "Products" WHERE "MarketId" = 4 LIMIT 5;

-- Userlarni topamiz
SELECT "Id", "FullName", "Role" FROM "Users" WHERE "MarketId" = 4;
