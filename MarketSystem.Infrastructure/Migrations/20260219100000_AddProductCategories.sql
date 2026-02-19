-- Migration: Add ProductCategories table and update Products table
-- Date: 2026-02-19

-- 1. Create ProductCategories table
CREATE TABLE IF NOT EXISTS "ProductCategories" (
    "Id" serial PRIMARY KEY,
    "Name" varchar(100) NOT NULL,
    "Description" varchar(500),
    "MarketId" integer NOT NULL,
    "IsActive" boolean NOT NULL DEFAULT true,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT now(),
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT now(),
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "DeletedAt" timestamp with time zone
);

-- 2. Create index on MarketId for filtering
CREATE INDEX IF NOT EXISTS "IX_ProductCategories_MarketId" ON "ProductCategories"("MarketId");

-- 3. Create index on Name for searching
CREATE INDEX IF NOT EXISTS "IX_ProductCategories_Name" ON "ProductCategories"("Name");

-- 4. Add foreign key to Markets table
ALTER TABLE "ProductCategories"
ADD CONSTRAINT "FK_ProductCategories_Markets_MarketId"
FOREIGN KEY ("MarketId")
REFERENCES "Markets"("Id")
ON DELETE CASCADE;

-- 5. Add CategoryId column to Products table (as nullable)
ALTER TABLE "Products"
ADD COLUMN IF NOT EXISTS "CategoryId" integer;

-- 6. Add foreign key to ProductCategories table (optional relationship)
ALTER TABLE "Products"
ADD CONSTRAINT "FK_Products_ProductCategories_CategoryId"
FOREIGN KEY ("CategoryId")
REFERENCES "ProductCategories"("Id")
ON DELETE SET NULL;  -- If category is deleted, product's CategoryId becomes NULL

-- 7. Create index on CategoryId for faster filtering
CREATE INDEX IF NOT EXISTS "IX_Products_CategoryId" ON "Products"("CategoryId");

-- 8. Add comment
COMMENT ON TABLE "ProductCategories" IS 'Mahsulot kategoriyalari - yog''och, metal, elektronika va hokazo';
COMMENT ON COLUMN "ProductCategories"."IsActive" IS 'Kategoriya faol yoki nofaol ekanini bildiradi';
COMMENT ON COLUMN "Products"."CategoryId" IS 'Mahsulotning kategoriyasi (ixtiyoriy)';
