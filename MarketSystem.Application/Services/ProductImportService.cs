using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public sealed class ProductImportService : IProductImportService
{
    private readonly IAppDbContext _db;
    private readonly ICurrentMarketService _market;
    private readonly ILogger<ProductImportService> _log;

    public ProductImportService(
        IAppDbContext db,
        ICurrentMarketService market,
        ILogger<ProductImportService> log)
    {
        _db = db;
        _market = market;
        _log = log;
    }

    // ── Preview ────────────────────────────────────────────────────────────

    public async Task<ImportPreviewResultDto> PreviewAsync(
        List<ImportProductRowDto> rows,
        CancellationToken ct = default)
    {
        var marketId = _market.GetCurrentMarketId();

        var existingNames = await _db.Products
            .Where(p => p.MarketId == marketId && !p.IsDeleted)
            .Select(p => p.Name.ToLower())
            .ToHashSetAsync(ct);

        var categories = await _db.ProductCategories
            .Where(c => c.MarketId == marketId && !c.IsDeleted && c.IsActive)
            .Select(c => new { c.Id, c.Name })
            .ToListAsync(ct);

        var results = new List<ImportRowResultDto>();
        var newCategoryNames = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var row in rows)
        {
            var errors = new List<string>();
            var warnings = new List<string>();

            // ── Nom tekshiruvi ─────────────────────────────────────────────
            var name = row.Name?.Trim();
            if (string.IsNullOrEmpty(name))
            {
                errors.Add("Tovar nomi bo'sh bo'lishi mumkin emas.");
                results.Add(ErrorRow(row, errors));
                continue;
            }
            if (name.Length > 200)
                errors.Add("Tovar nomi 200 belgidan oshmasligi kerak.");

            if (existingNames.Contains(name.ToLower()))
                errors.Add($"'{name}' nomli tovar allaqachon mavjud.");
            else
            {
                // Mavjud mahsulotlarga juda o'xshash nomni ogohlantirish
                // Length diff early-exit — Levenshtein'dan oldin tez filtr
                var similar = existingNames
                    .FirstOrDefault(e =>
                        Math.Abs(e.Length - name.Length) <= 2 &&
                        IsFuzzyMatch(name, e, maxDist: 2));
                if (similar is not null)
                    warnings.Add($"'{similar}' nomli tovar bilan juda o'xshash. Ikki marta tekshiring.");
            }

            // ── Narx tekshiruvi ────────────────────────────────────────────
            if (row.SalePrice is null or <= 0)
                errors.Add("Sotuv narxi majburiy va 0 dan katta bo'lishi kerak.");
            else if (row.MinSalePrice is not null && row.MinSalePrice > row.SalePrice)
                errors.Add("Minimal sotuv narxi sotuv narxidan katta bo'lishi mumkin emas.");

            // ── Kategoriya ─────────────────────────────────────────────────
            int? resolvedCategoryId = null;
            string? resolvedCategoryName = null;
            string? suggestedCategoryName = null;
            bool isNewCategory = false;

            if (!string.IsNullOrWhiteSpace(row.CategoryName))
            {
                if (row.CategoryName.Trim().Length > 100)
                    errors.Add("Kategoriya nomi 100 belgidan oshmasligi kerak.");

                var exact = categories.FirstOrDefault(
                    c => string.Equals(c.Name, row.CategoryName, StringComparison.OrdinalIgnoreCase));

                if (exact is not null)
                {
                    resolvedCategoryId = exact.Id;
                    resolvedCategoryName = exact.Name;
                }
                else
                {
                    // Fuzzy match
                    var fuzzy = categories
                        .Select(c => new { c.Id, c.Name, Dist = LevenshteinDistance(row.CategoryName.ToLower(), c.Name.ToLower()) })
                        .Where(x => x.Dist <= FuzzyThreshold(row.CategoryName))
                        .MinBy(x => x.Dist);

                    if (fuzzy is not null)
                    {
                        suggestedCategoryName = fuzzy.Name;
                        warnings.Add($"Kategoriya '{row.CategoryName}' topilmadi. '{fuzzy.Name}' nazarda tutilganmi?");
                    }
                    else
                    {
                        // Yangi kategoriya yaratiladi
                        isNewCategory = true;
                        newCategoryNames.Add(row.CategoryName.Trim());
                        warnings.Add($"'{row.CategoryName.Trim()}' yangi kategoriya sifatida yaratiladi.");
                    }
                }
            }

            // ── Unit va MinThreshold ───────────────────────────────────────
            var unit = ParseUnit(row.UnitName);
            var minThreshold = row.MinThreshold ?? 5m;
            var minSalePrice = row.MinSalePrice ?? row.SalePrice ?? 0m;

            var status = errors.Count > 0
                ? ImportRowStatus.Error
                : warnings.Count > 0
                    ? ImportRowStatus.Warning
                    : ImportRowStatus.Valid;

            results.Add(new ImportRowResultDto(
                RowNumber: row.RowNumber,
                InputName: row.Name,
                Status: status,
                Errors: errors,
                Warnings: warnings,
                ResolvedName: name,
                ResolvedSalePrice: row.SalePrice,
                ResolvedMinSalePrice: minSalePrice,
                ResolvedCategoryId: resolvedCategoryId,
                ResolvedCategoryName: resolvedCategoryName ?? row.CategoryName?.Trim(),
                SuggestedCategoryName: suggestedCategoryName,
                ResolvedUnit: (int)unit,
                ResolvedUnitName: UnitName(unit),
                ResolvedMinThreshold: minThreshold,
                IsNewCategory: isNewCategory
            ));
        }

        return new ImportPreviewResultDto(
            Rows: results,
            ValidCount: results.Count(r => r.Status == ImportRowStatus.Valid),
            WarningCount: results.Count(r => r.Status == ImportRowStatus.Warning),
            ErrorCount: results.Count(r => r.Status == ImportRowStatus.Error),
            NewCategories: newCategoryNames.ToList()
        );
    }

    // ── Confirm ────────────────────────────────────────────────────────────

    public async Task<ImportResultDto> ConfirmAsync(
        ImportConfirmDto request,
        CancellationToken ct = default)
    {
        var marketId = _market.GetCurrentMarketId();

        // Tranzaksiya ichida bajaramiz: kategoriyalar yoki mahsulotlar fail bo'lsa
        // ikkalasi ham rollback bo'ladi — orphaned kategoriyalar qolmaydi.
        await using var tx = await _db.Database.BeginTransactionAsync(ct);
        try
        {
            var result = await RunConfirmAsync(request, marketId, ct);
            await tx.CommitAsync(ct);
            return result;
        }
        catch (Exception ex)
        {
            await tx.RollbackAsync(ct);
            _log.LogError(ex, "Import rollback qilindi. MarketId={MarketId}, Rows={Count}",
                marketId, request.Rows.Count);
            throw;
        }
    }

    private async Task<ImportResultDto> RunConfirmAsync(
        ImportConfirmDto request,
        int marketId,
        CancellationToken ct)
    {
        var existingNames = await _db.Products
            .Where(p => p.MarketId == marketId && !p.IsDeleted)
            .Select(p => p.Name.ToLower())
            .ToHashSetAsync(ct);

        var categories = await _db.ProductCategories
            .Where(c => c.MarketId == marketId && !c.IsDeleted && c.IsActive)
            .ToListAsync(ct);

        var categoryCache = categories.ToDictionary(
            c => c.Name, c => c.Id, StringComparer.OrdinalIgnoreCase);

        var skippedNames = new List<string>();

        // ── 1-pass: barcha kerakli yangi kategoriya nomlarini yig'amiz ────────
        // Bir xil nom ikki marta yozilmasin (case-insensitive)
        var categoriesToCreate = new Dictionary<string, ProductCategory>(
            StringComparer.OrdinalIgnoreCase);

        foreach (var row in request.Rows)
        {
            var name = row.Name?.Trim();
            if (string.IsNullOrEmpty(name) || row.SalePrice is null or <= 0) continue;
            if (existingNames.Contains(name.ToLower())) continue;
            if (string.IsNullOrWhiteSpace(row.CategoryName)) continue;

            var key = row.CategoryName.Trim();
            if (key.Length > 100) continue;
            if (request.CategoryOverrides.ContainsKey(key)) continue;
            if (categoryCache.ContainsKey(key)) continue;

            // Fuzzy match bor — yangi kategoriya kerak emas
            var hasFuzzy = categories.Any(c =>
                Math.Abs(c.Name.Length - key.Length) <= FuzzyThreshold(key) &&
                LevenshteinDistance(key.ToLower(), c.Name.ToLower()) <= FuzzyThreshold(key));
            if (hasFuzzy) continue;

            if (!categoriesToCreate.ContainsKey(key))
                categoriesToCreate[key] = new ProductCategory
                {
                    Name = key,
                    MarketId = marketId,
                    IsActive = true,
                    IsDeleted = false,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                };
        }

        // ── Yangi kategoriyalarni bir batch da yaratamiz ───────────────────
        var newCategoriesCreated = 0;
        if (categoriesToCreate.Count > 0)
        {
            await _db.ProductCategories.AddRangeAsync(categoriesToCreate.Values, ct);
            await _db.SaveChangesAsync(ct);
            newCategoriesCreated = categoriesToCreate.Count;
            foreach (var cat in categoriesToCreate.Values)
            {
                categoryCache[cat.Name] = cat.Id;
                categories.Add(cat);
            }
        }

        // ── 2-pass: mahsulotlarni yaratamiz ───────────────────────────────
        var productsToAdd = new List<Product>();

        foreach (var row in request.Rows)
        {
            var name = row.Name?.Trim();
            if (string.IsNullOrEmpty(name) || row.SalePrice is null or <= 0)
            {
                if (name is not null) skippedNames.Add(name);
                continue;
            }
            if (existingNames.Contains(name.ToLower()))
            {
                skippedNames.Add(name);
                continue;
            }

            int? categoryId = null;
            if (!string.IsNullOrWhiteSpace(row.CategoryName))
            {
                var key = row.CategoryName.Trim();

                if (request.CategoryOverrides.TryGetValue(key, out var overrideId))
                    categoryId = overrideId;
                else if (categoryCache.TryGetValue(key, out var cachedId))
                    categoryId = cachedId;
                else
                {
                    var fuzzy = categories
                        .Where(c => Math.Abs(c.Name.Length - key.Length) <= FuzzyThreshold(key))
                        .Select(c => new { c.Id, Dist = LevenshteinDistance(key.ToLower(), c.Name.ToLower()) })
                        .Where(x => x.Dist <= FuzzyThreshold(key))
                        .MinBy(x => x.Dist);
                    categoryId = fuzzy?.Id;
                }
            }

            var salePrice = row.SalePrice!.Value;
            var minSalePrice = row.MinSalePrice is > 0 and var msp && msp <= salePrice
                ? msp
                : salePrice;

            productsToAdd.Add(new Product
            {
                Id = Guid.NewGuid(),
                Name = name,
                MarketId = marketId,
                CostPrice = 0,
                SalePrice = salePrice,
                MinSalePrice = minSalePrice,
                Quantity = 0,
                MinThreshold = row.MinThreshold ?? 5m,
                Unit = ParseUnit(row.UnitName),
                CategoryId = categoryId,
                IsTemporary = false,
            });

            existingNames.Add(name.ToLower());
        }

        if (productsToAdd.Count > 0)
        {
            await _db.Products.AddRangeAsync(productsToAdd, ct);
            await _db.SaveChangesAsync(ct);
        }

        _log.LogInformation(
            "Import: {Imported} mahsulot saqlandi, {Skipped} o'tkazib yuborildi, {NewCats} yangi kategoriya yaratildi.",
            productsToAdd.Count, skippedNames.Count, newCategoriesCreated);

        return new ImportResultDto(
            ImportedCount: productsToAdd.Count,
            SkippedCount: skippedNames.Count,
            NewCategoriesCreated: newCategoriesCreated,
            SkippedNames: skippedNames
        );
    }

    // ── Yordamchi metodlar ─────────────────────────────────────────────────

    private static ImportRowResultDto ErrorRow(ImportProductRowDto row, List<string> errors) =>
        new(row.RowNumber, row.Name, ImportRowStatus.Error, errors, [],
            null, null, null, null, null, null, (int)UnitType.Piece, "dona", 5m, false);

    private static UnitType ParseUnit(string? raw) => raw?.Trim().ToLower() switch
    {
        "kg" or "kilogram" or "kilogramm" or "кг" => UnitType.Kilogram,
        "m" or "metr" or "meter" or "метр"        => UnitType.Meter,
        _                                           => UnitType.Piece,
    };

    private static string UnitName(UnitType u) => u switch
    {
        UnitType.Kilogram => "kg",
        UnitType.Meter    => "m",
        _                 => "dona",
    };

    // Levenshtein masofasi — DP, O(n*m)
    private static int LevenshteinDistance(string s, string t)
    {
        if (s == t) return 0;
        if (s.Length == 0) return t.Length;
        if (t.Length == 0) return s.Length;

        var d = new int[s.Length + 1, t.Length + 1];
        for (var i = 0; i <= s.Length; i++) d[i, 0] = i;
        for (var j = 0; j <= t.Length; j++) d[0, j] = j;

        for (var i = 1; i <= s.Length; i++)
        for (var j = 1; j <= t.Length; j++)
        {
            var cost = s[i - 1] == t[j - 1] ? 0 : 1;
            d[i, j] = Math.Min(
                Math.Min(d[i - 1, j] + 1, d[i, j - 1] + 1),
                d[i - 1, j - 1] + cost);
        }
        return d[s.Length, t.Length];
    }

    // Qisqa so'zlarda juda ko'p soxta mosliklar chiqmasligi uchun adaptiv chegara
    private static int FuzzyThreshold(string s) => s.Length switch
    {
        <= 3 => 0, // Qisqa so'z — faqat aniq mos
        <= 5 => 1, // O'rta — 1 ta xato
        _    => 2, // Uzun — 2 ta xato
    };

    private static bool IsFuzzyMatch(string a, string b, int maxDist) =>
        LevenshteinDistance(a.ToLower(), b.ToLower()) <= maxDist;
}
