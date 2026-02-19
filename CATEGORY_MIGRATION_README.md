# Product Categories System - Migration Guide

## Overview
This migration adds the Product Categories system to the Market System application. Categories allow products to be organized (e.g., "yog'och mahsulotlar" containing "taxta, dsp, reka").

## Files Created/Modified

### Backend (C# .NET)

#### Domain Layer
- ✅ `MarketSystem.Domain/Common/ISoftDeletable.cs` - NEW
  - Interface for soft delete pattern

- ✅ `MarketSystem.Domain/Entities/ProductCategory.cs` - EXISTING
  - ProductCategory entity with market-scoped design
  - Id (int), Name, Description, MarketId (NOT NULL), IsActive, CreatedAt, UpdatedAt, IsDeleted, DeletedAt

- ✅ `MarketSystem.Domain/Entities/Product.cs` - MODIFIED
  - Added `CategoryId` (nullable) and `Category` navigation property

#### Application Layer
- ✅ `MarketSystem.Application/DTOs/ProductCategoryDTOs.cs` - NEW
  - ProductCategoryDto, CreateCategoryRequestModel, UpdateCategoryRequestModel

- ✅ `MarketSystem.Application/DTOs/CommonDTOs.cs` - MODIFIED
  - Added `CategoryId` and `CategoryName` to ProductDto
  - Added `CategoryId` to CreateProductDto and UpdateProductDto

- ✅ `MarketSystem.Application/Services/ProductCategoryService.cs` - NEW
  - GetAllCategoriesAsync, GetCategoryByIdAsync, CreateCategoryAsync, UpdateCategoryAsync, DeleteCategoryAsync
  - MarketId auto-assignment from context
  - Product count validation on delete

- ✅ `MarketSystem.Application/Services/ProductService.cs` - MODIFIED
  - CreateProductAsync and UpdateProductAsync now handle CategoryId

#### Infrastructure Layer
- ✅ `MarketSystem.Infrastructure/Data/AppDbContext.cs` - MODIFIED
  - Added ProductCategory DbSet
  - Added ProductCategory configuration with indexes and query filters

- ✅ `MarketSystem.Infrastructure/Repositories/SimpleRepositories.cs` - MODIFIED
  - Added ProductCategoryRepository class

- ✅ `MarketSystem.Infrastructure/Repositories/UnitOfWork.cs` - MODIFIED
  - Added ProductCategories repository property

#### API Layer
- ✅ `MarketSystem.API/Controllers/ProductCategoriesController.cs` - NEW
  - All endpoints require AdminOrOwner role
  - GET /api/ProductCategories/GetAllCategories
  - GET /api/ProductCategories/GetCategoryById/{id}
  - POST /api/ProductCategories/CreateCategory
  - PUT /api/ProductCategories/UpdateCategory/{id}
  - DELETE /api/ProductCategories/DeleteCategory/{id}

- ✅ `MarketSystem.API/Program.cs` - MODIFIED
  - Registered ProductCategoryService

### Frontend (Flutter)

#### Models
- ✅ `lib/data/models/product_category_model.dart` - NEW
  - ProductCategoryModel, CreateCategoryRequestModel, UpdateCategoryRequestModel

#### Services
- ✅ `lib/data/services/category_service.dart` - NEW
  - getAllCategories, getCategoryById, createCategory, updateCategory, deleteCategory

- ✅ `lib/data/services/product_service.dart` - MODIFIED
  - Added categoryId parameter to createProduct and updateProduct

- ✅ `lib/core/constants/api_constants.dart` - MODIFIED
  - Added productCategories endpoint constant

#### Screens
- ✅ `lib/features/categories/screens/category_management_screen.dart` - NEW
  - List all categories with CRUD operations
  - Product count display per category
  - Delete confirmation dialog

- ✅ `lib/features/categories/screens/category_form_screen.dart` - NEW
  - Create/edit category form
  - Name validation (min 3 characters)
  - Active status toggle

- ✅ `lib/features/products/screens/product_form_screen.dart` - MODIFIED
  - Added category dropdown selector
  - Loads categories on init
  - Selected category highlighted

- ✅ `lib/features/products/screens/products_screen.dart` - MODIFIED
  - Displays category name on product cards (if assigned)

#### DI Container
- ✅ `lib/core/utils/di.dart` - MODIFIED
  - Registered CategoryService

## Database Migration

### SQL Script Location
`MarketSystem.Infrastructure/Migrations/20260219100000_AddProductCategories.sql`

### How to Apply

#### Option 1: Manual SQL Execution (Recommended)
```bash
# Connect to your PostgreSQL database
psql -U your_username -d your_database

# Execute the migration script
\i "c:/Users/joo/Desktop/New folder/MarketSystem.Infrastructure/Migrations/20260219100000_AddProductCategories.sql"
```

#### Option 2: Using EF Core (if dotnet-ef is installed)
```bash
cd "c:\Users\joo\Desktop\New folder\MarketSystem.API"
dotnet ef database update --project MarketSystem.Infrastructure
```

### Migration Details
The SQL script creates:
1. **ProductCategories table** with:
   - Id (serial/integer, primary key, auto-increment)
   - Name (varchar(100), NOT NULL)
   - Description (varchar(500), nullable)
   - MarketId (integer, NOT NULL) - foreign key to Markets
   - IsActive (boolean, default true)
   - CreatedAt, UpdatedAt (timestamp with time zone, default now())
   - IsDeleted (boolean, default false) - for soft delete
   - DeletedAt (timestamp with time zone, nullable)

2. **Indexes**:
   - IX_ProductCategories_MarketId (for filtering by market)
   - IX_ProductCategories_Name (for searching)
   - IX_Products_CategoryId (for product filtering)

3. **Foreign Keys**:
   - FK_ProductCategories_Markets_MarketId (ON DELETE CASCADE)
   - FK_Products_ProductCategories_CategoryId (ON DELETE SET NULL)

4. **Column Addition**:
   - Products.CategoryId (integer, nullable)

## Features

### Category Management (Admin/Owner only)
- ✅ Create categories (name, description, active status)
- ✅ Edit categories
- ✅ Delete categories (only if no products assigned)
- ✅ View all categories with product count
- ✅ Activate/deactivate categories

### Product Integration
- ✅ Assign category to product during creation/editing
- ✅ Category dropdown in product form
- ✅ Display category name on product cards
- ✅ Optional relationship (product can have no category)

### Business Rules
1. **Market-Scoped**: Each category belongs to a specific market
2. **Soft Delete**: Deleted categories are filtered out (IsDeleted = true)
3. **Cascade Delete**: When market is deleted, all its categories are deleted
4. **Set Null on Category Delete**: When category is deleted, products' CategoryId becomes NULL
5. **Delete Validation**: Cannot delete category that has active products

## Testing Checklist

### Backend API Testing
```bash
# 1. Get all categories (Admin/Owner)
GET /api/ProductCategories/GetAllCategories
Authorization: Bearer {admin_or_owner_token}

# 2. Create category (Admin/Owner)
POST /api/ProductCategories/CreateCategory
{
  "name": "Yog'och mahsulotlar",
  "description": "Taxta, DSP, reka va boshqa yog'och mahsulotlar",
  "isActive": true
}

# 3. Create product with category (Admin/Owner)
POST /api/Products/CreateProduct
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

# 4. Delete category (Admin/Owner) - should fail if has products
DELETE /api/ProductCategories/DeleteCategory/1
```

### Flutter UI Testing
1. Navigate to "Kategoriyalar" (Categories) from dashboard
2. Click "+ Qo'shish" to create new category
3. Fill form: Name "Yog'och mahsulotlar", Description "..."
4. Save and verify category appears in list
5. Go to Products, click "+ Mahsulot qo'shish"
6. Select category from dropdown
7. Create product and verify category displays on product card

## Rollback Plan

If issues occur, execute this rollback SQL:

```sql
-- Drop foreign keys
ALTER TABLE "Products" DROP CONSTRAINT IF EXISTS "FK_Products_ProductCategories_CategoryId";
ALTER TABLE "ProductCategories" DROP CONSTRAINT IF EXISTS "FK_ProductCategories_Markets_MarketId";

-- Drop indexes
DROP INDEX IF EXISTS "IX_Products_CategoryId";
DROP INDEX IF EXISTS "IX_ProductCategories_Name";
DROP INDEX IF EXISTS "IX_ProductCategories_MarketId";

-- Drop column
ALTER TABLE "Products" DROP COLUMN IF EXISTS "CategoryId";

-- Drop table
DROP TABLE IF EXISTS "ProductCategories";
```

## Troubleshooting

### Issue: Build errors after migration
**Solution**: Run `dotnet clean` then `dotnet build`

### Issue: Migration not applied
**Solution**: Check PostgreSQL connection string in appsettings.json

### Issue: Categories not showing in Flutter
**Solution**:
1. Check API is running
2. Check user has Admin or Owner role
3. Check browser console for errors

### Issue: Product count showing incorrectly
**Solution**: Ensure soft delete filter is working (IsDeleted = false)

## Next Steps

After migration is applied:
1. ✅ Test category creation/editing/deletion
2. ✅ Test product-category assignment
3. ✅ Add category management to dashboard menu (Admin/Owner only)
4. ✅ Update Zakup screen to filter by category
5. ✅ Update Sale screen to filter by category
