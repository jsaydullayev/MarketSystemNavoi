-- Test query to check ProductCategories table
SELECT * FROM "ProductCategories" WHERE "MarketId" = 4;

-- Count total categories
SELECT COUNT(*) FROM "ProductCategories" WHERE "MarketId" = 4 AND "IsDeleted" = false;

-- Check if table exists
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name = 'ProductCategories';
