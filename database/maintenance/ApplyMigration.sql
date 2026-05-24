-- Add IsDeleted columns
ALTER TABLE "Users" ADD COLUMN "IsDeleted" BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE "Customers" ADD COLUMN "IsDeleted" BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE "Sales" ADD COLUMN "IsDeleted" BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE "Products" ADD COLUMN "IsDeleted" BOOLEAN NOT NULL DEFAULT FALSE;

-- Create indexes
CREATE INDEX IF NOT EXISTS "IX_Sale_CustomerId" ON "Sales"("CustomerId") WHERE "CustomerId" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "IX_Sale_Seller_Status" ON "Sales"("SellerId", "Status");
CREATE INDEX IF NOT EXISTS "IX_Sale_Status_CreatedAt" ON "Sales"("Status", "CreatedAt");
CREATE INDEX IF NOT EXISTS "IX_SaleItem_Sale_Product" ON "SaleItems"("SaleId", "ProductId");
CREATE INDEX IF NOT EXISTS "IX_RefreshToken_Token" ON "RefreshTokens"("Token");
CREATE INDEX IF NOT EXISTS "IX_RefreshToken_User_ExpiresAt" ON "RefreshTokens"("UserId", "ExpiresAt");
CREATE INDEX IF NOT EXISTS "IX_Debt_Customer_Status" ON "Debts"("CustomerId", "Status");
CREATE INDEX IF NOT EXISTS "IX_AuditLog_Entity_CreatedAt" ON "AuditLogs"("EntityType", "EntityId", "CreatedAt");
CREATE INDEX IF NOT EXISTS "IX_AuditLog_User_CreatedAt" ON "AuditLogs"("UserId", "CreatedAt");
