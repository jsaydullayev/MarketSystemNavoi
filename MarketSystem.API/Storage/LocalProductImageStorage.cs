using MarketSystem.Application.Interfaces;

namespace MarketSystem.API.Storage;

/// <summary>
/// <see cref="IProductImageStorage"/> ning lokal-disk implementatsiyasi.
/// Fayllarni wwwroot/uploads/products/{marketId}/ ostiga yozadi va
/// server-nisbiy URL qaytaradi. Productionda bu papka named Docker volume'ga
/// mount qilinadi (docker-compose.yml: product-images) — shuning uchun
/// `--no-cache` rebuild'lar fayllarni o'chirmaydi.
/// </summary>
public sealed class LocalProductImageStorage : IProductImageStorage
{
    // Rasm URL'lari "/api/uploads/products/..." ostida beriladi — shunda mavjud
    // nginx "/api/" proxy'si (host → API konteyner) ularni hech qanday yangi
    // location bloki qo'shmasdan yetkazadi. Fizik fayllar wwwroot/uploads/products
    // da, Program.cs StaticFileOptions RequestPath="/api/uploads" bilan ulanadi.
    private const string UrlPrefix = "/api/uploads/products";

    private readonly string _physicalRoot;
    private readonly ILogger<LocalProductImageStorage> _logger;

    public LocalProductImageStorage(IWebHostEnvironment env, IConfiguration config, ILogger<LocalProductImageStorage> logger)
    {
        _logger = logger;

        // Konfiguratsiya override'i bo'lsa o'shani, aks holda wwwroot ostidagi
        // standart yo'lni ishlatamiz. WebRootPath ba'zan null bo'ladi (wwwroot
        // hali yaratilmagan) — ContentRootPath'dan tiklaymiz.
        var configured = config["Storage:ProductImagesPath"];
        if (!string.IsNullOrWhiteSpace(configured))
        {
            _physicalRoot = configured;
        }
        else
        {
            var webRoot = env.WebRootPath;
            if (string.IsNullOrEmpty(webRoot))
                webRoot = Path.Combine(env.ContentRootPath, "wwwroot");
            _physicalRoot = Path.Combine(webRoot, "uploads", "products");
        }

        Directory.CreateDirectory(_physicalRoot);
    }

    public async Task<string> SaveAsync(int marketId, Guid productId, byte[] bytes, string extension, CancellationToken ct = default)
    {
        var ext = NormalizeExtension(extension);

        var marketDir = Path.Combine(_physicalRoot, marketId.ToString());
        Directory.CreateDirectory(marketDir);

        // Server tomonda generatsiya qilingan nom — foydalanuvchi nomidan
        // foydalanilmaydi (path-traversal yo'q). productId + qisqa guid bilan
        // unikallik (rasm almashtirilganda eski fayl bilan to'qnashmaydi va
        // brauzer keshini buzadi).
        var fileName = $"{productId:N}_{Guid.NewGuid():N}.{ext}";
        var physicalPath = Path.Combine(marketDir, fileName);

        await File.WriteAllBytesAsync(physicalPath, bytes, ct);

        // Forward-slash URL (Windows backslash'idan qat'i nazar).
        return $"{UrlPrefix}/{marketId}/{fileName}";
    }

    public Task DeleteAsync(string? imageUrl, CancellationToken ct = default)
    {
        if (string.IsNullOrWhiteSpace(imageUrl))
            return Task.CompletedTask;

        try
        {
            var physicalPath = ResolvePhysicalPath(imageUrl);
            if (physicalPath is not null && File.Exists(physicalPath))
                File.Delete(physicalPath);
        }
        catch (Exception ex)
        {
            // O'chirish best-effort — yetim fayl diskda qolsa ham asosiy
            // operatsiya (DB yangilanishi) buzilmasin.
            _logger.LogWarning(ex, "Mahsulot rasmini o'chirishda xatolik: {ImageUrl}", imageUrl);
        }

        return Task.CompletedTask;
    }

    /// <summary>
    /// Server-nisbiy URL'ni fizik yo'lga aylantiradi va natija saqlash
    /// ildizidan tashqariga chiqmasligini tekshiradi (path-traversal himoyasi).
    /// Mos kelmasa null.
    /// </summary>
    private string? ResolvePhysicalPath(string imageUrl)
    {
        var prefix = $"{UrlPrefix}/";
        if (!imageUrl.StartsWith(prefix, StringComparison.Ordinal))
            return null;

        var relative = imageUrl.Substring(prefix.Length).Replace('/', Path.DirectorySeparatorChar);
        var combined = Path.GetFullPath(Path.Combine(_physicalRoot, relative));

        // Trailing separator MUHIM: usiz prefiksni bo'lishadigan qardosh papka
        // (masalan ".../products-evil") StartsWith guard'idan o'tib ketardi.
        var rootFull = Path.GetFullPath(_physicalRoot);
        if (!rootFull.EndsWith(Path.DirectorySeparatorChar))
            rootFull += Path.DirectorySeparatorChar;

        if (!combined.StartsWith(rootFull, StringComparison.Ordinal))
            return null; // ../ bilan tashqariga yoki qardosh papkaga chiqishga urinish

        return combined;
    }

    private static string NormalizeExtension(string extension)
    {
        var ext = extension.Trim().TrimStart('.').ToLowerInvariant();
        return ext switch
        {
            "jpg" or "jpeg" => "jpg",
            "png" => "png",
            "gif" => "gif",
            "webp" => "webp",
            _ => "bin" // controller validatsiyadan o'tkazgan — bu yetib kelmasligi kerak
        };
    }
}
