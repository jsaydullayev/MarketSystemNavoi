# Database Migration Guide - Product Categories

## Migration: AddProductCategories (20260219100000)

### What's New:
- ✅ **ProductCategories table** - Mahsulot kategoriyalari uchun
- ✅ **Products.CategoryId** - Mahsulotning kategoriyasi (nullable)
- ✅ **Foreign Key** - Products → ProductCategories (SET NULL on delete)

### Migration Files:
1. **20260219100000_AddProductCategories.cs** - Main migration
2. **20260219100000_AddProductCategories.Designer.cs** - Snapshot
3. **20260219100000_AddProductCategories.sql** - SQL script (manual)

### How to Apply Migration:

#### Option 1: Using EF Core Tools (Recommended)
```bash
# Add migration (already done)
dotnet ef migrations add AddProductCategories --project MarketSystem.Infrastructure

# Update database
dotnet ef database update --project MarketSystem.Infrastructure
```

#### Option 2: Using SQL Script
```bash
# Connect to PostgreSQL database
psql -U your_username -d your_database

# Run migration script
\i migrations/20260219100000_AddProductCategories.sql
```

### Database Changes:
```sql
-- New Table
CREATE TABLE "ProductCategories" (
    "Id" serial PRIMARY KEY,
    "Name" varchar(100) NOT NULL,
    "Description" varchar(500),
    "MarketId" integer NOT NULL,
    "IsActive" boolean DEFAULT true,
    "CreatedAt" timestamp with time zone DEFAULT now(),
    "UpdatedAt" timestamp with time zone DEFAULT now(),
    "IsDeleted" boolean DEFAULT false,
    "DeletedAt" timestamp with time zone
);

-- New Column
ALTER TABLE "Products" ADD COLUMN "CategoryId" integer;

-- New Indexes
CREATE INDEX "IX_ProductCategories_MarketId" ON "ProductCategories"("MarketId");
CREATE INDEX "IX_ProductCategories_Name" ON "ProductCategories"("Name");
CREATE INDEX "IX_Products_CategoryId" ON "Products"("CategoryId");

-- New Foreign Key
ALTER TABLE "Products"
ADD CONSTRAINT "FK_Products_ProductCategories_CategoryId"
FOREIGN KEY ("CategoryId")
REFERENCES "ProductCategories"("Id")
ON DELETE SET NULL;
```

### Rollback (if needed):
```bash
dotnet ef database update 20260219135549_MarketMigration5 --project MarketSystem.Infrastructure
```

### Verification:
```sql
-- Check ProductCategories table
SELECT * FROM "ProductCategories";

-- Check Products CategoryId column
SELECT "Id", "Name", "CategoryId" FROM "Products" LIMIT 5;

-- Check foreign key constraint
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_name='Products';
```

## Important Notes:

1. **CategoryId is Nullable**: Products can exist without category
2. **Soft Delete**: Categories use soft delete (IsDeleted flag)
3. **SET NULL on Delete**: Category o'chirilsa, Product.CategoryId = NULL
4. **Market-Scoped**: Categories are filtered by MarketId
5. **Product Count**: Category DTO includes product count (active only)
