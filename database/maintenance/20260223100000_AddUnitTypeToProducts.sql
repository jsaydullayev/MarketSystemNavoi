-- Migration: Add UnitType column to Products table
-- Date: 2026-02-23

-- 1. Add Unit column (default to Piece = 1)
ALTER TABLE "Products"
ADD COLUMN "Unit" integer NOT NULL DEFAULT 1;

-- 2. Change Quantity from integer to decimal
ALTER TABLE "Products"
ALTER COLUMN "Quantity" TYPE numeric(18,2) USING "Quantity"::numeric;

-- 3. Change MinThreshold from integer to decimal
ALTER TABLE "Products"
ALTER COLUMN "MinThreshold" TYPE numeric(18,2) USING "MinThreshold"::numeric;

-- 4. Add check constraint: Unit must be 1, 2, or 3
ALTER TABLE "Products"
ADD CONSTRAINT "CK_Products_Unit" CHECK ("Unit" IN (1, 2, 3));

-- 5. Add check constraint: Quantity must be non-negative
ALTER TABLE "Products"
ADD CONSTRAINT "CK_Products_Quantity_NonNegative" CHECK ("Quantity" >= 0);

-- 6. Add check constraint: MinThreshold must be non-negative
ALTER TABLE "Products"
ADD CONSTRAINT "CK_Products_MinThreshold_NonNegative" CHECK ("MinThreshold" >= 0);

-- 7. Create index on Unit for faster filtering
CREATE INDEX IF NOT EXISTS "IX_Products_Unit" ON "Products"("Unit");

COMMENT ON COLUMN "Products"."Unit" IS '1=Piece(dona), 2=Kilogram(kg), 3=Meter(m)';
COMMENT ON COLUMN "Products"."Quantity" IS 'Stock quantity (decimal for kg/m support)';
COMMENT ON COLUMN "Products"."MinThreshold" IS 'Minimum stock threshold before low stock alert';

-- Migration for SaleItems
-- Change Quantity from integer to decimal
ALTER TABLE "SaleItems"
ALTER COLUMN "Quantity" TYPE numeric(18,2) USING "Quantity"::numeric;

-- Add check constraint: Quantity must be positive
ALTER TABLE "SaleItems"
ADD CONSTRAINT "CK_SaleItems_Quantity_Positive" CHECK ("Quantity" > 0);

COMMENT ON COLUMN "SaleItems"."Quantity" IS 'Sold quantity (decimal for kg/m support)';
