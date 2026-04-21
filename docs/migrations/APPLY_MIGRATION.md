# Product Categories Migration - Quick Apply Guide

## Problem
EF Core migrations are out of sync with the database model. The simplest solution is to apply the SQL script directly.

## Solution: Apply SQL Migration Manually

### Step 1: Connect to PostgreSQL
```bash
# Using psql command line
psql -U postgres -d market_system_db

# Or using pgAdmin / DBeaver / your preferred PostgreSQL client
```

### Step 2: Apply the SQL Script
Copy and paste the contents of this file:
```
MarketSystem.Infrastructure/Migrations/20260219100000_AddProductCategories.sql
```

Or run it directly:
```bash
psql -U postgres -d market_system_db -f "MarketSystem.Infrastructure/Migrations/20260219100000_AddProductCategories.sql"
```

### Step 3: Verify
```sql
-- Check if ProductCategories table exists
\d "ProductCategories"

-- Check if Products table has CategoryId column
\d "Products"

-- Should see CategoryId column in Products table
```

### Step 4: Record Migration in EFMigrationsHistory (Optional)
If you want EF Core to know this migration was applied:

```sql
INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20260219100000_AddProductCategories', '9.0.4');
```

## What the Migration Does

1. Creates **ProductCategories** table with:
   - Id (auto-increment integer)
   - Name (varchar 100)
   - Description (varchar 500, optional)
   - MarketId (integer, NOT NULL) - links to Markets table
   - IsActive (boolean, default true)
   - CreatedAt, UpdatedAt (timestamps)
   - IsDeleted (boolean, default false) - soft delete
   - DeletedAt (timestamp, optional)

2. Adds **CategoryId** column to Products table (optional)

3. Creates indexes for performance

4. Creates foreign key relationships

## Alternative: Clean Slate (Development Only)

If this is a development database and you don't mind losing data:

```bash
# Drop and recreate database
psql -U postgres -c "DROP DATABASE IF EXISTS market_system_db;"
psql -U postgres -c "CREATE DATABASE market_system_db;"

# Then run the application - it will auto-apply migrations
cd MarketSystem.API
dotnet run
```

## Troubleshooting

### Error: "relation \"ProductCategories\" already exists"
**Solution**: Migration already applied. Continue to testing.

### Error: "column \"CategoryId\" of relation \"Products\" already exists"
**Solution**: Migration already applied. Continue to testing.

### Error: "database \"market_system_db\" does not exist"
**Solution**: Create the database first:
```sql
CREATE DATABASE market_system_db;
```

## Testing After Migration

1. Start the backend API:
```bash
cd MarketSystem.API
dotnet run
```

2. Test category creation via API:
```bash
POST http://localhost:5000/api/ProductCategories/CreateCategory
Authorization: Bearer {admin_or_owner_token}
Content-Type: application/json

{
  "name": "Yog'och mahsulotlar",
  "description": "Taxta, DSP, reka",
  "isActive": true
}
```

3. Create product with category:
```bash
POST http://localhost:5000/api/Products/CreateProduct
Authorization: Bearer {admin_or_owner_token}
Content-Type: application/json

{
  "name": "Taxta",
  "categoryId": 1,
  "costPrice": 1000000,
  "salePrice": 1200000,
  "minSalePrice": 1100000,
  "quantity": 50,
  "minThreshold": 10,
  "isTemporary": false
}
```

## Next Steps

After migration is successfully applied:
1. Test category management in Flutter app
2. Test product-category assignment
3. Verify category display on product cards
