using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Constants;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Authorization;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly IExcelService _excelService;
    private readonly ITashkentClock _clock;
    private readonly IProductImportService _importService;
    private readonly IAuditLogService _auditLogService;

    public ProductsController(
        IProductService productService,
        IExcelService excelService,
        ITashkentClock clock,
        IProductImportService importService,
        IAuditLogService auditLogService)
    {
        _productService = productService;
        _excelService = excelService;
        _clock = clock;
        _importService = importService;
        _auditLogService = auditLogService;
    }

    /// <summary>Cost price is visible to Owner and Admin only — a Seller must
    /// never see the shop's margin (SellerForbidden = data.costPrice). Mirrors
    /// the masking the Excel export already applies.</summary>
    private bool CanViewCost() =>
        User.FindFirst(ClaimTypes.Role)?.Value is "Owner" or "Admin";

    [HttpGet("{id}")]
    [RequirePermission(PermissionKeys.ProductsAccess)]
    public async Task<ActionResult<ProductDto>> GetProduct(Guid id, CancellationToken ct = default)
    {
        var product = await _productService.GetProductByIdAsync(id, CanViewCost(), ct);
        if (product is null)
            return NotFound();

        return Ok(product);
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.ProductsAccess)]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetAllProducts(CancellationToken ct = default)
    {
        var products = await _productService.GetAllProductsAsync(CanViewCost(), ct);
        // X-Total-Count: -1 → mijoz ma'lumotlar to'liq emasligini biladi
        var list = products.ToList();
        if (list.Count >= 5000)
            Response.Headers["X-Total-Count"] = "-1";
        return Ok(list);
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.ProductsAccess)]
    public async Task<ActionResult<PagedResult<ProductDto>>> GetAllProductsPaged(
        [FromQuery] int page = 1,
        [FromQuery] int size = 50,
        CancellationToken ct = default)
    {
        var result = await _productService.GetAllProductsPagedAsync(page, size, CanViewCost(), ct);
        return Ok(result);
    }

    [HttpGet("low-stock")]
    [RequirePermission(PermissionKeys.ProductsAccess)]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetLowStockProducts(CancellationToken ct = default)
    {
        var products = await _productService.GetLowStockProductsAsync(CanViewCost(), ct);
        return Ok(products);
    }

    /// <summary>
    /// Barcha o'lchov birliklarini olish (dona, kg, m)
    /// </summary>
    [HttpGet("units")]
    [AllowAnonymous]
    public ActionResult<List<UnitInfo>> GetUnits()
    {
        return Ok(UnitConstants.AllUnits);
    }

    [HttpPost]
    [RequirePermission(PermissionKeys.ProductsCreate)]
    public async Task<ActionResult<ProductDto>> CreateProduct([FromBody] CreateProductDto request, CancellationToken ct = default)
    {
        var sellerId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var sellerGuid = !string.IsNullOrEmpty(sellerId) && Guid.TryParse(sellerId, out var parsed)
            ? parsed : (Guid?)null;

        try
        {
            var product = await _productService.CreateProductAsync(request, sellerGuid);
            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
        }
        catch (Exception ex) when (ex is InvalidOperationException || ex is ArgumentException)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id}")]
    [RequirePermission(PermissionKeys.ProductsEdit)]
    public async Task<ActionResult<ProductDto>> UpdateProduct(Guid id, [FromBody] UpdateProductDto request, CancellationToken ct = default)
    {
        if (id != request.Id)
            return BadRequest("ID mismatch");

        // On-hand stock may only be hand-corrected by Owner/SuperAdmin. For any
        // other caller (even an Admin with products.edit) request.Quantity is
        // ignored server-side; stock otherwise moves only through zakup/sales.
        var canEditStock = User.FindFirst(ClaimTypes.Role)?.Value is "Owner" or "SuperAdmin";
        // Kelgan (tannarx) narxini forma orqali faqat cost-ko'ruvchi (Owner/Admin)
        // o'zgartira oladi — masking tufayli boshqa rol 0 yuborib eski narxni
        // yo'qotib qo'ymasin.
        var canEditCost = CanViewCost();

        // Capture the pre-edit quantity only on an actual override so the audit
        // row can record old→new. Rare Owner path — the extra read is fine.
        decimal? oldQuantity = null;
        if (canEditStock && request.Quantity.HasValue)
            oldQuantity = (await _productService.GetProductByIdAsync(id, canViewCost: true, ct))?.Quantity;

        try
        {
            var product = await _productService.UpdateProductAsync(request, canEditStock, canEditCost, ct);
            if (product is null)
                return NotFound();

            // Manual stock correction is fraud-sensitive — journal it (old→new)
            // whenever the figure actually changed.
            if (oldQuantity.HasValue && oldQuantity.Value != product.Quantity)
            {
                await _auditLogService.LogActionAsync(
                    AuditEntityTypes.Product, id, AuditActions.StockAdjust, CurrentUserId(),
                    new { from = oldQuantity.Value, to = product.Quantity });
            }

            return Ok(product);
        }
        catch (Exception ex) when (ex is InvalidOperationException || ex is ArgumentException)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpDelete("{id}")]
    [RequirePermission(PermissionKeys.ProductsDelete)]
    public async Task<IActionResult> DeleteProduct(Guid id, CancellationToken ct = default)
    {
        var result = await _productService.DeleteProductAsync(id);
        if (!result)
            return NotFound();

        return NoContent();
    }

    /// <summary>
    /// Exports all products as an .xlsx workbook. Column headers (and the
    /// "Ha"/"Yo'q" boolean labels) come back in the caller's language —
    /// pass `lang=ru` for Russian, anything else (or omit) yields Uzbek.
    /// Returns every product the caller can see — same paging-disabled
    /// fetch used by the in-app list. No filtering server-side; the user
    /// can sort / filter in Excel if needed.
    /// </summary>
    [HttpGet("export")]
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.ProductsExport)]
    public async Task<IActionResult> ExportProductsToExcel(
        [FromQuery] string lang = "uz",
        CancellationToken ct = default)
    {
        var products = await _productService.GetAllProductsAsync();
        var isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        var role = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
        var canSeeCost = role is "Owner" or "Admin";

        // Anonymous types pick up the field names as Excel column headers.
        // We need two separate shapes for uz vs ru because anonymous-type
        // member names are compile-time fixed.
        object exportData = isRu
            ? products.Select(p => new
            {
                ID = p.Id.ToString(),
                Название = p.Name,
                Категория = p.CategoryName ?? "",
                Цена_закупки = canSeeCost ? p.CostPrice.ToString("G29") : "—",
                Цена_продажи = p.SalePrice,
                Минимальная_цена = p.MinSalePrice,
                Количество = p.Quantity,
                Ед_изм = p.UnitName,
                Минимальный_остаток = p.MinThreshold,
                Заканчивается = p.IsLowStock ? "Да" : "Нет",
                Временный = p.IsTemporary ? "Да" : "Нет"
            }).Cast<object>()
            : products.Select(p => new
            {
                ID = p.Id.ToString(),
                Nomi = p.Name,
                Kategoriya = p.CategoryName ?? "",
                Xarid_narxi = canSeeCost ? p.CostPrice.ToString("G29") : "—",
                Sotuv_narxi = p.SalePrice,
                Minimal_narx = p.MinSalePrice,
                Miqdor = p.Quantity,
                Birlik = p.UnitName,
                Minimal_chegara = p.MinThreshold,
                Kam_qoldi = p.IsLowStock ? "Ha" : "Yo'q",
                Vaqtinchalik = p.IsTemporary ? "Ha" : "Yo'q"
            }).Cast<object>();

        var sheetName = isRu ? "Товары" : "Mahsulotlar";
        var fileContent = _excelService.GenerateExcel((dynamic)exportData, sheetName);

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"{sheetName}_{_clock.NowLocal:yyyyMMdd_HHmmss}.xlsx"
        );
    }

    /// <summary>
    /// Mahsulotga rasm biriktiradi yoki mavjudini almashtiradi. Ikki formatni
    /// qabul qiladi: multipart/form-data (`image` fayl) yoki JSON
    /// ({ "image": "data:image/...;base64,..." }). Faqat savdo ekranida
    /// ko'rsatish uchun. Magic-byte va hajm (max 5MB) tekshiruvidan o'tadi.
    /// </summary>
    [HttpPost("{id}/image")]
    [RequirePermission(PermissionKeys.ProductsEdit)]
    // 5MB raw rasm base64'da ~6.7MB bo'ladi; 8MB ceiling boundary'da 413 emas,
    // aniq "5MB" xabarini beruvchi ichki tekshiruvga yetib borishni kafolatlaydi.
    [RequestSizeLimit(8 * 1024 * 1024)]
    public async Task<ActionResult<ProductDto>> SetImage(Guid id, CancellationToken ct = default)
    {
        // Ikki xil yuborishni qo'llab-quvvatlaymiz (avatar endpoint'i kabi):
        //  1) multipart/form-data — `image` fayl;
        //  2) JSON — { "image": "data:image/...;base64,..." }.
        // Mijozning HttpService base64-JSON yo'lidan foydalanadi.
        byte[] imageBytes;

        if (Request.HasFormContentType && Request.Form.Files.Count > 0)
        {
            var image = Request.Form.Files[0];
            if (image.Length == 0)
                return BadRequest("Rasm fayli bo'sh.");
            if (image.Length > 5 * 1024 * 1024)
                return BadRequest("Rasm hajmi juda katta. Maksimum rasm hajmi 5MB.");

            using var memoryStream = new MemoryStream();
            await image.CopyToAsync(memoryStream, ct);
            imageBytes = memoryStream.ToArray();
        }
        else
        {
            SetProductImageRequest? body;
            try
            {
                body = await Request.ReadFromJsonAsync<SetProductImageRequest>(ct);
            }
            catch
            {
                return BadRequest("So'rov noto'g'ri formatda.");
            }

            var dataUrl = body?.Image;
            if (string.IsNullOrWhiteSpace(dataUrl))
                return BadRequest("Rasm yuborilmadi.");

            // "data:image/png;base64,XXXX" yoki to'g'ridan-to'g'ri base64.
            var base64 = dataUrl.Contains(',') ? dataUrl[(dataUrl.IndexOf(',') + 1)..] : dataUrl;
            try
            {
                imageBytes = Convert.FromBase64String(base64);
            }
            catch (FormatException)
            {
                return BadRequest("Rasm ma'lumoti noto'g'ri (base64 emas).");
            }

            if (imageBytes.Length == 0)
                return BadRequest("Rasm fayli bo'sh.");
            if (imageBytes.Length > 5 * 1024 * 1024)
                return BadRequest("Rasm hajmi juda katta. Maksimum rasm hajmi 5MB.");
        }

        // Baytlarga ISHONISHDAN OLDIN magic-byte'larni tekshiramiz.
        var kind = MarketSystem.API.Validation.ImageContentValidator.Detect(imageBytes);
        if (kind == MarketSystem.API.Validation.ImageKind.Unknown)
            return BadRequest("Fayl tasvir emas yoki qo'llab-quvvatlanmaydigan formatda (JPEG/PNG/GIF/WebP qabul qilinadi).");

        var extension = MarketSystem.API.Validation.ImageContentValidator.ToExtension(kind);

        var product = await _productService.SetProductImageAsync(id, imageBytes, extension, ct);
        if (product is null)
            return NotFound();

        // Audit — faqat flag, hech qachon rasm baytlari/URL emas.
        await _auditLogService.LogActionAsync(
            AuditEntityTypes.Product, id, AuditActions.ProductImageUpdate, CurrentUserId(),
            new { imageSet = true });

        return Ok(product);
    }

    /// <summary>Mahsulot rasmini o'chiradi.</summary>
    [HttpDelete("{id}/image")]
    [RequirePermission(PermissionKeys.ProductsEdit)]
    public async Task<ActionResult<ProductDto>> RemoveImage(Guid id, CancellationToken ct = default)
    {
        var product = await _productService.RemoveProductImageAsync(id, ct);
        if (product is null)
            return NotFound();

        await _auditLogService.LogActionAsync(
            AuditEntityTypes.Product, id, AuditActions.ProductImageUpdate, CurrentUserId(),
            new { imageSet = false });

        return Ok(product);
    }

    /// <summary>The authenticated caller's user id from the JWT (Guid.Empty if absent).</summary>
    private Guid CurrentUserId()
    {
        var raw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(raw, out var id) ? id : Guid.Empty;
    }

    /// <summary>
    /// Dry-run: Excel qatorlarini tahlil qiladi, bazaga yozmaydi.
    /// Flutter bu natijani foydalanuvchiga ko'rsatadi (xatolar, ogohlantirishlar, kategoriya takliflari).
    /// </summary>
    [HttpPost("import/preview")]
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.ProductsImport)]
    public async Task<ActionResult<ImportPreviewResultDto>> ImportPreview(
        [FromBody] List<ImportProductRowDto> rows,
        CancellationToken ct = default)
    {
        if (rows is null or { Count: 0 })
            return BadRequest(new { message = "Kamida bitta qator yuborilishi kerak." });

        if (rows.Count > 1000)
            return BadRequest(new { message = "Bir marta maksimum 1000 ta qator import qilish mumkin." });

        var result = await _importService.PreviewAsync(rows, ct);
        return Ok(result);
    }

    /// <summary>
    /// Haqiqiy import: faqat Error bo'lmagan qatorlarni saqlaydi.
    /// CategoryOverrides — foydalanuvchi kategoriya moslamalarini tasdiqlaydi.
    /// </summary>
    [HttpPost("import/confirm")]
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.ProductsImport)]
    public async Task<ActionResult<ImportResultDto>> ImportConfirm(
        [FromBody] ImportConfirmDto request,
        CancellationToken ct = default)
    {
        if (request.Rows is null or { Count: 0 })
            return BadRequest(new { message = "Kamida bitta qator yuborilishi kerak." });

        if (request.Rows.Count > 1000)
            return BadRequest(new { message = "Bir marta maksimum 1000 ta qator import qilish mumkin." });

        var result = await _importService.ConfirmAsync(request, ct);
        return Ok(result);
    }

}
