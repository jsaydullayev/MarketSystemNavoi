# 📄 MUKAMMAL TEXNIK VAZIFA (BACKEND): OUTSOURCING SALE SYSTEM - FIX

**Loyiha:** MarketSystemNavoi ERP
**Versiya:** v1.1 (Fix Version)
**Sana:** 2026-05-01
**Sohalar:** SaleService Business Logic
**Strategiya:** IsExternal Flag Implementation (Fix)

---

## 📋 TABLE OF CONTENTS

1. [Overview](#overview)
2. [Qilinishi Kerak Bo'lgan Ischlar](#qilinishi-kerak-bolgan-ishlar)
3. [Implementatsiya Qadamlari](#implementatsiya-qadamlari)
4. [Kod O'zgarishlari](#kod-ozgarishlari)
5. [Testlash](#testlash)
6. [Risk Management](#risk-management)

---

## OVERVIEW

### Tahlil Natijalari

Avvalgi tahlil asosida quyidagi muammolar aniqlandi:

| Modul | TZ Bo'yicha | Amaldagi Holat | Natija |
|--------|--------------|-----------------|--------|
| SaleItem Entity | ✅ Barchasi | ✅ Barchasi | ✅ To'liq |
| AppDbContext | ✅ Barchasi | ✅ Barchasi | ✅ To'liq |
| DTOs | ✅ Barchasi | ✅ Barchasi | ✅ To'liq |
| ReportService | ✅ Barchasi | ✅ Barchasi | ✅ To'liq |
| **SaleService.AddSaleItemAsync** | ❌ IsExternal sharti | ❌ IsExternal sharti yo'q | ❌ XATO |
| **SaleService.RemoveSaleItemAsync** | ❌ IsExternal sharti | ❌ IsExternal sharti yo'q | ❌ XATO |
| **SaleService.CancelSaleAsync** | ❌ IsExternal sharti | ❌ IsExternal sharti yo'q | ❌ XATO |
| **SaleService.ReturnSaleItemAsync** | ⚠️ Partial | ⚠️ IsExternal sharti yo'q | ❌ XATO |
| **SaleService.UpdateSaleItemPriceAsync** | ❌ Tashqi narx | ❌ Tashqi taqiqlanadi | ❌ XATO |

---

## QILINISHI KERAK BOLGAN ISHLAR

### 1. SaleService.AddSaleItemAsync

**Muammo:** Tashqi mahsulotlar (IsExternal = true) qo'shilmaydi

**Hozirgi holat (Line 342-471):**
```csharp
// ❌ Hozir: Faqat oddiy mahsulotlar qo'shiladi
if (request.ProductId == null)
    throw new InvalidOperationException("ProductId kerak (oddiy mahsulot uchun)");

var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId.Value, cancellationToken);
// ... stokni kamaytirish
```

**Kerak bo'lgan o'zgarish:**
```csharp
// ✅ ISEXTERNAL SHARTI bilan
if (!request.IsExternal)
{
    // ---- ORDINARY PRODUCT (Oddiy mahsulot) ----
    if (request.ProductId == null)
        throw new InvalidOperationException("ProductId kerak (oddiy mahsulot uchun)");

    var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId.Value, cancellationToken);
    if (product is null)
        throw new InvalidOperationException("Product not found");

    if (product.MarketId != sale.MarketId)
        throw new InvalidOperationException("Product does not belong to this market");

    if (product.Quantity <= 0)
        throw new InvalidOperationException("Bu mahsulot omborda yo'q");

    if (product.Quantity < request.Quantity)
        throw new InvalidOperationException($"Omborda yetarli mahsulot yo'q. Mavjud: {product.Quantity}, So'ralgan: {request.Quantity}");

    // ... create/update sale item, update stock
}
else
{
    // ---- EXTERNAL PRODUCT (Tashqi mahsulot) ----
    if (string.IsNullOrEmpty(request.ExternalProductName))
        throw new InvalidOperationException("ExternalProductName kerak (tashqi mahsulot uchun)");

    if (request.ExternalCostPrice >= request.SalePrice)
        throw new InvalidOperationException("Tashqi tannarx sotuv narxidan katta yoki teng bo'lishi mumkin emas");

    // Create new sale item WITHOUT ProductId
    var saleItem = new SaleItem
    {
        Id = Guid.NewGuid(),
        SaleId = saleId,
        IsExternal = true,  // ✅ Tashqi mahsulot
        ProductId = null,  // ✅ Nullable
        ExternalProductName = request.ExternalProductName,
        ExternalCostPrice = request.ExternalCostPrice.Value,
        Quantity = request.Quantity,
        SalePrice = request.SalePrice,
        Comment = request.Comment
    };

    await _unitOfWork.SaleItems.AddAsync(saleItem, cancellationToken);
    
    // ✅ NO STOCK UPDATE - Tashqi mahsulotlar ombor qoldig'iga ta'sir qilmaydi
    
    // Update sale total
    var itemTotal = request.Quantity * request.SalePrice;
    sale.TotalAmount += itemTotal;
    _unitOfWork.Sales.Update(sale);

    await _unitOfWork.SaveChangesAsync(cancellationToken);

    // Mapping
    return MapSaleItemToDto(
        saleItem,
        saleItem.ExternalProductName ?? "Unknown",
        ""
    );
}
```

---

### 2. SaleService.RemoveSaleItemAsync

**Muammo:** Tashqi mahsulotlarni o'chirganda stok qaytarilmoqda (xato)

**Hozirgi holat (Line 499-507):**
```csharp
// ❌ Hozir: Har doim stok qaytariladi
if (saleItem.ProductId == null)
    throw new InvalidOperationException("ProductId null (tashqi mahsulot)");

var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId.Value, cancellationToken);
product.Quantity += saleItem.Quantity;  // ❌ Tashqi mahsulotlar uchun ham qo'llanmoqda
```

**Kerak bo'lgan o'zgarish:**
```csharp
// ============================================
// ✅ ISEXTERNAL SHARTI - STOKNI SAQLASH
// ============================================
if (!saleItem.IsExternal)
{
    // ---- ORDINARY PRODUCT (Oddiy mahsulot) ----
    var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId.Value, cancellationToken);
    if (product is null)
        throw new InvalidOperationException("Product not found");

    if (product.MarketId != sale.MarketId)
        throw new InvalidOperationException("Product does not belong to this market");

    // Restore stock
    product.Quantity += saleItem.Quantity;
    _unitOfWork.Products.Update(product);
}
else
{
    // ---- EXTERNAL PRODUCT (Tashqi mahsulot) ----
    // ✅ NO STOCK RESTORE - Tashqi mahsulotlar ombor qoldig'iga ta'sir qilmaydi
}
```

---

### 3. SaleService.CancelSaleAsync

**Muammo:** Savdo bekor qilganda tashqi mahsulotlar uchun ham stok qaytarilmoqda (xato)

**Hozirgi holat (Line 784-799):**
```csharp
// ❌ Hozir: Barcha itemlar uchun stok qaytariladi
foreach (var item in saleItems)
{
    var products = await _unitOfWork.Products.FindAsync(
        p => p.Id == item.ProductId && p.MarketId == marketId,
        cancellationToken);
    var product = products.FirstOrDefault();

    if (product != null)
    {
        product.Quantity += item.Quantity;  // ❌ Tashqi mahsulotlar uchun ham
        _unitOfWork.Products.Update(product);
    }
}
```

**Kerak bo'lgan o'zgarish:**
```csharp
// Restore stock for all items
var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == saleId, cancellationToken);
foreach (var item in saleItems)
{
    // ============================================
    // ✅ ISEXTERNAL SHARTI - STOKNI QAYTARISH
    // ============================================
    if (!item.IsExternal)
    {
        // ---- ORDINARY PRODUCT (Oddiy mahsulot) ----
        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == item.ProductId.Value && p.MarketId == marketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        if (product != null)
        {
            product.Quantity += item.Quantity;
            _unitOfWork.Products.Update(product);
        }
    }
    // ---- EXTERNAL PRODUCT (Tashqi mahsulot) ----
    // ✅ Tashqi mahsulotlar - stokni o'zgarmaslik
}
```

---

### 4. SaleService.ReturnSaleItemAsync

**Muammo:** Qaytarganda stokni o'zgartirishda IsExternal sharti yo'q

**Hozirgi holat (Line 1418-1425):**
```csharp
// ❌ Hozir: Product null check bor, lekin IsExternal sharti yo'q
if (saleItem.Product != null)
{
    var oldStock = saleItem.Product.Quantity;
    saleItem.Product.Quantity += returnQuantity;
    _context.Products.Update(saleItem.Product);
}
```

**Kerak bo'lgan o'zgarish:**
```csharp
// 2. Mahsulot stock'iga qaytarish
// ✅ STOK UPDATE - ISEXTERNAL SHARTI
if (!saleItem.IsExternal && saleItem.Product != null)
{
    // Faqat oddiy mahsulotlar uchun stokni qaytarish
    var oldStock = saleItem.Product.Quantity;
    saleItem.Product.Quantity += returnQuantity;
    _context.Products.Update(saleItem.Product);
}
// Tashqi mahsulotlar - stokni o'zgarmaslik
```

---

### 5. SaleService.UpdateSaleItemPriceAsync

**Muammo:** Tashqi mahsulotlar narxini o'zgartirish taqiqlanmoqda

**Hozirgi holat (Line 1113-1117):**
```csharp
// ❌ Hozir: Tashqi mahsulotlar narxini o'zgartirish taqiqlanadi
if (saleItem.ProductId == null)
    throw new InvalidOperationException("ProductId null (tashqi mahsulot)");
```

**Kerak bo'lgan o'zgarish:**
```csharp
// Store old price
var oldPrice = saleItem.SalePrice;

// Update SaleItem price
saleItem.SalePrice = request.NewPrice;
_saleItem.SaleItems.Update(saleItem);

// ... (qolgan qismlar o'zgarmaydi)

// Get product name for response
string productName;
string unit = "";
if (!saleItem.IsExternal)
{
    // Oddiy mahsulot
    var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId.Value, cancellationToken);
    productName = product?.Name ?? "Unknown";
    unit = product?.GetUnitName() ?? "";
}
else
{
    // Tashqi mahsulot - ExternalProductName ishlatish
    productName = saleItem.ExternalProductName ?? "Tashqi mahsulot";
    unit = "";
}

return MapSaleItemToDto(saleItem, productName, unit);
```

---

## IMPLEMENTATSIYA QADAMLARI

| # | Action | File | Line | Prioritet |
|---|---------|------|-----------|
| 1 | AddSaleItemAsync - IsExternal sharti qo'shish | SaleService.cs | 362-471 | ⭐ YUQORI |
| 2 | RemoveSaleItemAsync - IsExternal sharti qo'shish | SaleService.cs | 498-553 | ⭐ YUQORI |
| 3 | CancelSaleAsync - IsExternal sharti qo'shish | SaleService.cs | 786-799 | ⭐ YUQORI |
| 4 | ReturnSaleItemAsync - IsExternal sharti qo'shish | SaleService.cs | 1418-1425 | ⭐ YUQORI |
| 5 | UpdateSaleItemPriceAsync - tashqi mahsulot ruxsat | SaleService.cs | 1113-1117 | ⭐ YUQORI |
| 6 | Migration yaratish (bor bo'lsa) | CLI | - | ⭐ YUQORI |
| 7 | Testlash | - | - | ⭐ YUQORI |

---

## KOD O'ZGARISHLARI

### Fayl: MarketSystem.Application/Services/SaleService.cs

#### 1. AddSaleItemAsync - Start of method (Line ~362)

**ESKI KOD:**
```csharp
// Validate ProductId for ordinary products
if (request.ProductId == null)
    throw new InvalidOperationException("ProductId kerak (oddiy mahsulot uchun)");
var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId.Value, cancellationToken);
```

**YANGI KOD:**
```csharp
// ============================================
// ✅ ISEXTERNAL SHARTI - TASHQI MAHSULOT
// ============================================
if (!request.IsExternal)
{
    // ---- ORDINARY PRODUCT (Oddiy mahsulot) ----
    // ProductId bo'lishi shart
    if (request.ProductId == null)
        throw new InvalidOperationException("ProductId kerak (oddiy mahsulot uchun)");

    var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId.Value, cancellationToken);
    if (product is null)
        throw new InvalidOperationException("Product not found");

    // SECURITY: Verify product belongs to same market as sale
    if (product.MarketId != sale.MarketId)
        throw new InvalidOperationException("Product does not belong to this market");

    // Validate stock
    if (product.Quantity <= 0)
        throw new InvalidOperationException("Bu mahsulot omborda yo'q");

    if (product.Quantity < request.Quantity)
        throw new InvalidOperationException($"Omborda yetarli mahsulot yo'q. Mavjud: {product.Quantity}, So'ralgan: {request.Quantity}");

    SaleItem? resultSaleItem;
    decimal itemTotal;

    // CHECK: Is this product already in sale?
    var existingItem = saleItems.FirstOrDefault(si => si.ProductId == request.ProductId);

    if (existingItem != null)
    {
        // Product exists - UPDATE existing item
        var oldQuantity = existingItem.Quantity;
        existingItem.Quantity += request.Quantity;

        _unitOfWork.SaleItems.Update(existingItem);

        // Update stock
        product.Quantity -= request.Quantity;
        _context.Entry(product).State = EntityState.Modified;
        _unitOfWork.Products.Update(product);

        // Update sale total
        var oldItemTotal = oldQuantity * existingItem.SalePrice;
        itemTotal = existingItem.Quantity * existingItem.SalePrice;
        sale.TotalAmount = sale.TotalAmount - oldItemTotal + itemTotal;
        _unitOfWork.Sales.Update(sale);

        resultSaleItem = existingItem;
    }
    else
    {
        // Product doesn't exist - CREATE new item
        var saleItem = new SaleItem
        {
            Id = Guid.NewGuid(),
            SaleId = saleId,
            ProductId = request.ProductId,
            IsExternal = false,  // ✅ Oddiy mahsulot
            Quantity = request.Quantity,
            CostPrice = product.CostPrice,
            SalePrice = request.SalePrice,
            Comment = request.Comment
        };

        await _unitOfWork.SaleItems.AddAsync(saleItem, cancellationToken);

        // Update stock
        product.Quantity -= request.Quantity;
        _context.Entry(product).State = EntityState.Modified;
        _unitOfWork.Products.Update(product);

        // Update sale total
        itemTotal = request.Quantity * request.SalePrice;
        sale.TotalAmount += itemTotal;
        _unitOfWork.Sales.Update(sale);

        resultSaleItem = saleItem;
    }

    await _unitOfWork.SaveChangesAsync(cancellationToken);

    return MapSaleItemToDto(resultSaleItem, product.Name, product.GetUnitName());
}
else
{
    // ---- EXTERNAL PRODUCT (Tashqi mahsulot) ----
    // ExternalProductName bo'lishi shart
    if (string.IsNullOrEmpty(request.ExternalProductName))
        throw new InvalidOperationException("ExternalProductName kerak (tashqi mahsulot uchun)");

    // ✅ VALIDATION: Tashqi tannarx sotuv narxidan katta bo'lishi mumkin emas
    if (request.ExternalCostPrice >= request.SalePrice)
        throw new InvalidOperationException("Tashqi tannarx sotuv narxidan katta yoki teng bo'lishi mumkin emas");

    SaleItem? resultSaleItem;
    decimal itemTotal;

    // CHECK: Is this external product already in sale? (by name)
    var existingItem = saleItems.FirstOrDefault(si =>
        si.IsExternal &&
        si.ExternalProductName == request.ExternalProductName);

    if (existingItem != null)
    {
        // External product exists - UPDATE existing item
        var oldQuantity = existingItem.Quantity;
        existingItem.Quantity += request.Quantity;

        _unitOfWork.SaleItems.Update(existingItem);

        // Update sale total
        var oldItemTotal = oldQuantity * existingItem.SalePrice;
        itemTotal = existingItem.Quantity * existingItem.SalePrice;
        sale.TotalAmount = sale.TotalAmount - oldItemTotal + itemTotal;
        _unitOfWork.Sales.Update(sale);

        resultSaleItem = existingItem;
    }
    else
    {
        // External product doesn't exist - CREATE new item
        var saleItem = new SaleItem
        {
            Id = Guid.NewGuid(),
            SaleId = saleId,
            IsExternal = true,  // ✅ Tashqi mahsulot
            ProductId = null,  // ✅ Nullable
            ExternalProductName = request.ExternalProductName,
            ExternalCostPrice = request.ExternalCostPrice.Value,
            Quantity = request.Quantity,
            SalePrice = request.SalePrice,
            Comment = request.Comment
        };

        await _unitOfWork.SaleItems.AddAsync(saleItem, cancellationToken);

        // ✅ NO STOCK UPDATE - Tashqi mahsulotlar ombor qoldig'iga ta'sir qilmaydi

        // Update sale total
        itemTotal = request.Quantity * request.SalePrice;
        sale.TotalAmount += itemTotal;
        _unitOfWork.Sales.Update(sale);

        resultSaleItem = saleItem;
    }

    await _unitOfWork.SaveChangesAsync(cancellationToken);

    // Mapping: Product name = ExternalProductName, Unit = empty
    return MapSaleItemToDto(
        resultSaleItem,
        resultSaleItem.ExternalProductName ?? "Unknown",
        ""
    );
}
```

---

#### 2. RemoveSaleItemAsync - Stock restore section (Line ~498)

**ESKI KOD:**
```csharp
if (saleItem.ProductId == null)
    throw new InvalidOperationException("ProductId null (tashqi mahsulot)");

var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId.Value, cancellationToken);
// ... restore full stock
product.Quantity += saleItem.Quantity;
```

**YANGI KOD:**
```csharp
// ============================================
// ✅ ISEXTERNAL SHARTI - STOKNI SAQLASH
// ============================================
if (!saleItem.IsExternal)
{
    // ---- ORDINARY PRODUCT (Oddiy mahsulot) ----
    // ProductId bo'lishi shart
    var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId.Value, cancellationToken);
    if (product is null)
        throw new InvalidOperationException("Product not found");

    if (product.MarketId != sale.MarketId)
        throw new InvalidOperationException("Product does not belong to this market");

    SaleItem? resultSaleItem;
    decimal itemTotal;

    if (request.Quantity == 0 || request.Quantity >= saleItem.Quantity)
    {
        // Remove entire item from sale
        _unitOfWork.SaleItems.Delete(saleItem);

        // ✅ Restore full stock (faqat oddiy mahsulotlar uchun)
        product.Quantity += saleItem.Quantity;
        _context.Entry(product).State = EntityState.Modified;
        _unitOfWork.Products.Update(product);

        // Update sale total
        itemTotal = saleItem.Quantity * saleItem.SalePrice;
        sale.TotalAmount -= itemTotal;
        _unitOfWork.Sales.Update(sale);

        resultSaleItem = saleItem;
    }
    else
    {
        // Partial quantity removal
        var oldQuantity = saleItem.Quantity;
        saleItem.Quantity -= request.Quantity;
        _unitOfWork.SaleItems.Update(saleItem);

        // ✅ Restore partial stock (faqat oddiy mahsulotlar uchun)
        product.Quantity += request.Quantity;
        _context.Entry(product).State = EntityState.Modified;
        _unitOfWork.Products.Update(product);

        // Update sale total
        var oldItemTotal = oldQuantity * saleItem.SalePrice;
        itemTotal = saleItem.Quantity * saleItem.SalePrice;
        sale.TotalAmount = sale.TotalAmount - oldItemTotal + itemTotal;
        _unitOfWork.Sales.Update(sale);

        resultSaleItem = saleItem;
    }

    await _unitOfWork.SaveChangesAsync(cancellationToken);

    return MapSaleItemToDto(resultSaleItem, product.Name, product.GetUnitName());
}
else
{
    // ---- EXTERNAL PRODUCT (Tashqi mahsulot) ----
    // ✅ NO STOCK RESTORE - Tashqi mahsulotlar ombor qoldig'iga ta'sir qilmaydi

    SaleItem? resultSaleItem;
    decimal itemTotal;

    if (request.Quantity == 0 || request.Quantity >= saleItem.Quantity)
    {
        // Remove entire item from sale
        _unitOfWork.SaleItems.Delete(saleItem);

        // Update sale total
        itemTotal = saleItem.Quantity * saleItem.SalePrice;
        sale.TotalAmount -= itemTotal;
        _unitOfWork.Sales.Update(sale);

        resultSaleItem = saleItem;
    }
    else
    {
        // Partial quantity removal
        var oldQuantity = saleItem.Quantity;
        saleItem.Quantity -= request.Quantity;
        _unitOfWork.SaleItems.Update(saleItem);

        // Update sale total
        var oldItemTotal = oldQuantity * saleItem.SalePrice;
        itemTotal = saleItem.Quantity * saleItem.SalePrice;
        sale.TotalAmount = sale.TotalAmount - oldItemTotal + itemTotal;
        _unitOfWork.Sales.Update(sale);

        resultSaleItem = saleItem;
    }

    await _unitOfWork.SaveChangesAsync(cancellationToken);

    // Mapping: Product name = ExternalProductName, Unit = empty
    return MapSaleItemToDto(
        resultSaleItem,
        resultSaleItem.ExternalProductName ?? "Unknown",
        ""
    );
}
```

---

#### 3. CancelSaleAsync - Stock restore section (Line ~786)

**ESKI KOD:**
```csharp
foreach (var item in saleItems)
{
    var products = await _unitOfWork.Products.FindAsync(
        p => p.Id == item.ProductId && p.MarketId == marketId,
        cancellationToken);
    var product = products.FirstOrDefault();

    if (product != null)
    {
        product.Quantity += item.Quantity;  // ❌ Tashqi mahsulotlar uchun ham
        _unitOfWork.Products.Update(product);
    }
}
```

**YANGI KOD:**
```csharp
// Restore stock for all items
var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == saleId, cancellationToken);
foreach (var item in saleItems)
{
    // ============================================
    // ✅ ISEXTERNAL SHARTI - STOKNI QAYTARISH
    // ============================================
    if (!item.IsExternal)
    {
        // ---- ORDINARY PRODUCT (Oddiy mahsulot) ----
        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == item.ProductId.Value && p.MarketId == marketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        if (product != null)
        {
            product.Quantity += item.Quantity;
            _context.Entry(product).State = EntityState.Modified;
            _unitOfWork.Products.Update(product);
        }
    }
    // ---- EXTERNAL PRODUCT (Tashqi mahsulot) ----
    // ✅ Tashqi mahsulotlar - stokni o'zgarmaslik
}
```

---

#### 4. ReturnSaleItemAsync - Stock update section (Line ~1418)

**ESKI KOD:**
```csharp
if (saleItem.Product != null)
{
    var oldStock = saleItem.Product.Quantity;
    saleItem.Product.Quantity += returnQuantity;
    _context.Products.Update(saleItem.Product);
}
```

**YANGI KOD:**
```csharp
// 2. Mahsulot stock'iga qaytarish
// ✅ STOK UPDATE - ISEXTERNAL SHARTI
if (!saleItem.IsExternal && saleItem.Product != null)
{
    // Faqat oddiy mahsulotlar uchun stokni qaytarish
    var oldStock = saleItem.Product.Quantity;
    saleItem.Product.Quantity += returnQuantity;
    _context.Products.Update(saleItem.Product);

    _logger.LogInformation("Product stock updated: ProductId={ProductId}, OldStock={OldStock}, NewStock={NewStock}",
        saleItem.ProductId, oldStock, saleItem.Product.Quantity);
}
// Tashqi mahsulotlar - stokni o'zgarmaslik
```

---

#### 5. UpdateSaleItemPriceAsync - Product name section (Line ~1113)

**ESKI KOD:**
```csharp
if (saleItem.ProductId == null)
    throw new InvalidOperationException("ProductId null (tashqi mahsulot)");

return MapSaleItemToDto(saleItem, product?.Name ?? "Unknown", product?.GetUnitName() ?? "");
```

**YANGI KOD:**
```csharp
// Store old price
var oldPrice = saleItem.SalePrice;

// Update SaleItem price
saleItem.SalePrice = request.NewPrice;
_saleItem.SaleItems.Update(saleItem);

// ... (recalculate total amount, debt, audit log - o'zgarmaydi)

// Get product name for response
string productName;
string unit = "";
if (!saleItem.IsExternal)
{
    // Oddiy mahsulot
    var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId.Value, cancellationToken);
    productName = product?.Name ?? "Unknown";
    unit = product?.GetUnitName() ?? "";
}
else
{
    // Tashqi mahsulot - ExternalProductName ishlatish
    productName = saleItem.ExternalProductName ?? "Tashqi mahsulot";
    unit = "";
}

return MapSaleItemToDto(saleItem, productName, unit);
```

---

## TESTLASH

### Test Senariylari

| # | Test | Kutayotgan Natija | Izoh |
|---|-------|-----------------|-------|
| 1 | Oddiy mahsulot qo'shish | Stok kamayadi | Existing behavior |
| 2 | Tashqi mahsulot qo'shish (IsExternal=true) | Stok o'zgarmaydi | New behavior |
| 3 | Tashqi mahsulot o'chirish | Stok qaytarilmaydi | New behavior |
| 4 | Tashqi mahsulotli savdo bekor qilish | Stok qaytarilmaydi | New behavior |
| 5 | Tashqi mahsulotni qaytarish | Stok qaytarilmaydi | New behavior |
| 6 | Tashqi mahsulot narxini o'zgartirish | Narx yangilanadi | New behavior |
| 7 | Tashqi tannarx > sotuv narx validation | Xatolik | New behavior |
| 8 | Profit report - oddiy | Profit to'g'ri hisoblanadi | Existing behavior |
| 9 | Profit report - tashqi | Profit to'g'ri hisoblanadi | New behavior |

---

## RISK MANAGEMENT

### Risk #1: IsExternal sharti unutib qolishi

| Ehtimollik | Oqibat | Yechim |
|------------|--------|-------|
| YUQORI | Stok noto'g'ri hisoblanishi | Code review qilish |

### Risk #2: Tashqi mahsulot narxini o'zgartirish taqiqlanmasligi

| Ehtimollik | Oqibat | Yechim |
|------------|--------|-------|
| O'RTA | Tashqi mahsulotnarxi o'zgara olmaydi | UpdateSaleItemPriceAsync o'zgartirish |

### Risk #3: Testlash o'tkazib qolishi

| Ehtimollik | Oqibat | Yechim |
|------------|--------|-------|
| YUQORI | Production da xatolik bo'lishi | Test DB da sinash, keyin prod |

---

## ACCEPTANCE CRITERIA

### Functional

- [x] Tashqi mahsulot qo'shish (AddSaleItemAsync - IsExternal)
- [x] Tashqi mahsulot o'chirish (RemoveSaleItemAsync - IsExternal)
- [x] Tashqi mahsulot savdo bekor qilish (CancelSaleAsync - IsExternal)
- [x] Tashqi mahsulot qaytarish (ReturnSaleItemAsync - IsExternal)
- [x] Stok o'zgarmasligi (barcha metodlarda)
- [x] Foyda to'g'ri hisoblanishi (ReportService - already working)
- [x] DTO mapping to'g'ri ishlashi (already working)
- [x] Tashqi mahsulot narxini o'zgartirish ruxsati (UpdateSaleItemPriceAsync)

### Non-Functional

- [ ] Migration yaratish va bazaga apply qilish
- [ ] Performance testlash
- [ ] Integration testlash

---

**TZ Yakunlandi.** Implementatsiyani boshlashga tayyormiz!
