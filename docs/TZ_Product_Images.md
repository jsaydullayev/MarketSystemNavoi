# TZ — Tovar (Mahsulot) Rasmlari

> **Status:** ✅ BAJARILDI (kod tayyor, testlar yashil) · **Sana:** 2026-06-05
> **Modul:** Products + Sales (faqat ko'rsatish) · **Tamoyil:** mavjud ishlashga ta'sir qilmaslik
>
> Implementatsiya xulosasi va deploy cheklisti uchun §12 ga qarang.

---

## 1. Qamrov (aniqlangan)

| Savol | Qaror |
|---|---|
| Rasm majburiymi? | **Yo'q** — `null` bo'lishi mumkin. Rasmsiz tovarlar bugungidek ishlaydi. |
| Qayerda yuklanadi? | **Faqat admin mahsulot formasi** (`products.edit`). Sotuvchi yuklamaydi. |
| Qayerda ko'rsatiladi? | **Faqat savdo (POS) grid'ida** — tovarni vizual aniqlashtirish uchun. |
| Qanday UX? | Kartada **thumbnail** + **uzun bosish (long-press)** → kattalashtirilgan preview. Oddiy bosish **o'zgarmaydi** (savatga qo'shadi). |
| Boshqa ekranlarda? | Yo'q (admin ro'yxati, hisobotlar va h.k. tegmaydi). |

**Asosiy tamoyil:** mavjud savdo/mahsulot oqimlari ishlashiga **nol ta'sir**. Rasm — qo'shimcha, lazy-yuklanadigan, keshlanadigan qatlam.

---

## 2. Mavjud holat (qayta ishlatiladigan komponentlar)

| Komponent | Joylashuv | Holat |
|---|---|---|
| Magic-byte validator | [ImageContentValidator.cs](../MarketSystem.API/Validation/ImageContentValidator.cs) | ✅ Qayta ishlatamiz |
| Format enum (JPEG/PNG/GIF/WebP) | [ImageKind.cs](../MarketSystem.API/Validation/ImageKind.cs) | ✅ |
| Upload pattern (referens) | [UsersController.cs:170](../MarketSystem.API/Controllers/UsersController.cs#L170) (avatar) | ✅ Pattern |
| Klient picker pattern | [profile_image_picker.dart](../MarketSystem.Client/lib/features/profile/widgets/profile_image_picker.dart) | ✅ Pattern |
| `image_picker`, `cached_network_image` | `pubspec.yaml` | ✅ Allaqachon bor |
| Static serving | [Program.cs:675](../MarketSystem.API/Program.cs#L675) `UseStaticFiles()` | ✅ |
| POS mahsulot kartasi | [continue_sale_product_card.dart](../MarketSystem.Client/lib/features/sales/presentation/widgets/continue_sale_product_card.dart) | 🎯 Bu yerga thumbnail |
| POS grid | [continue_sale_screen.dart:621](../MarketSystem.Client/lib/features/sales/presentation/screens/continue_sale_screen.dart#L621) (3 ustun, tap=savat) | 🎯 long-press qo'shiladi |

### 2.1. Nega base64-in-DB EMAS (ishlashga ta'sir)

Avatar base64 ni DB ustuniga saqlaydi — bitta avatar uchun OK. Lekin POS grid [continue_sale_screen.dart:621](../MarketSystem.Client/lib/features/sales/presentation/screens/continue_sale_screen.dart#L621) **barcha** mahsulotni ro'yxatlaydi. Agar rasm DB'da base64 bo'lsa, har bir mahsulot ro'yxati so'rovi yuzlab rasm baytini tortadi → **kassa sekinlashadi**. Bu sizning "ishlashga ta'sir qilmaslik" talabingizni buzadi.

➡️ **Tanlangan yo'l:** fayl diskda (persistent volume), DB'da faqat **qisqa `ImageUrl` string**. POS grid yengil qoladi; `cached_network_image` faqat **ko'rinadigan** kartalar rasmini lazy yuklaydi va keshlaydi.

### 2.2. 🔴 Kritik: Docker volume yo'q

[docker-compose.yml](../docker-compose.yml) da API uchun `wwwroot` volume mount **yo'q**. Deploy har safar `--no-cache rebuild` qiladi → fayllar **yo'qoladi**. Shuning uchun persistent named volume — **0-bosqich, majburiy**.

---

## 3. Arxitektura

```
ADMIN (yuklash)                          SAVDO (ko'rsatish)
┌──────────────┐  POST /{id}/image   ┌──────────────────┐  GET /uploads/...   ┌────────────┐
│ Mahsulot     │ ──multipart──────▶  │ ProductsController │ ◀──cached_network── │ POS grid   │
│ formasi      │                     │ + IProductImage    │      _image         │ thumbnail  │
│(products.edit)│ ◀──ImageUrl──────  │   Storage          │                     │ +long-press│
└──────────────┘                     └────────┬───────────┘                     └────────────┘
                                              │ Product.ImageUrl (DB: qisqa string, nullable)
                                              ▼
                          wwwroot/uploads/products/{marketId}/{guid}.{ext}  ◀── named volume
```

**Saqlash sxemasi (multi-tenant):** `wwwroot/uploads/products/{marketId}/{productId}_{shortGuid}.{ext}`
Fayl nomi **server tomonda** generatsiya qilinadi (foydalanuvchi nomi ishlatilmaydi → path-traversal yo'q).

---

## 4. Backend vazifalari

### 4.0. Infratuzilma (🔴 birinchi, majburiy)
- [docker-compose.yml](../docker-compose.yml): `market-system-api` ga volume va global `volumes:` ga `product-images`:
  ```yaml
      volumes:
        - product-images:/app/wwwroot/uploads/products
  # ...
  volumes:
    product-images:
  ```
- `docker-compose.secure.yml` / `override` ga ham sinxronlash (agar API'ni qayta belgilasa).
- Konteyner foydalanuvchisi (`marketsystem`, [Dockerfile:41](../Dockerfile#L41)) volume'ga yoza olishini tekshirish.
- `appsettings.json` / `appsettings.Production.json`: `Storage:ProductImagesPath` (default `/app/wwwroot/uploads/products`).
- DB-backup oqimiga `product-images` volume'ini qo'shish.

### 4.1. Domain
[Product.cs](../MarketSystem.Domain/Entities/Product.cs):
```csharp
/// <summary>Rasmga nisbiy URL, masalan "/uploads/products/12/abc.webp". Null = rasmsiz.</summary>
public string? ImageUrl { get; set; }
```
Nullable, bitta ustun, eski mahsulotlar `null`.

### 4.2. Migration (schema-drift'dan saqlanish)
> ⚠️ [Schema drift naqsh](.): model ustunni biladi, migration yo'q → fresh DB'da 503.
- `dotnet ef migrations add AddProductImageUrl` (`Products.ImageUrl` `text` nullable).
- **Idempotent** (`IF NOT EXISTS`, `CompensateMissingColumns` patternidagidek).
- `AppDbContextModelSnapshot.cs` yangilanishini tekshirish. Indeks shart emas.

### 4.3. Storage abstraktsiyasi (yangi)
- Interfeys `MarketSystem.Application/Interfaces/IProductImageStorage.cs`:
  ```csharp
  Task<string> SaveAsync(int marketId, Guid productId, byte[] bytes, ImageKind kind, CancellationToken ct = default);
  Task DeleteAsync(string? imageUrl, CancellationToken ct = default);
  ```
- Implementatsiya `MarketSystem.Infrastructure/Storage/LocalProductImageStorage.cs` (papka yaratish, fayl yozish, nisbiy URL qaytarish, eski faylni o'chirish). DI'ga ulanadi.
- Interfeys orqali ajratilgani uchun kelajakda S3/MinIO'ga o'tish faqat yangi implementatsiya — controller/servis tegmaydi.

### 4.4. DTO
[ProductDTOs.cs](../MarketSystem.Application/DTOs/ProductDTOs.cs):
- `ProductDto` ga `[property: JsonPropertyName("imageUrl")] string? ImageUrl`.
- `Create/UpdateProductDto` ga **tegmaymiz** — rasm alohida endpoint orqali (avatar pattern, atomik).
- `MapToDto` da `ImageUrl` to'ldiriladi → POS grid avtomatik oladi (sales ProductDto'ni ishlatadi).

### 4.5. Service
[IProductService.cs](../MarketSystem.Application/Interfaces/IProductService.cs) + [ProductService.cs](../MarketSystem.Application/Services/ProductService.cs):
- `SetProductImageAsync(Guid productId, byte[] bytes, ImageKind kind, ct)`:
  1. Mahsulotni **joriy tenant filtri** bilan topadi (boshqa marketniki topilmaydi).
  2. Eski `ImageUrl` bo'lsa — `DeleteAsync` (yetim fayl qolmasin).
  3. Yangi faylni saqlaydi, `ImageUrl` + `UpdatedAt` yangilaydi, `SaveChanges`.
- `RemoveProductImageAsync(...)` — `ImageUrl=null` + fayl o'chirish.
- `DeleteProductAsync` (mavjud): hard-delete'da fayl ham o'chsin (soft-delete'da qoladi — §7.1).

### 4.6. Controller
[ProductsController.cs](../MarketSystem.API/Controllers/ProductsController.cs) — yangi endpointlar (avatar mantiqidan, faqat multipart):
```csharp
[HttpPost("{id}/image")]
[RequirePermission(PermissionKeys.ProductsEdit)]
[RequestSizeLimit(5 * 1024 * 1024)]            // DoS himoyasi
public async Task<ActionResult<ProductDto>> SetImage(Guid id, CancellationToken ct)

[HttpDelete("{id}/image")]
[RequirePermission(PermissionKeys.ProductsEdit)]
public async Task<IActionResult> RemoveImage(Guid id, CancellationToken ct)
```
Mantiq: multipart tekshiruvi → hajm (>5MB → 400) → `ImageContentValidator.Detect` (`Unknown` → 400) → servis → `null` → 404 → audit.
- Audit: `LogActionAsync(AuditEntityTypes.Product, id, AuditActions.ProductImageUpdate, ..., new { imageSet = true })` — **base64/baytlar hech qachon log qilinmaydi** (avatar [UsersController.cs:253](../MarketSystem.API/Controllers/UsersController.cs#L253)).
- `AuditActions.ProductImageUpdate` ni [AuditEvents.cs](../MarketSystem.Domain/Constants/AuditEvents.cs) ga qo'shish.

### 4.7. Static serving (yengillik)
- Fayl nomi unikal (guid) → uzoq `Cache-Control: max-age` xavfsiz. `uploads/` ga cache header qo'shish — trafikni kamaytiradi, qayta yuklamaydi.

---

## 5. Flutter — Admin (yuklash)

### 5.1. Model
[product_model.dart](../MarketSystem.Client/lib/features/products/data/models/product_model.dart) + entity:
- `imageUrl` (String?) maydon, `fromJson`/`toJson` da `imageUrl`.
- To'liq URL helperi: `ApiConstants.baseUrl + imageUrl` (server nisbiy beradi).

### 5.2. Service
[product_service.dart](../MarketSystem.Client/lib/data/services/product_service.dart):
- `uploadProductImage(productId, bytes, filename)` → `POST {products}/{id}/image` (`MultipartFile`, avatar `uploadProfileImage` patterni).
- `removeProductImage(productId)` → `DELETE {products}/{id}/image`.

### 5.3. Picker (admin forma)
- [admin_product_form_screen.dart](../MarketSystem.Client/lib/features/admin_products/screens/admin_product_form_screen.dart) ga rasm bo'limi: qo'shish / almashtirish / o'chirish.
- `profile_image_picker.dart` UX'ini qayta ishlatish (bottom-sheet Kamera/Galereya, `imageQuality: 50`, `maxWidth/Height: 1024`) — yuklashdan oldin **downscale**.

---

## 6. Flutter — Savdo (ko'rsatish)

### 6.1. Karta thumbnail
[continue_sale_product_card.dart](../MarketSystem.Client/lib/features/sales/presentation/widgets/continue_sale_product_card.dart):
- Karta tepasiga kichik **thumbnail** (`CachedNetworkImage`, `memCacheWidth ~120`), `imageUrl` bo'lsa.
- Rasmsiz bo'lsa — joriy ko'rinish (placeholder ikonka). **Layout buzilmasin** (`childAspectRatio: 1.45` ga moslash yoki kichik leading thumbnail).
- `errorWidget` → buzilgan URL UI ni sindirmaydi.
- **Ishlash:** faqat ko'rinadigan kartalar yuklanadi (GridView lazy), kesh saqlanadi → grid scroll silliq qoladi.

### 6.2. Long-press preview
[continue_sale_screen.dart:637](../MarketSystem.Client/lib/features/sales/presentation/screens/continue_sale_screen.dart#L637):
- `ContinueSaleProductCard` ga `onLongPress` qo'shish → kattalashtirilgan rasm dialog (`showDialog`, nom + narx + katta `CachedNetworkImage`).
- Oddiy `onTap` **o'zgarmaydi** (`_addToCart`).
- Rasmi yo'q tovarda long-press — yo ishlamaydi, yo "Rasm yo'q" ko'rsatadi (kichik qaror, MVP'da ishlamasin).

### 6.3. Lokalizatsiya
- `app_uz.arb` / `app_ru.arb`: "Rasm qo'shish", "Rasmni o'chirish", "Rasm yo'q", "Rasm hajmi 5MB dan oshmasligi kerak".

---

## 7. Ochiq mayda qarorlar
1. **Soft-delete:** rasm fayli qolsin (tiklanish uchun), faqat hard-delete'da o'chsin.
2. **Long-press rasmsiz tovarda:** MVP'da hech narsa qilmaydi (yoki "Rasm yo'q" toast).
3. **WebP konvert / thumbnail server tomonda:** MVP'da **yo'q** — klient downscale + `memCacheWidth` yetarli.
4. **Bir nechta rasm:** hozir **bitta**. Galereya kerak bo'lsa kelajakda alohida `ProductImage` jadvali.

---

## 8. Xavfsizlik checklist

| # | Talab | Qanday |
|---|---|---|
| S1 | Magic-byte | `ImageContentValidator.Detect` (renamed `.exe.png` rad) |
| S2 | Hajm limiti | `RequestSizeLimit` + `Length > 5MB` (DoS) |
| S3 | Server fayl nomi | Foydalanuvchi nomi ishlatilmaydi → path-traversal yo'q |
| S4 | Multi-tenant | Servis joriy tenant filtri; fayl `{marketId}/` ostida |
| S5 | RBAC | `products.edit` (upload/delete); ko'rsatish `products.access` orqali (mavjud) |
| S6 | Audit | Faqat `imageSet` flag; **hech qachon baytlar** |
| S7 | Yetim fayl yo'q | Almashtirish/o'chirishda `DeleteAsync` |
| S8 | Statik fayl | `uploads/` bajariladigan emas; to'g'ri MIME |
| S9 | CSP | `img-src 'self'` (same-origin URL) — o'zgarmaydi |

---

## 9. Bosqichli reja

| # | Ish | Natija |
|---|---|---|
| **0** | 🔴 Volume + appsettings + idempotent migration | Deploy'da rasm yo'qolmaydi |
| **1** | `IProductImageStorage` + `LocalProductImageStorage` + DI | Saqlash qatlami |
| **2** | Domain `ImageUrl` + DTO + `MapToDto` | Ma'lumot oqimi (POS grid avtomatik oladi) |
| **3** | Service metodlari + Controller endpointlari + audit | API tayyor |
| **4** | Backend testlar (tenant, magic-byte, hajm, RBAC, migration) | Regressiyadan himoya |
| **5** | Klient: model + service + admin forma picker | Yuklash ishlaydi |
| **6** | Klient: POS karta thumbnail + long-press preview + placeholder | Savdoda ko'rinadi |
| **7** | E2E + deploy (volume) + `--no-cache` dan keyin rasm ochilishini tekshirish | Productionda barqaror |

---

## 10. Qabul mezonlari (Definition of Done)

**Backend:**
- ✅ Boshqa market mahsulotiga rasm yuklab bo'lmaydi (multi-tenant isolation testi).
- ✅ Non-image / renamed fayl → 400; 5MB+ → 400/413; `products.edit`siz → 403.
- ✅ Almashtirishda eski fayl o'chadi (yetim yo'q).
- ✅ `ProductDto.imageUrl` to'g'ri; rasmsiz mahsulot `null`.
- ✅ Migration fresh DB'da xatosiz.

**Klient / Ishlash:**
- ✅ POS grid scroll **sekinlashmaydi** (rasmsiz holatga nisbatan sezilarli farq yo'q) — lazy + cache.
- ✅ Rasmsiz tovar bugungidek ko'rinadi (placeholder, crash yo'q).
- ✅ Long-press → katta preview; oddiy tap → savatga (o'zgarmagan).
- ✅ Buzilgan URL → errorWidget.

**Yakuniy:** deploy `--no-cache` dan keyin avval yuklangan rasm hamon ochiladi; mavjud savdo/mahsulot oqimlari o'zgarishsiz ishlaydi.

---

## 11. Risklar

| Risk | Ta'sir | Yumshatish |
|---|---|---|
| Volume unutilsa | Rasmlar deploy'da yo'qoladi | 0-bosqich birinchi; DoD `--no-cache` testi |
| base64-in-DB ga sirg'alish | POS sekinlashadi | TZ fayl-saqlashni aniq belgilaydi |
| Schema drift | Fresh DB'da 503 | Idempotent migration + snapshot |
| Yetim fayllar | Disk to'ladi | `DeleteAsync` + (kelajak) tozalash job |
| Grid layout buzilishi | UX | Rasmsiz holat default; thumbnail opsional, aspect-ratio moslash |

---

*Qamrov: rasm — opsional, admin formada yuklanadi, faqat POS grid'ida thumbnail + long-press preview sifatida ko'rsatiladi. Fayl-saqlash + persistent volume yondashuvi mavjud savdo ishlashiga ta'sir qilmaydi.*

---

## 12. Implementatsiya xulosasi (nima qilindi)

### Backend
- **Domain:** [Product.cs](../MarketSystem.Domain/Entities/Product.cs) — nullable `ImageUrl` ustuni.
- **Migration:** [20260605120000_AddProductImageUrl.cs](../MarketSystem.Infrastructure/Migrations/20260605120000_AddProductImageUrl.cs) — idempotent (`ADD COLUMN IF NOT EXISTS`), startup'da `MigrateAsync()` avtomatik qo'llaydi. Snapshot yangilandi.
- **Storage:** [IProductImageStorage.cs](../MarketSystem.Application/Interfaces/IProductImageStorage.cs) (Application) + [LocalProductImageStorage.cs](../MarketSystem.API/Storage/LocalProductImageStorage.cs) (API). Path-traversal himoyasi, server-generatsiya qilingan fayl nomi.
- **DTO/Service:** `ProductDto.imageUrl`; `SetProductImageAsync` / `RemoveProductImageAsync` (tenant filtri, eski faylni o'chirish).
- **Controller:** [ProductsController.cs](../MarketSystem.API/Controllers/ProductsController.cs) — `POST/DELETE /Products/{Set|Remove}Image/{id}/image` (`products.edit`), magic-byte + 5MB + audit (faqat flag).
- **Testlar:** [ProductServiceTests.cs](../MarketSystem.IntegrationTests/Integration/ProductServiceTests.cs) — 4 yangi test (set/replace/tenant/remove). **Jami 240/240 yashil.**

### Asosiy arxitektura qarori — rasm `/api/uploads/...` ostida
Rasm URL'lari `/api/uploads/products/...` ko'rinishida. Sabab: host nginx allaqachon `/api/` ni API konteyneriga proxy qiladi, shuning uchun **nginx konfiguratsiyasiga umuman tegmadik** (host nginx qo'lda yangilanadi — buni oldini oldik). [Program.cs](../MarketSystem.API/Program.cs) da `StaticFileOptions(RequestPath="/api/uploads")` + 30 kunlik immutable cache.

### 🔴 Ikki kritik infratuzilma tuzatuvi
1. **Volume:** [docker-compose.yml](../docker-compose.yml) + [docker-compose.secure.yml](../docker-compose.secure.yml) — `product-images` named volume `/app/wwwroot/uploads/products` ga mount. `--no-cache` rebuild'da rasm yo'qolmaydi.
2. **Volume ruxsati:** [Dockerfile](../Dockerfile) — mount nuqtasi `marketsystem` (UID 1001) egaligida oldindan yaratiladi. Busiz named volume root-egaligida bo'lib, non-root jarayon yoza olmay, har upload `EACCES` bilan yiqilardi.

### Klient (Flutter)
- **URL helper + service:** [api_constants.dart](../MarketSystem.Client/lib/core/constants/api_constants.dart) `productImageUrl()` (origin'dan absolute URL); [product_service.dart](../MarketSystem.Client/lib/data/services/product_service.dart) `uploadProductImage` / `removeProductImage` (base64-JSON, avatar transporti).
- **POS ko'rsatish:** [product_image_view.dart](../MarketSystem.Client/lib/features/sales/presentation/widgets/product_image_view.dart) (`ProductThumb` + `showProductImagePreview`); [sale_body.dart](../MarketSystem.Client/lib/features/sales/presentation/widgets/sale_body.dart) (`_ProductTile`) va [continue_sale_product_card.dart](../MarketSystem.Client/lib/features/sales/presentation/widgets/continue_sale_product_card.dart) — shartli thumbnail + long-press preview. Rasmsiz tile o'zgarmaydi.
- **Admin yuklash:** [admin_product_image_section.dart](../MarketSystem.Client/lib/features/admin_products/screens/widgets/admin_product_image_section.dart) — faqat tahrirlashda. `flutter analyze`: 0 muammo.

### Transport eslatmasi
Avatar singari **base64-JSON** ishlatildi (multipart EMAS), chunki klient `HttpService`'da multipart helper yo'q. Backend endpoint **ikkalasini** ham qabul qiladi (multipart + JSON). Yuklash kamdan-kam (admin), shuning uchun base64 inflyatsiyasi ahamiyatsiz; ko'rsatish esa URL orqali (yengil).

---

## 13. Deploy cheklisti

0. 🔴 **Yangi fayllarni `git add` qiling** (`git status` da `??` bilan turganlar). Eng muhimi — **migration fayli** `20260605120000_AddProductImageUrl.cs`. Agar `git commit -am` bilan commit qilsangiz, untracked fayllar **tushib qoladi** → model ustunni biladi-yu, DB'da yo'q → schema-drift 503. `git add -A` hammasini oladi. Boshqa yangi fayllar: `MarketSystem.API/Storage/`, `IProductImageStorage.cs`, `product_image_view.dart`, `admin_product_image_section.dart`, `LocalProductImageStorageTests.cs`.
1. `master` ga merge → serverda `git pull`.
2. **`--no-cache` rebuild** (Dockerfile o'zgardi — volume ruxsat tuzatuvi yangi qatlam talab qiladi).
3. Konteyner ko'tarilganda migration avtomatik qo'llanadi (`Products.ImageUrl` qo'shiladi).
4. **Tekshirish:**
   - Admin → mahsulot tahrirlash → rasm qo'shish → 200, rasm ko'rinadi.
   - Savdo ekrani → o'sha mahsulot kartasida thumbnail; uzun bosish → katta preview.
   - `https://strotech.uz/api/uploads/products/...` to'g'ridan-to'g'ri ochiladimi (200).
   - **`--no-cache` qayta rebuild → avval yuklangan rasm hamon ochiladimi** (volume ishlayapti).
5. Backup oqimiga `product-images` volume'ini qo'shish (DB tiklanganda rasm yo'qolmasin).

> ⚠️ Eslatma: `docker-compose.secure.yml` ham yangilandi. Agar deploy boshqa compose faylidan foydalansa, volume + mount mavjudligini tekshiring.

---

## 14. Adversarial review tuzatishlari (2-pass)

Implementatsiyadan keyin ikki mustaqil agent (backend + klient) adversarial review qildi. Topilgan haqiqiy muammolar tuzatildi:

| # | Muammo | Tuzatish |
|---|---|---|
| R1 | **POS tile overflow xavfi** — tor savdo tile'larida (aspectRatio 1.45/1.05) leading thumbnail nomni surib vertikal overflow keltirishi mumkin edi | Ikkala karta **Stack overlay** ga o'tkazildi — `Positioned` thumbnail Column balandligiga ta'sir qilmaydi (overflow strukturaviy imkonsiz); nom `hasImage` da o'ng padding oladi |
| R2 | **Path-traversal prefix-bypass** — `DeleteAsync` da `StartsWith(rootFull)` trailing-separator'siz, `products-evil` kabi qardosh papka o'tib ketardi (hozir exploit qilinmaydi, ImageUrl server-generatsiya) | Trailing separator qo'shildi; **regression test** (`LocalProductImageStorageTests`) yozildi |
| R3 | **Web-debug cross-origin** — klient boshqa portda, `/api/uploads` static javobida CORS header yo'q → thumbnail placeholder'ga tushardi | Static javobga `Access-Control-Allow-Origin: *` (rasm ochiq/sensitiv emas; prod same-origin → zararsiz) |
| R4 | **base64 boundary** — 5MB raw → ~6.7MB base64, RequestSizeLimit 7MB chegaraga yaqin edi | 8MB ga ko'tarildi (aniq "5MB" xabari beruvchi ichki tekshiruvga yetib boradi) |

**Verifikatsiya:** backend 244/244 test yashil (4 yangi storage testi), `flutter analyze` 0 muammo, solution build toza.

Review tasdiqlagan toza joylar (muammo yo'q): multi-tenant izolyatsiya, static yo'l mapping, magic-byte ikkala (multipart+JSON) yo'lda, tracked-entity persist, save tartibi (yetim fayl yo'q), audit gigienasi (bayt log qilinmaydi), Docker volume+egalik, imageUrl uchidan-uchiga oqimi.
