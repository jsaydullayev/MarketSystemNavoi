# Product Units Architecture - Professional Documentation

## 1. Arxitekturaviy Qarorlar

### 1.1. Enum vs Units Table - Tahlil

**✅ TAVSIYA: Enum ishlating**

#### Sabablari:

1. **Soddalik va Maintenance**
   - O'lchov birliklari odatda o'zgarmaydi (dona, kg, metr)
   - Enum compilation time'da tekshiriladi
   - Database migrationlari kamroq

2. **Performance**
   - Enum tezroq - join kerak emas
   - Index hajmi kamroq
   - Memory efficiency yuqori

3. **Type Safety**
   ```csharp
   public enum UnitType
   {
       Piece = 1,      // dona
       Kilogram = 2,   // kg
       Meter = 3       // m
   }
   ```
   - Compile-time xavfsizlik
   - IDE intellisens support

4. **Business Logic**
   ```csharp
   public string GetUnitName() => Unit switch
   {
       UnitType.Piece => "dona",
       UnitType.Kilogram => "kg",
       UnitType.Meter => "m",
       _ => "noma'lum"
   };
   ```

#### Qachon Table yaxshiroq?
- Agar units dinamik bo'lsa (foydalanuvchi qo'sha oladi)
- Agar bir nechta unit tizimi bo'lsa (metric, imperial)
- Agar konversiyalar murakkab bo'lsa

---

## 2. Database Strukturas

### 2.1. Products Table

```sql
CREATE TABLE "Products" (
    "Id" uuid PRIMARY KEY,
    "Name" varchar(200) NOT NULL,
    "CostPrice" numeric(18,2) NOT NULL,
    "SalePrice" numeric(18,2) NOT NULL,
    "MinSalePrice" numeric(18,2) NOT NULL,
    "Quantity" numeric(18,2) NOT NULL DEFAULT 0,        -- ✅ DECIMAL
    "MinThreshold" numeric(18,2) NOT NULL DEFAULT 5,    -- ✅ DECIMAL
    "Unit" integer NOT NULL DEFAULT 1,                  -- ✅ NEW
    "CategoryId" integer,
    "MarketId" integer NOT NULL,
    "IsTemporary" boolean NOT NULL DEFAULT false,
    "IsDeleted" boolean NOT NULL DEFAULT false,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT now(),
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT now(),

    CONSTRAINT "CK_Products_Unit" CHECK ("Unit" IN (1, 2, 3)),
    CONSTRAINT "CK_Products_Quantity_NonNegative" CHECK ("Quantity" >= 0),
    CONSTRAINT "CK_Products_MinThreshold_NonNegative" CHECK ("MinThreshold" >= 0)
);

CREATE INDEX "IX_Products_Unit" ON "Products"("Unit");
CREATE INDEX "IX_Products_MarketId" ON "Products"("MarketId");
```

### 2.2. SaleItems Table

```sql
CREATE TABLE "SaleItems" (
    "Id" uuid PRIMARY KEY,
    "SaleId" uuid NOT NULL,
    "ProductId" uuid NOT NULL,
    "Quantity" numeric(18,2) NOT NULL,                  -- ✅ DECIMAL
    "CostPrice" numeric(18,2) NOT NULL,
    "SalePrice" numeric(18,2) NOT NULL,
    "Comment" text,
    "CreatedAt" timestamp with time zone NOT NULL DEFAULT now(),
    "UpdatedAt" timestamp with time zone NOT NULL DEFAULT now(),
    "IsDeleted" boolean NOT NULL DEFAULT false,

    CONSTRAINT "CK_SaleItems_Quantity_Positive" CHECK ("Quantity" > 0),
    CONSTRAINT "FK_SaleItems_Sales" FOREIGN KEY ("SaleId") REFERENCES "Sales"("Id"),
    CONSTRAINT "FK_SaleItems_Products" FOREIGN KEY ("ProductId") REFERENCES "Products"("Id")
);

CREATE INDEX "IX_SaleItems_SaleId" ON "SaleItems"("SaleId");
CREATE INDEX "IX_SaleItems_ProductId" ON "SaleItems"("ProductId");
```

---

## 3. C# Entity Classlar

### 3.1. Product Entity

```csharp
public class Product : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public bool IsTemporary { get; set; } = false;
    public Guid? CreatedBySellerId { get; set; }
    public bool IsDeleted { get; set; } = false;

    // Pricing
    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public decimal MinSalePrice { get; set; }

    // Stock - ✅ DECIMAL
    public decimal Quantity { get; set; }
    public decimal MinThreshold { get; set; } = 5m;

    // ✅ Unit Type
    public UnitType Unit { get; set; } = UnitType.Piece;

    // Multi-tenancy
    public int MarketId { get; set; }
    public Market? Market { get; set; }

    // Category
    public int? CategoryId { get; set; }
    public ProductCategory? Category { get; set; }

    // Navigation properties
    public User? CreatedBySeller { get; set; }
    public ICollection<SaleItem> SaleItems { get; set; } = new List<SaleItem>();
    public ICollection<Zakup> Zakups { get; set; } = new List<Zakup>();

    /// <summary>
    /// Omborda mavjudligini tekshirish
    /// </summary>
    public bool IsInStock(decimal requestedQuantity)
    {
        return Quantity >= requestedQuantity;
    }

    /// <summary>
    /// Minimal miqdordan pastga tushganmi
    /// </summary>
    public bool IsLowStock => Quantity <= MinThreshold;

    /// <summary>
    /// Unit nomini olish (uzbek)
    /// </summary>
    public string GetUnitName()
    {
        return Unit switch
        {
            UnitType.Piece => "dona",
            UnitType.Kilogram => "kg",
            UnitType.Meter => "m",
            _ => "noma'lum"
        };
    }
}
```

### 3.2. SaleItem Entity

```csharp
public class SaleItem : BaseEntity
{
    public Guid SaleId { get; set; }
    public Guid ProductId { get; set; }

    // ✅ Quantity - DECIMAL
    public decimal Quantity { get; set; }

    public decimal CostPrice { get; set; }
    public decimal SalePrice { get; set; }
    public string? Comment { get; set; }

    // Navigation properties
    public Sale Sale { get; set; } = null!;
    public Product Product { get; set; } = null!;

    /// <summary>
    /// Jami summa (Quantity * SalePrice)
    /// </summary>
    public decimal TotalPrice => Quantity * SalePrice;

    /// <summary>
    /// Foyda (SalePrice - CostPrice) * Quantity
    /// </summary>
    public decimal Profit => (SalePrice - CostPrice) * Quantity;

    /// <summary>
    /// Jami xaraj narx (Quantity * CostPrice)
    /// </summary>
    public decimal TotalCost => Quantity * CostPrice;
}
```

### 3.3. UnitType Enum

```csharp
namespace MarketSystem.Domain.Enums;

public enum UnitType
{
    /// <summary>
    /// Dona (piece) - butun sonlar uchun
    /// Masalan: 5 dona telefon, 10 dona stul
    /// </summary>
    Piece = 1,

    /// <summary>
    /// Kilogram - og'irlik o'lchovi
    /// Masalan: 1.5 kg olma, 0.5 kg shakar
    /// </summary>
    Kilogram = 2,

    /// <summary>
    /// Metr - uzunlik o'lchovi
    /// Masalan: 2.5 metr mato, 10.5 metr sim
    /// </summary>
    Meter = 3
}
```

---

## 4. Nima uchun DECIMAL?

### 4.1. Muammo: int vs decimal

**❌ Int ishlatilsa:**
```csharp
public int Quantity { get; set; }  // 1.5 kg bo'la olmaydi!
```

**✅ Decimal ishlatilsa:**
```csharp
public decimal Quantity { get; set; }  // 1.5 kg, 0.3 m bo'lishi mumkin
```

### 4.2. Misollar

| Product | Unit | Quantity (int) | Quantity (decimal) |
|---------|------|----------------|-------------------|
| Telefon | dona | 5 ✅ | 5.0 ✅ |
| Olma    | kg   | 1 ❌ (1.5 bo'lishi kerak) | 1.5 ✅ |
| Mato    | m    | 2 ❌ (2.5 bo'lishi kerak) | 2.5 ✅ |
| Shakar  | kg   | 0 ❌ (0.5 bo'lishi kerak) | 0.5 ✅ |

### 4.3. Technical Reasons

1. **Precision**: `decimal` 28-29 significant digits gacha aniq
2. **Financial calculations**: Pul hisob-kitoblari uchun mandatory
3. **Standart**: IEEE 754-compliant
4. **Database mapping**: PostgreSQL `numeric(18,2)` -> C# `decimal`

```csharp
// ❌ Xato:
int quantity = 1.5;  // Compile error!

// ✅ To'g'ri:
decimal quantity = 1.5m;  // Works!
decimal quantity = 1.50m;  // Same precision
decimal quantity = 5m;     // Whole numbers also work
```

---

## 5. Stock Kamaytirish Logikasi

### 5.1. Product Creation

```csharp
public async Task<ProductDto> CreateProductAsync(CreateProductRequest request, Guid? sellerId)
{
    var marketId = _currentMarketService.TryGetCurrentMarketId();

    var product = new Product
    {
        Id = Guid.NewGuid(),
        Name = request.Name,
        CostPrice = request.CostPrice,
        SalePrice = request.SalePrice,
        MinSalePrice = request.MinSalePrice,
        Quantity = request.Quantity,          // Initial stock
        MinThreshold = request.MinThreshold,  // Low stock alert
        Unit = (UnitType)request.Unit,        // dona/kg/m
        MarketId = marketId.Value,
        CategoryId = request.CategoryId
    };

    await _unitOfWork.Products.AddAsync(product);
    await _unitOfWork.SaveChangesAsync();

    return MapToDto(product);
}
```

### 5.2. Sale - Stock Kamaytirish

```csharp
public async Task<SaleItemDto> AddSaleItemAsync(AddSaleItemRequest request)
{
    // 1. Productni topish
    var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId);
    if (product is null)
        throw new NotFoundException("Product not found");

    // 2. ✅ Stock tekshirish
    if (!product.IsInStock(request.Quantity))
        throw new InvalidOperationException(
            $"Yetarli mahsulot yo'q. Mavjud: {product.Quantity} {product.GetUnitName()}, " +
            $"So'ralgan: {request.Quantity} {product.GetUnitName()}"
        );

    // 3. SaleItem yaratish
    var saleItem = new SaleItem
    {
        Id = Guid.NewGuid(),
        SaleId = request.SaleId,
        ProductId = request.ProductId,
        Quantity = request.Quantity,
        CostPrice = product.CostPrice,
        SalePrice = request.SalePrice,
        Comment = request.Comment
    };

    // 4. ✅ Stockni kamaytirish
    product.Quantity -= request.Quantity;

    // 5. Save
    await _unitOfWork.SaleItems.AddAsync(saleItem);
    _unitOfWork.Products.Update(product);
    await _unitOfWork.SaveChangesAsync();

    return MapToDto(saleItem);
}
```

### 5.3. Zakup (Purchase) - Stock Oshirish

```csharp
public async Task<ZakupDto> CreateZakupAsync(CreateZakupRequest request, Guid adminId)
{
    var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId);
    if (product is null)
        throw new NotFoundException("Product not found");

    // 1. Zakup yaratish
    var zakup = new Zakup
    {
        Id = Guid.NewGuid(),
        ProductId = request.ProductId,
        Quantity = request.Quantity,
        CostPrice = request.CostPrice,
        CreatedByAdminId = adminId,
        MarketId = product.MarketId
    };

    // 2. ✅ Stockni oshirish
    product.Quantity += request.Quantity;

    // 3. ✅ Weighted Average Cost Price
    // Masalan: 10 dona @ 10000 = 100000
    //          5 dona @ 12000 = 60000
    //          Jami: 15 dona @ 10666.67
    var oldTotalValue = product.Quantity * product.CostPrice;
    var newTotalValue = request.Quantity * request.CostPrice;
    var totalQuantity = product.Quantity + request.Quantity;
    product.CostPrice = (oldTotalValue + newTotalValue) / totalQuantity;

    await _unitOfWork.Zakups.AddAsync(zakup);
    _unitOfWork.Products.Update(product);
    await _unitOfWork.SaveChangesAsync();

    return MapToDto(zakup);
}
```

---

## 6. Edge Cases va Validation

### 6.1. Negative Stock

```csharp
// ❌ XATO:
product.Quantity = -5;  // Database constraint: CHECK ("Quantity" >= 0)

// ✅ TO'G'RI:
if (product.Quantity - requestedQuantity < 0)
    throw new InvalidOperationException("Insufficient stock");

product.Quantity -= requestedQuantity;  // Safe
```

### 6.2. Wrong Quantity Type

```csharp
// ❌ XATO:
public int Quantity { get; set; }
Quantity = 1.5;  // Compile error

// ✅ TO'G'RI:
public decimal Quantity { get; set; }
Quantity = 1.5m;  // Works
Quantity = 2m;    // Also works (whole numbers)
```

### 6.3. Unit Mismatch

```csharp
// ❌ XATO:
// Product: 5 kg olma
// Sale: 10 dona olma  // Unit mos emas!

// ✅ TO'G'RI:
// Har doim product unitiga e'tibor bering
var product = await GetProduct(productId);
var saleItem = new SaleItem
{
    Quantity = request.Quantity,  // 1.5
    // Product unit: kg -> Sale ham kg
};
```

### 6.4. Zero Quantity

```csharp
// ❌ XATO:
if (request.Quantity <= 0)
    throw new ArgumentException("Quantity must be positive");

// ✅ TO'G'RI:
// SaleItem uchun:
[Range(0.01, double.MaxValue, ErrorMessage = "Quantity must be positive")]
public decimal Quantity { get; set; }

// Product uchun (0 bo'lishi mumkin - stock yo'q):
public decimal Quantity { get; set; } = 0;
```

### 6.5. Too Many Decimal Places

```csharp
// ❌ XATO:
decimal quantity = 1.234567890m;  // Too precise!

// ✅ TO'G'RI:
// Database: numeric(18,2) -> 2 decimal places
decimal quantity = 1.23m;  // OK
decimal quantity = 1.2m;   // OK
decimal quantity = 1m;     // OK

// Validation:
if (Decimal.Round(quantity, 2) != quantity)
    throw new ArgumentException("Quantity max 2 decimal places");
```

---

## 7. DTO Structures

### 7.1. ProductDto

```csharp
public record ProductDto(
    Guid Id,
    string Name,
    decimal CostPrice,
    decimal SalePrice,
    decimal MinSalePrice,
    decimal Quantity,        // ✅ DECIMAL
    decimal MinThreshold,    // ✅ DECIMAL
    int Unit,                // ✅ UnitType enum as int
    string UnitName,         // "dona", "kg", "m"
    int? CategoryId,
    string? CategoryName,
    bool IsTemporary,
    bool IsInStock,
    bool IsLowStock
);
```

### 7.2. CreateProductRequest

```csharp
public record CreateProductRequest(
    string Name,
    decimal CostPrice,
    decimal SalePrice,
    decimal MinSalePrice,
    decimal Quantity,        // ✅ DECIMAL
    decimal MinThreshold,    // ✅ DECIMAL
    int Unit,                // ✅ UnitType enum as int
    int? CategoryId,
    bool IsTemporary = false
);
```

### 7.3. SaleItemDto

```csharp
public record SaleItemDto(
    Guid Id,
    Guid SaleId,
    Guid ProductId,
    string ProductName,
    decimal Quantity,        // ✅ DECIMAL
    decimal CostPrice,
    decimal SalePrice,
    decimal TotalPrice,      // Quantity * SalePrice
    decimal Profit,          // (SalePrice - CostPrice) * Quantity
    string Unit,             // "dona", "kg", "m"
    string? Comment
);
```

---

## 8. API Endpoints

### 8.1. Create Product

```http
POST /api/Products/CreateProduct
Content-Type: application/json

{
  "name": "Olma",
  "costPrice": 8000,
  "salePrice": 12000,
  "minSalePrice": 10000,
  "quantity": 15.5,        // ✅ DECIMAL - 15.5 kg
  "minThreshold": 5.0,     // ✅ DECIMAL
  "unit": 2,               // ✅ UnitType.Kilogram
  "categoryId": 1,
  "isTemporary": false
}
```

### 8.2. Add Sale Item

```http
POST /api/Sales/AddSaleItem/{saleId}
Content-Type: application/json

{
  "saleId": "123e4567-e89b-12d3-a456-426614174000",
  "productId": "456e7890-e12b-34d1-b567-539628418932",
  "quantity": 1.5,         // ✅ DECIMAL - 1.5 kg olma
  "costPrice": 8000,
  "salePrice": 12000,
  "comment": "Sifatli olma"
}
```

**Response:**
```json
{
  "totalPrice": 18000,      // 1.5 * 12000
  "profit": 6000,           // (12000 - 8000) * 1.5
  "unit": "kg"
}
```

### 8.3. Get Product

```http
GET /api/Products/GetProductById/{id}

Response:
{
  "id": "456e7890-e12b-34d1-b567-539628418932",
  "name": "Olma",
  "quantity": 14.0,         // 15.5 - 1.5 (after sale)
  "minThreshold": 5.0,
  "unit": 2,
  "unitName": "kg",
  "isInStock": true,
  "isLowStock": false
}
```

---

## 9. Testing Strategy

### 9.1. Unit Tests

```csharp
[Fact]
public void Product_ShouldHandleDecimalQuantity()
{
    // Arrange
    var product = new Product
    {
        Name = "Olma",
        Quantity = 15.5m,
        Unit = UnitType.Kilogram
    };

    // Act
    var saleQuantity = 1.5m;
    product.Quantity -= saleQuantity;

    // Assert
    Assert.Equal(14.0m, product.Quantity);
}

[Fact]
public void Product_ShouldThrowInsufficientStock()
{
    // Arrange
    var product = new Product
    {
        Quantity = 1.5m,
        Unit = UnitType.Kilogram
    };

    // Act & Assert
    Assert.Throws<InvalidOperationException>(() =>
    {
        if (!product.IsInStock(2.0m))
            throw new InvalidOperationException("Insufficient stock");
    });
}
```

---

## 10. Migration Plan

### Step 1: Add Unit column
```sql
ALTER TABLE "Products" ADD "Unit" integer NOT NULL DEFAULT 1;
```

### Step 2: Change Quantity to decimal
```sql
ALTER TABLE "Products" ALTER "Quantity" TYPE numeric(18,2);
ALTER TABLE "SaleItems" ALTER "Quantity" TYPE numeric(18,2);
```

### Step 3: Add constraints
```sql
ALTER TABLE "Products" ADD CONSTRAINT "CK_Products_Unit" CHECK ("Unit" IN (1, 2, 3));
ALTER TABLE "Products" ADD CONSTRAINT "CK_Products_Quantity_NonNegative" CHECK ("Quantity" >= 0);
```

### Step 4: Update application code
- Update entities to use `decimal Quantity`
- Add `UnitType` enum
- Update DTOs
- Update services

### Step 5: Test thoroughly
- Unit tests
- Integration tests
- Manual testing

---

## 11. Summary

### ✅ YANGILANISHLAR:

1. **UnitType Enum** - dona/kg/m uchun
2. **Decimal Quantity** - 1.5 kg bo'lishi mumkin
3. **Validation** - Stock tekshirish, manfiy qiymatlar oldini olish
4. **DTOs** - ProductDto, CreateProductRequest yangilandi
5. **Services** - Stock management logikasi
6. **Migration** - SQL skriptlar tayyor

### 🔥 KLUCH O'ZGARISHLAR:

- `int Quantity` → `decimal Quantity` ✅
- `Unit` column qo'shildi ✅
- `IsInStock()`, `IsLowStock`, `GetUnitName()` methods ✅
- Constraints: `Quantity >= 0`, `Unit IN (1,2,3)` ✅

### 🎯 NATIJA:

Production-ready, scalable, xatolarga chidamli arxitekturaga ega bo'lgan tovarlar moduli!

---

**Created:** 2026-02-23
**Version:** 1.0.0
**Author:** Backend Architect
