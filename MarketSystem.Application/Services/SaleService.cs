using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public partial class SaleService : ISaleService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditLogService _auditLogService;
    private readonly IAppDbContext _context;
    private readonly ILogger<SaleService> _logger;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly ICustomerService _customerService;

    public SaleService(IUnitOfWork unitOfWork, IAuditLogService auditLogService, IAppDbContext context, ILogger<SaleService> logger, ICurrentMarketService currentMarketService, ICustomerService customerService)
    {
        _unitOfWork = unitOfWork;
        _auditLogService = auditLogService;
        _context = context;
        _logger = logger;
        _currentMarketService = currentMarketService;
        _customerService = customerService;
    }

    public async Task<SaleDto?> GetSaleByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.Id == id && s.MarketId == marketId,
            cancellationToken);

        var sale = sales.FirstOrDefault();

        if (sale is null)
            return null;

        return await MapToDtoAsync(sale, cancellationToken);
    }

    // Hard cap to keep Excel export from streaming millions of rows into memory.
    // Callers that may legitimately want more than this should switch to a
    // date-range-filtered export (TODO: add `ExportSalesByDateRangeAsync`).
    private const int ExportMaxRows = 10_000;

    public async Task<IEnumerable<SaleDto>> GetAllSalesAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // We fetch ExportMaxRows + 1 so we can detect truncation without an extra COUNT(*).
        var sales = await _context.Sales
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.MarketId == marketId)
            .OrderByDescending(s => s.CreatedAt)
            .ThenBy(s => s.Id)
            .Take(ExportMaxRows + 1)
            .AsNoTracking()
            .AsSplitQuery()
            .ToListAsync(cancellationToken);

        if (sales.Count > ExportMaxRows)
        {
            _logger.LogWarning(
                "Sales export for market {MarketId} truncated at {Cap} rows. " +
                "Consider switching to a date-range export.",
                marketId, ExportMaxRows);
            sales = sales.Take(ExportMaxRows).ToList();
        }

        return sales.Select(MapSaleToDto);
    }

    public async Task<PagedResult<SaleDto>> GetSalesPagedAsync(int page, int size, CancellationToken cancellationToken = default)
    {
        // Clamp inputs — clients cannot ask for arbitrarily large pages or negative offsets.
        // Upper bound on `page` prevents `(page - 1) * size` int overflow on hostile input
        // (e.g. ?page=2147483647) — at size=200 the max reachable offset is ~20M, well past
        // any realistic sales history.
        if (page < 1) page = 1;
        if (page > 100_000) page = 100_000;
        if (size < 1) size = 50;
        if (size > 200) size = 200;

        var marketId = _currentMarketService.GetCurrentMarketId();

        var baseQuery = _context.Sales
            .Where(s => s.MarketId == marketId);

        var total = await baseQuery.CountAsync(cancellationToken);
        if (total == 0)
            return PagedResult<SaleDto>.Empty(page, size);

        // Secondary sort by Id guarantees a stable order across pages even when
        // two sales share the same CreatedAt millisecond — without it, rows on the
        // page boundary can be duplicated or dropped between requests.
        var sales = await baseQuery
            .OrderByDescending(s => s.CreatedAt)
            .ThenBy(s => s.Id)
            .Skip((page - 1) * size)
            .Take(size)
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .AsNoTracking()
            .AsSplitQuery()
            .ToListAsync(cancellationToken);

        var items = sales.Select(MapSaleToDto).ToList();
        return PagedResult<SaleDto>.From(items, page, size, total);
    }

    private SaleDto MapSaleToDto(Sale s) => new(
        s.Id,
        s.SellerId,
        s.Seller?.FullName ?? "Unknown",
        s.CustomerId,
        s.Customer?.FullName,
        s.Customer?.Phone,
        s.Status.ToString(),
        s.TotalAmount,
        s.PaidAmount,
        s.TotalAmount - s.PaidAmount,
        s.CreatedAt,
        s.SaleItems.Select(si =>
        {
            string productName;
            string unit = "";
            if (!si.IsExternal)
            {
                productName = si.Product?.Name ?? "Unknown";
                unit = si.Product?.GetUnitName() ?? "";
            }
            else
            {
                productName = si.ExternalProductName ?? "Tashqi mahsulot";
            }
            return MapSaleItemToDto(si, productName, unit);
        }).ToList(),
        s.Payments.Select(p => new PaymentDto(
            p.Id,
            p.PaymentType.ToString().ToLowerInvariant(),
            p.Amount,
            p.CreatedAt,
            null,
            null,
            null
        )).ToList()
    );

    public async Task<IEnumerable<SaleDto>> GetSalesByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ✅ OPTIMIZED: Single query with eager loading
        // ✅ FIX: Add Distinct() to prevent duplicate sales from being returned
        var sales = await _context.Sales
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.MarketId == marketId && s.CreatedAt >= start && s.CreatedAt <= end)
            .OrderByDescending(s => s.CreatedAt)
            .AsNoTracking()
            .AsSplitQuery()
            .ToListAsync(cancellationToken);

        // M7 — was an inline duplicate of MapSaleToDto; consolidated.
        return sales.Select(MapSaleToDto);
    }

    public async Task<IEnumerable<SaleDto>> GetDraftSalesBySellerAsync(Guid sellerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ✅ OPTIMIZED: Single query with eager loading
        var sales = await _context.Sales
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.MarketId == marketId && s.SellerId == sellerId && s.Status == SaleStatus.Draft)
            .OrderByDescending(s => s.CreatedAt)
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        // M7 — was an inline duplicate of MapSaleToDto; consolidated.
        return sales.Select(MapSaleToDto);
    }

    public async Task<IEnumerable<SaleDto>> GetUnfinishedSalesBySellerAsync(Guid sellerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Draft, Debt va Paid statusdagi savdolarni olish
        var sales = await _context.Sales
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.MarketId == marketId && s.SellerId == sellerId &&
                       (s.Status == SaleStatus.Draft || s.Status == SaleStatus.Debt || s.Status == SaleStatus.Paid))
            .OrderByDescending(s => s.CreatedAt)
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        // M7 — was an inline duplicate of MapSaleToDto; consolidated.
        return sales.Select(MapSaleToDto);
    }

    public async Task<SaleDto> CreateSaleAsync(CreateSaleDto request, Guid sellerId, CancellationToken cancellationToken = default)
    {
        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            SellerId = sellerId,
            CustomerId = request.CustomerId,
            Status = SaleStatus.Draft,
            TotalAmount = 0,
            PaidAmount = 0,
            MarketId = _currentMarketService.GetCurrentMarketId()  // Multi-tenancy
        };

        await _unitOfWork.Sales.AddAsync(sale, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // If customer is specified, apply any available credit
        if (request.CustomerId.HasValue)
        {
            await ApplyCustomerCreditInternalAsync(sale.Id, request.CustomerId.Value, cancellationToken);
        }

        await _auditLogService.LogSaleActionAsync(sale.Id, "Create", sellerId, cancellationToken);

        return await MapToDtoAsync(sale, cancellationToken);
    }

    public async Task<SaleDto?> UpdateSaleCustomerAsync(Guid saleId, UpdateSaleCustomerDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.Id == saleId && s.MarketId == marketId,
            cancellationToken);
        var sale = sales.FirstOrDefault();

        if (sale is null)
            return null;

        // Faqat Draft va Debt statusdagi savdolarga mijoz qo'shish mumkin
        if (sale.Status != SaleStatus.Draft && sale.Status != SaleStatus.Debt)
            throw new InvalidOperationException("Faqat Draft va Debt statusdagi savdolarga mijoz qo'shish mumkin");

        // Agar mijoz berilgan bo'lsa, u shu do'konga tegishli ekanligini tekshiramiz
        if (request.CustomerId.HasValue)
        {
            var customers = await _unitOfWork.Customers.FindAsync(
                c => c.Id == request.CustomerId.Value && c.MarketId == marketId,
                cancellationToken);
            var customer = customers.FirstOrDefault();

            if (customer is null)
                throw new InvalidOperationException("Mijoz topilmadi yoki bu do'konga tegishli emas");
        }

        // Mijozni yangilaymiz
        sale.CustomerId = request.CustomerId;
        _unitOfWork.Sales.Update(sale);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // If customer is specified, apply any available credit
        if (request.CustomerId.HasValue)
        {
            await ApplyCustomerCreditInternalAsync(saleId, request.CustomerId.Value, cancellationToken);
        }

        return await MapToDtoAsync(sale, cancellationToken);
    }

    /// <summary>
    /// ============================================
    /// ✅ ISEXTERNAL SHARTI - TASHQI MAHSULOT
    /// ============================================
    /// </summary>
    public async Task<SaleItemDto?> AddSaleItemAsync(Guid saleId, AddSaleItemDto request, CancellationToken cancellationToken = default)
    {
        if (request.Quantity <= 0)
            throw new InvalidOperationException("Quantity must be greater than 0");
        if (request.SalePrice < 0)
            throw new InvalidOperationException("Sale price cannot be negative");

        var marketId = _currentMarketService.GetCurrentMarketId();

        // LOG: Track IsExternal flag
        _logger.LogInformation("[AddSaleItem] RECEIVED - SaleId: {SaleId}, IsExternal: {IsExternal}, ProductId: {ProductId}, ExternalProductName: {ProductName}, Quantity: {Quantity}",
            saleId, request.IsExternal, request.ProductId, request.ExternalProductName, request.Quantity);

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // Get sale with MarketId filtering
            var sales = await _unitOfWork.Sales.FindAsync(
                s => s.Id == saleId && s.MarketId == marketId,
                cancellationToken);
            var sale = sales.FirstOrDefault();

            if (sale is null || sale.Status != SaleStatus.Draft)
                throw new InvalidOperationException("Sale not found or not in Draft status");

            // Load sale items separately
            var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == saleId, cancellationToken);

            if (!request.IsExternal)
            {
                // ------------ ORDINARY PRODUCT (Oddiy mahsulot) ------------
                // ProductId bo'lishi shart
                if (request.ProductId == null)
                    throw new InvalidOperationException("ProductId kerak (oddiy mahsulot uchun)");

                var productId = request.ProductId.Value;
                // FOR UPDATE faqat PostgreSQL da ishlaydi; InMemory test DB da oddiy query
                Product? product;
                if (_context.Database.ProviderName?.Contains("InMemory") == false)
                {
                    // EF Core wraps this query and references xmin (the concurrency
                    // token on Product). PostgreSQL doesn't include xmin in `SELECT *`,
                    // so we must list it explicitly — otherwise we get
                    // `42703: column m.xmin does not exist`.
                    product = await _context.Products
                        .FromSqlInterpolated($"SELECT *, xmin FROM \"Products\" WHERE \"Id\" = {productId} FOR UPDATE")
                        .FirstOrDefaultAsync(cancellationToken);
                }
                else
                {
                    product = await _unitOfWork.Products.GetByIdAsync(productId, cancellationToken);
                }
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

                // Note: MinSalePrice validation is now UI-only warning, not enforced on backend
                // Sellers can sell below minimum price without comment if needed

                // Check threshold (warning only, not blocking)
                if (product.Quantity <= product.MinThreshold)
                {
                    // Log warning - product is at or below threshold
                    // This is allowed but should trigger warning in UI
                }

                SaleItem? resultSaleItem;
                decimal itemTotal;

                // CHECK: Is this product already in sale?
                var existingItem = saleItems.FirstOrDefault(si => si.ProductId == request.ProductId);

                if (existingItem != null)
                {
                    // Product exists - UPDATE existing item
                    var oldQuantity = existingItem.Quantity;
                    existingItem.Quantity += request.Quantity;

                    // LOG: Existing item update
                    _logger.LogInformation("[AddSaleItem] UPDATE EXISTING - OldQty: {OldQty}, RequestQty: {RequestQty}, NewQty: {NewQty}",
                        oldQuantity, request.Quantity, existingItem.Quantity);

                    _unitOfWork.SaleItems.Update(existingItem);

                    // Update stock
                    product.Quantity -= request.Quantity;
                    _unitOfWork.Products.Update(product);

                    itemTotal = existingItem.Quantity * existingItem.SalePrice;
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

                    // LOG: New item create
                    _logger.LogInformation("[AddSaleItem] CREATE NEW - Quantity: {Quantity}, ProductId: {ProductId}",
                        saleItem.Quantity, saleItem.ProductId);

                    await _unitOfWork.SaleItems.AddAsync(saleItem, cancellationToken);

                    // Update stock
                    product.Quantity -= request.Quantity;
                    _unitOfWork.Products.Update(product);

                    itemTotal = request.Quantity * request.SalePrice;
                    resultSaleItem = saleItem;
                }

                // Persist the SaleItem change first, then recompute Sale.TotalAmount
                // from the authoritative SUM over SaleItems. Replacing the old
                // arithmetic `sale.TotalAmount = old - x + new` with a fresh SUM kills
                // a race where two concurrent AddSaleItem calls each read a stale
                // in-memory total and overwrite each other's increment.
                await _unitOfWork.SaveChangesAsync(cancellationToken);
                await RecalculateSaleTotalAsync(sale, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // After the item lands and the sale total grows, re-apply any outstanding
                // customer credit so the new portion of the bill is automatically covered.
                if (sale.CustomerId.HasValue)
                {
                    await ApplyCustomerCreditInternalAsync(sale.Id, sale.CustomerId.Value, cancellationToken);
                }

                // LOG: After DB save
                _logger.LogInformation("[AddSaleItem] AFTER DB SAVE - Quantity: {Quantity}, ProductId: {ProductId}",
                    resultSaleItem.Quantity, resultSaleItem.ProductId);

                return MapSaleItemToDto(resultSaleItem, product.Name, product.GetUnitName());
            }
            else
            {
                // ------------ EXTERNAL PRODUCT (Tashqi mahsulot) ------------
                // ExternalProductName bo'lishi shart
                if (string.IsNullOrEmpty(request.ExternalProductName))
                    throw new InvalidOperationException("ExternalProductName kerak (tashqi mahsulot uchun)");

                // ExternalCostPrice is nullable on the DTO but mandatory when IsExternal
                // is true — without this guard the .Value access below NREs.
                if (!request.ExternalCostPrice.HasValue)
                    throw new InvalidOperationException("ExternalCostPrice kerak (tashqi mahsulot uchun)");
                if (request.ExternalCostPrice.Value < 0)
                    throw new InvalidOperationException("Tashqi tannarx manfiy bo'lmasin");

                // ✅ VALIDATION: Tashqi tannarx sotuv narxidan katta bo'lishi mumkin emas
                if (request.ExternalCostPrice.Value >= request.SalePrice)
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

                    // LOG: Existing item update
                    _logger.LogInformation("[AddSaleItem] UPDATE EXTERNAL - OldQty: {OldQty}, RequestQty: {RequestQty}, NewQty: {NewQty}",
                        oldQuantity, request.Quantity, existingItem.Quantity);

                    _unitOfWork.SaleItems.Update(existingItem);

                    itemTotal = existingItem.Quantity * existingItem.SalePrice;
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

                    // LOG: New item create
                    _logger.LogInformation("[AddSaleItem] CREATE EXTERNAL - Quantity: {Quantity}, ProductName: {ProductName}",
                        saleItem.Quantity, request.ExternalProductName);

                    await _unitOfWork.SaleItems.AddAsync(saleItem, cancellationToken);

                    // ✅ NO STOCK UPDATE - Tashqi mahsulotlar ombor qoldig'iga ta'sir qilmaydi

                    itemTotal = request.Quantity * request.SalePrice;
                    resultSaleItem = saleItem;
                }

                // Same SUM-from-items recompute as the ordinary branch.
                await _unitOfWork.SaveChangesAsync(cancellationToken);
                await RecalculateSaleTotalAsync(sale, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // External items also count toward the bill, so re-apply credit.
                if (sale.CustomerId.HasValue)
                {
                    await ApplyCustomerCreditInternalAsync(sale.Id, sale.CustomerId.Value, cancellationToken);
                }

                // LOG: After DB save
                _logger.LogInformation("[AddSaleItem] AFTER DB SAVE - IsExternal: {IsExternal}, ProductName: {ProductName}, Quantity: {Quantity}",
                    resultSaleItem.IsExternal, resultSaleItem.ExternalProductName, resultSaleItem.Quantity);

                // Mapping: Product name = ExternalProductName, Unit = empty
                return MapSaleItemToDto(
                    resultSaleItem,
                    resultSaleItem.ExternalProductName ?? "Unknown",
                    ""
                );
            }
        }, cancellationToken);
    }

    public async Task<SaleItemDto?> RemoveSaleItemAsync(Guid saleId, RemoveSaleItemDto request, CancellationToken cancellationToken = default)
    {
        if (request.Quantity <= 0)
            throw new InvalidOperationException("Quantity must be greater than 0");

        var marketId = _currentMarketService.GetCurrentMarketId();

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // Get sale with MarketId filtering
            var sales = await _unitOfWork.Sales.FindAsync(
                s => s.Id == saleId && s.MarketId == marketId,
                cancellationToken);
            var sale = sales.FirstOrDefault();

            if (sale is null || sale.Status != SaleStatus.Draft)
                throw new InvalidOperationException("Sale not found or not in Draft status");

            // Get sale item
            var saleItemGuid = Guid.Parse(request.SaleItemId);
            var saleItems = await _unitOfWork.SaleItems.FindAsync(
                si => si.Id == saleItemGuid && si.SaleId == saleId,
                cancellationToken);
            var saleItem = saleItems.FirstOrDefault();

            if (saleItem == null)
                throw new InvalidOperationException("Sale item not found");

            /// <summary>
            /// ============================================
            /// ✅ ISEXTERNAL SHARTI - STOKNI SAQLASH
            /// ============================================
            /// </summary>
            if (!saleItem.IsExternal)
            {
                // ---- ORDINARY PRODUCT (Oddiy mahsulot) ----
                // ProductId bo'lishi shart
                if (saleItem.ProductId == null)
                    throw new InvalidOperationException("ProductId null (oddiy mahsulot uchun)");

                var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId.Value, cancellationToken);
                if (product is null)
                    throw new InvalidOperationException("Product not found");

                // SECURITY: Verify product belongs to same market as sale
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
                    _unitOfWork.Products.Update(product);

                    itemTotal = saleItem.Quantity * saleItem.SalePrice;
                    resultSaleItem = saleItem; // Return deleted item info
                }
                else
                {
                    // Partial quantity removal
                    saleItem.Quantity -= request.Quantity;
                    _unitOfWork.SaleItems.Update(saleItem);

                    // ✅ Restore partial stock (faqat oddiy mahsulotlar uchun)
                    product.Quantity += request.Quantity;
                    _unitOfWork.Products.Update(product);

                    itemTotal = saleItem.Quantity * saleItem.SalePrice;
                    resultSaleItem = saleItem;
                }

                // SUM-from-items recompute — matches AddSaleItem (kills the
                // same race condition under concurrent remove + add).
                await _unitOfWork.SaveChangesAsync(cancellationToken);
                await RecalculateSaleTotalAsync(sale, cancellationToken);
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
                    itemTotal = saleItem.Quantity * saleItem.SalePrice;
                    resultSaleItem = saleItem;
                }
                else
                {
                    // Partial quantity removal
                    saleItem.Quantity -= request.Quantity;
                    _unitOfWork.SaleItems.Update(saleItem);
                    itemTotal = saleItem.Quantity * saleItem.SalePrice;
                    resultSaleItem = saleItem;
                }

                // SUM-from-items recompute.
                await _unitOfWork.SaveChangesAsync(cancellationToken);
                await RecalculateSaleTotalAsync(sale, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                // Mapping: Product name = ExternalProductName, Unit = empty
                return MapSaleItemToDto(
                    saleItem,
                    saleItem.ExternalProductName ?? "Unknown",
                    ""
                );
            }
        }, cancellationToken);
    }

    public async Task<PaymentDto?> AddPaymentAsync(Guid saleId, AddPaymentDto request, CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
            throw new InvalidOperationException("Payment amount must be greater than 0");

        var marketId = _currentMarketService.GetCurrentMarketId();

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // Repository now enforces MarketId at the query layer — a sale in
            // another tenant returns null here, same as a non-existent id.
            var sale = await _unitOfWork.Sales.GetWithItemsAsync(saleId, marketId, cancellationToken);

            if (sale is null)
                throw new InvalidOperationException("Sale not found");

            if (sale.Status == SaleStatus.Paid || sale.Status == SaleStatus.Closed || sale.Status == SaleStatus.Cancelled)
                throw new InvalidOperationException($"Cannot add payment to sale with status: {sale.Status}");

            // Log payment details with structured properties
            _logger.LogInformation("Adding payment {PaymentAmount} to sale {SaleId}, " +
                "TotalAmount: {TotalAmount}, PaidAmount: {PaidAmount}, Status: {Status}, ItemsCount: {ItemsCount}",
                request.Amount, sale.Id, sale.TotalAmount, sale.PaidAmount, sale.Status, sale.SaleItems?.Count ?? 0);

            if (sale.SaleItems != null)
            {
                foreach (var item in sale.SaleItems)
                {
                    decimal itemTotal = item.SalePrice * item.Quantity;
                    _logger.LogDebug("Sale item: ProductId={ProductId}, Quantity={Quantity}, SalePrice={SalePrice}, Total={Total}",
                        item.ProductId, item.Quantity, item.SalePrice, itemTotal);
                }
            }

            // VALIDATION: Mijozsiz qarzga savdo taqiqlanadi
            var newPaidAmount = sale.PaidAmount + request.Amount;
            if (newPaidAmount < sale.TotalAmount && (!sale.CustomerId.HasValue || sale.CustomerId.Value == Guid.Empty))
            {
                throw new InvalidOperationException("Mijoz tanlanmagan savdoni qarzga yopib bo'lmaydi. Iltimos, mijoz tanlang yoki to'liq to'lov qiling.");
            }

            // Map frontend's "CARD" to backend's "Terminal"
            var paymentTypeStr = request.PaymentType;
            if (string.Equals(paymentTypeStr, "CARD", StringComparison.OrdinalIgnoreCase))
            {
                paymentTypeStr = "Terminal";
            }

            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                SaleId = saleId,
                PaymentType = Enum.Parse<PaymentType>(paymentTypeStr, true),
                Amount = request.Amount,
                MarketId = sale.MarketId  // Multi-tenancy - inherit from Sale
            };

            await _unitOfWork.Payments.AddAsync(payment, cancellationToken);

            // Update cash register balance for cash payments — scoped to this sale's market.
            if (payment.PaymentType == PaymentType.Cash)
            {
                var cashRegister = await _context.CashRegisters
                    .FirstOrDefaultAsync(cr => cr.MarketId == sale.MarketId, cancellationToken);

                if (cashRegister == null)
                {
                    cashRegister = new CashRegister
                    {
                        Id = Guid.NewGuid(),
                        MarketId = sale.MarketId,
                        CurrentBalance = 0,
                        LastUpdated = DateTime.UtcNow
                    };
                    _context.CashRegisters.Add(cashRegister);
                }

                cashRegister.CurrentBalance += request.Amount;
                cashRegister.LastUpdated = DateTime.UtcNow;
            }

            // Update sale paid amount
            sale.PaidAmount += request.Amount;

            // CRITICAL: Recalculate TotalAmount from SaleItems before determining status
            decimal calculatedTotal = sale.SaleItems?.Sum(si => si.SalePrice * si.Quantity) ?? 0;
            _logger.LogDebug("Calculated TotalAmount from items: {CalculatedTotal}", calculatedTotal);

            // Update TotalAmount if it differs (this can happen if sale was created before items were added)
            if (sale.TotalAmount != calculatedTotal)
            {
                _logger.LogWarning("TotalAmount mismatch for sale {SaleId}! DB={DbTotal}, Calculated={CalcTotal}. Updating...",
                    sale.Id, sale.TotalAmount, calculatedTotal);
                sale.TotalAmount = calculatedTotal;
            }

            _logger.LogDebug("Final values for sale {SaleId} - TotalAmount: {TotalAmount}, PaidAmount: {PaidAmount}",
                sale.Id, sale.TotalAmount, sale.PaidAmount);

            // Determine new status
            _logger.LogDebug("Determining new status for sale {SaleId}: " +
                "TotalAmount={TotalAmount} (>0: {IsGreaterThan0}), " +
                "PaidAmount={PaidAmount} (>=Total: {IsPaidInFull}, >0: {IsPaidPartial}, <Total: {IsPartialPayment})",
                sale.Id, sale.TotalAmount, sale.TotalAmount > 0,
                sale.PaidAmount, sale.PaidAmount >= sale.TotalAmount,
                sale.PaidAmount > 0, sale.PaidAmount < sale.TotalAmount);

            // 1. To'liq to'langan savdo
            if (sale.TotalAmount > 0 && sale.PaidAmount >= sale.TotalAmount)
            {
                // Semantic distinction (mirrors DebtService.PayAsync):
                //   Paid   = sale was paid in full at sale time, never had debt.
                //   Closed = sale was previously on debt (partial payment + carried),
                //            and the customer has now finished paying it off.
                // Without this branch, paying the final installment via AddPaymentAsync
                // would land on Paid while paying it via DebtService.PayAsync would land
                // on Closed — same business event, two different terminal states.
                var wasOnDebt = sale.Status == SaleStatus.Debt;
                sale.Status = wasOnDebt ? SaleStatus.Closed : SaleStatus.Paid;
                _logger.LogInformation(
                    "Sale {SaleId} is fully paid, setting status to {Status} (wasOnDebt={WasOnDebt})",
                    saleId, sale.Status, wasOnDebt);

                // Close any associated debt (filtered by market)
                var existingDebtToClose = (await _unitOfWork.Debts.FindAsync(
                    d => d.SaleId == saleId && d.MarketId == sale.MarketId,
                    cancellationToken)).FirstOrDefault();

                if (existingDebtToClose != null)
                {
                    existingDebtToClose.Status = DebtStatus.Closed;
                    existingDebtToClose.RemainingDebt = 0;
                    _unitOfWork.Debts.Update(existingDebtToClose);
                }
            }
            // 2. Qisman to'langan savdo (qarzga yopilgan)
            else if (sale.TotalAmount > 0 && sale.PaidAmount > 0 && sale.PaidAmount < sale.TotalAmount)
            {
                _logger.LogInformation("Sale {SaleId} has partial payment, setting status to Debt", saleId);
                sale.Status = SaleStatus.Debt;

                // Create or update debt record - ONLY if there's a customer
                // Mijozsiz qarzga savdo ham mumkin, status "debt" bo'ladi, lekin debt record yaratilmaydi
                if (sale.CustomerId.HasValue && sale.CustomerId.Value != Guid.Empty)
                {
                    var existingDebt = (await _unitOfWork.Debts.FindAsync(
                        d => d.SaleId == saleId && d.MarketId == sale.MarketId,
                        cancellationToken)).FirstOrDefault();

                    if (existingDebt == null)
                    {
                        var newDebt = new Debt
                        {
                            Id = Guid.NewGuid(),
                            SaleId = saleId,
                            CustomerId = sale.CustomerId.Value,
                            TotalDebt = sale.TotalAmount,
                            RemainingDebt = sale.TotalAmount - sale.PaidAmount,
                            Status = DebtStatus.Open,
                            MarketId = sale.MarketId
                        };
                        await _unitOfWork.Debts.AddAsync(newDebt, cancellationToken);
                    }
                    else
                    {
                        existingDebt.TotalDebt = sale.TotalAmount;
                        existingDebt.RemainingDebt = sale.TotalAmount - sale.PaidAmount;
                        existingDebt.Status = existingDebt.RemainingDebt > 0 ? DebtStatus.Open : DebtStatus.Closed;
                        _unitOfWork.Debts.Update(existingDebt);
                    }
                }
            }
            // 3. TotalAmount 0 bo'lsa (hali mahsulotlar qo'shilgan yo'q), status Draft da qoladi
            else if (sale.TotalAmount == 0)
            {
                _logger.LogInformation("Sale {SaleId} has TotalAmount=0, keeping Draft status", saleId);
            }
            else
            {
                _logger.LogWarning("Unhandled case for sale {SaleId}: TotalAmount={TotalAmount}, PaidAmount={PaidAmount}",
                    sale.Id, sale.TotalAmount, sale.PaidAmount);
            }

            _unitOfWork.Sales.Update(sale);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Sale {SaleId} final status: {Status}", sale.Id, sale.Status);

            // Audit log
            await _auditLogService.LogPaymentActionAsync(payment.Id, sale.SellerId, cancellationToken);

            return new PaymentDto(
                payment.Id,
                payment.PaymentType.ToString().ToLowerInvariant(),
                payment.Amount,
                payment.CreatedAt,
                sale.Status.ToString().ToLowerInvariant(), // Yangilangan sale status
                sale.PaidAmount, // Yangilangan paid amount
                sale.TotalAmount // Total amount
            );
        }, cancellationToken);
    }

    /// <summary>
    /// ============================================
    /// ✅ ISEXTERNAL SHARTI - TASHQI MAHSULOT
    /// ============================================
    /// </summary>
    public async Task<SaleDto?> CancelSaleAsync(Guid saleId, Guid adminId, CancellationToken cancellationToken = default)
    {
        // adminId is the JWT-extracted caller identity (controller pulls it
        // from ClaimTypes.NameIdentifier). It used to be a string parsed
        // from a client-supplied request body, which let any caller with
        // sales.delete forge another admin's id into the audit row.
        _logger.LogInformation("CancelSale by Admin {AdminId}", adminId);

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            var marketId = _currentMarketService.GetCurrentMarketId();

            var sales = await _unitOfWork.Sales.FindAsync(
                s => s.Id == saleId && s.MarketId == marketId,
                cancellationToken);
            var sale = sales.FirstOrDefault();

            if (sale is null)
            {
                _logger.LogWarning("Sale not found: {SaleId}", saleId);
                return null;
            }

            if (sale.Status == SaleStatus.Cancelled)
                throw new InvalidOperationException("Sale is already cancelled");

            // Restore stock for all items.
            // P4 — fetch every affected Product in ONE round trip instead of
            // one-per-item. A cancelled sale with 50 ordinary items used to
            // fire 50 separate `Products WHERE Id = ?` queries; now we issue
            // a single `Products WHERE Id IN (...)`. External items have no
            // ProductId so they're filtered out upfront.
            var saleItems = (await _unitOfWork.SaleItems.FindAsync(
                si => si.SaleId == saleId, cancellationToken)).ToList();

            var ordinaryProductIds = saleItems
                .Where(i => !i.IsExternal && i.ProductId.HasValue)
                .Select(i => i.ProductId!.Value)
                .Distinct()
                .ToList();

            if (ordinaryProductIds.Count > 0)
            {
                var products = await _context.Products
                    .Where(p => ordinaryProductIds.Contains(p.Id) && p.MarketId == marketId)
                    .ToDictionaryAsync(p => p.Id, cancellationToken);

                foreach (var item in saleItems)
                {
                    if (item.IsExternal || !item.ProductId.HasValue) continue;
                    if (products.TryGetValue(item.ProductId.Value, out var product))
                    {
                        product.Quantity += item.Quantity;
                        _unitOfWork.Products.Update(product);
                    }
                }
            }
            // External items (IsExternal == true) have no stock to restore.

            // Refund cash payments back to the till. Card / Click / Terminal payments
            // flow through external rails (POS / payment processor) so they don't touch
            // our CashRegister — only Cash payments must be reversed here. The Payment
            // records themselves stay in place as an audit trail.
            var cashPayments = await _unitOfWork.Payments.FindAsync(
                p => p.SaleId == saleId && p.PaymentType == PaymentType.Cash,
                cancellationToken);
            var cashRefund = cashPayments.Sum(p => p.Amount);
            if (cashRefund > 0)
            {
                var cashRegister = await _context.CashRegisters
                    .FirstOrDefaultAsync(cr => cr.MarketId == sale.MarketId, cancellationToken);
                if (cashRegister != null)
                {
                    cashRegister.CurrentBalance -= cashRefund;
                    cashRegister.LastUpdated = DateTime.UtcNow;
                    _logger.LogInformation(
                        "Sale {SaleId} cancelled — refunded {Amount} cash to market {MarketId} till",
                        saleId, cashRefund, sale.MarketId);
                }
            }

            // Update sale status
            sale.Status = SaleStatus.Cancelled;
            _unitOfWork.Sales.Update(sale);

            // S4 — close the associated debt cleanly. The previous code
            // relied on `sale.Debt` being eagerly loaded; the query above
            // does NOT include it, so `sale.Debt` was always null and the
            // debt never closed when the sale was cancelled. The customer's
            // total outstanding balance kept showing the cancelled sale's
            // RemainingDebt — a real financial-correctness bug. Look the
            // debt up directly, mark it Closed AND zero RemainingDebt so
            // the customer's running total stays consistent.
            var openDebts = await _unitOfWork.Debts.FindAsync(
                d => d.SaleId == saleId && d.Status == DebtStatus.Open,
                cancellationToken);
            foreach (var debt in openDebts)
            {
                debt.Status = DebtStatus.Closed;
                debt.RemainingDebt = 0;
                _unitOfWork.Debts.Update(debt);
            }

            // P6 — stage the audit row on the same DbContext BEFORE the
            // single SaveChanges so business state + audit INSERT batch into
            // one round trip instead of two. The audit row will now commit /
            // rollback with the surrounding business transaction (which is
            // the stronger guarantee here — if the cancel rolls back we
            // don't want a "Cancel" audit row lingering).
            await _auditLogService.EnqueueActionAsync(
                AuditEntityTypes.Sale, saleId, AuditActions.Cancel, adminId,
                new
                {
                    SaleId = saleId,
                    sale.SellerId,
                    sale.CustomerId,
                    Status = sale.Status.ToString(),
                    sale.TotalAmount,
                    sale.PaidAmount,
                },
                cancellationToken);

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return await MapToDtoAsync(sale, cancellationToken);
        }, cancellationToken);
    }

    public async Task<bool> ValidateSalePriceAsync(Guid saleItemId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var saleItems = await _unitOfWork.SaleItems.FindAsync(
            si => si.Id == saleItemId,
            cancellationToken);
        var saleItem = saleItems.FirstOrDefault();

        if (saleItem is null)
            return false;

        // Get sale to verify market
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.Id == saleItem.SaleId && s.MarketId == marketId,
            cancellationToken);
        if (!sales.Any())
            return false;

        // External products have no MinSalePrice constraint — always valid.
        if (saleItem.IsExternal)
            return true;

        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == saleItem.ProductId && p.MarketId == marketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        if (product is null)
            return false;

        // Returns true if price is valid (>= min price) or comment is provided
        return saleItem.SalePrice >= product.MinSalePrice || !string.IsNullOrWhiteSpace(saleItem.Comment);
    }

    /// <summary>
    /// Recompute Sale.TotalAmount from the authoritative SUM over its SaleItems.
    /// Replaces the old `sale.TotalAmount += x` / `-= x` arithmetic that was
    /// race-prone under concurrent AddSaleItem / RemoveSaleItem calls — two
    /// callers could each read the same stale in-memory total, each apply
    /// their own delta, and the last write would clobber the other's
    /// contribution. SUM-from-DB is deterministic regardless of order.
    /// Callers should SaveChanges BEFORE invoking this so newly added/removed
    /// items are visible in the SUM.
    /// </summary>
    private async Task RecalculateSaleTotalAsync(Sale sale, CancellationToken cancellationToken = default)
    {
        sale.TotalAmount = await _context.SaleItems
            .Where(si => si.SaleId == sale.Id)
            .SumAsync(si => si.SalePrice * si.Quantity, cancellationToken);
        _unitOfWork.Sales.Update(sale);
    }

    /// <summary>
    /// Applies customer's available credit (from negative payments/refunds) to a sale.
    /// This is called when a customer is associated with a sale or when finalizing a sale.
    /// </summary>
    private async Task ApplyCustomerCreditInternalAsync(Guid saleId, Guid customerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var availableCredit = await _customerService.GetAvailableCreditAsync(customerId, cancellationToken);

        if (availableCredit <= 0)
            return;

        var sale = await _context.Sales
            .Include(s => s.Payments)
            .FirstOrDefaultAsync(s => s.Id == saleId && s.MarketId == marketId, cancellationToken);

        if (sale == null)
            return;

        var creditToApply = Math.Min(availableCredit, sale.TotalAmount - sale.PaidAmount);

        if (creditToApply <= 0)
            return;

        _logger.LogInformation("Applying customer credit: SaleId={SaleId}, CustomerId={CustomerId}, CreditToApply={CreditToApply}, AvailableCredit={AvailableCredit}",
            saleId, customerId, creditToApply, availableCredit);

        // Record credit consumption as a positive Payment with PaymentType.Credit.
        // GetAvailableCreditAsync subtracts these from the refund balance so the same
        // credit cannot be spent twice.
        var creditPayment = new Payment
        {
            Id = Guid.NewGuid(),
            SaleId = saleId,
            MarketId = marketId,
            PaymentType = PaymentType.Credit,
            Amount = creditToApply,
            CreatedAt = DateTime.UtcNow
        };
        await _context.Payments.AddAsync(creditPayment, cancellationToken);

        sale.PaidAmount += creditToApply;
        _context.Sales.Update(sale);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Credit applied successfully: SaleId={SaleId}, NewPaidAmount={NewPaidAmount}",
            saleId, sale.PaidAmount);
    }

    /// <summary>
    /// Public method for ISaleService - applies customer credit and returns updated sale
    /// </summary>
    public async Task<SaleDto?> ApplyCustomerCreditAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Get sale to find customer
        var sale = await _unitOfWork.Sales.FindAsync(
            s => s.Id == saleId && s.MarketId == marketId,
            cancellationToken);
        var saleEntity = sale.FirstOrDefault();

        if (saleEntity == null)
            return null;

        if (!saleEntity.CustomerId.HasValue)
            return null; // No customer to apply credit to

        // Apply credit using internal method
        await ApplyCustomerCreditInternalAsync(saleId, saleEntity.CustomerId.Value, cancellationToken);

        // Return updated sale
        return await GetSaleByIdAsync(saleId, cancellationToken);
    }

    /// <summary>
    /// Maps SaleItem entity to DTO, handling external products correctly
    /// </summary>
    private static SaleItemDto MapSaleItemToDto(SaleItem item, string productName, string unit = "")
    {
        /// <summary>
        /// ============================================
        /// ✅ EFFECTIVE COST PRICE & ISEXTERNAL FLAG
        /// ============================================
        /// </summary>
        decimal effectiveCostPrice = item.IsExternal
            ? item.ExternalCostPrice
            : item.CostPrice;

        return new SaleItemDto(
            item.Id.ToString(),
            item.SaleId.ToString(),
            item.ProductId,  // ✅ Nullable
            productName,
            item.Quantity,
            effectiveCostPrice,  // ✅ Effective cost price
            item.SalePrice,
            item.TotalPrice,
            (item.SalePrice - effectiveCostPrice) * item.Quantity,  // ✅ Recalculated profit
            unit,
            item.Comment,
            item.IsExternal  // ✅ New flag
        );
    }

    private async Task<SaleDto> MapToDtoAsync(Sale sale, CancellationToken cancellationToken)
    {
        // Get sale items
        var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == sale.Id, cancellationToken);
        var itemsDto = new List<SaleItemDto>();

        /// <summary>
        /// ============================================
        /// ✅ ISEXTERNAL SHARTI - Product name olish
        /// ============================================
        /// </summary>
        // Batch fetch all ordinary products to avoid N+1 query (faqat oddiy mahsulotlar uchun)
        var ordinaryProductIds = saleItems
            .Where(si => !si.IsExternal && si.ProductId.HasValue)
            .Select(si => si.ProductId!.Value)
            .Distinct()
            .ToList();

        var products = new Dictionary<Guid, Product>();
        if (ordinaryProductIds.Any())
        {
            var productList = await _unitOfWork.Products.FindAsync(
                p => ordinaryProductIds.Contains(p.Id) && p.MarketId == sale.MarketId,
                cancellationToken);
            foreach (var p in productList)
            {
                products[p.Id] = p;
            }
        }

        foreach (var item in saleItems)
        {
            // ✅ ISEXTERNAL SHARTI - Product name olish
            string? productName = null;
            string unit = "";

            if (!item.IsExternal)
            {
                // Oddiy mahsulot - Product table'dan nomini olish.
                // ProductId is nullable on the entity; guard before .Value
                // so a corrupt row degrades to "Unknown" instead of throwing.
                if (item.ProductId.HasValue &&
                    products.TryGetValue(item.ProductId.Value, out var product))
                {
                    productName = product.Name;
                    unit = product.GetUnitName();
                }
            }
            else
            {
                // Tashqi mahsulot - ExternalProductName ishlatish
                productName = item.ExternalProductName;
                // Unit bo'sh qoldiriladi (tashqi mahsulotlar uchun)
            }

            itemsDto.Add(MapSaleItemToDto(item, productName ?? "Unknown", unit));
        }

        // Get payments
        var payments = await _unitOfWork.Payments.FindAsync(p => p.SaleId == sale.Id, cancellationToken);
        var paymentsDto = payments.Select(p => new PaymentDto(
            p.Id,
            p.PaymentType.ToString().ToLowerInvariant(),
            p.Amount,
            p.CreatedAt,
            null,
            null,
            null
        )).ToList();

        // Get seller name
        var seller = await _unitOfWork.Users.GetByIdAsync(sale.SellerId, cancellationToken);
        var customer = sale.CustomerId.HasValue ? await _unitOfWork.Customers.GetByIdAsync(sale.CustomerId.Value, cancellationToken) : null;

        return new SaleDto(
            sale.Id,
            sale.SellerId,
            seller?.FullName ?? "Unknown",
            sale.CustomerId,
            customer?.FullName,
            customer?.Phone,
            sale.Status.ToString(),
            sale.TotalAmount,
            sale.PaidAmount,
            sale.TotalAmount - sale.PaidAmount,
            sale.CreatedAt,
            itemsDto,
            paymentsDto
        );
    }

    /// <summary>
    /// ============================================
    /// ✅ ISEXTERNAL SHARTI - TASHQI MAHSULOT O'CHIRISH
    /// ============================================
    /// Savdoni o'chirganda tashqi mahsulotlar stokni saqlash
    /// </summary>
    public async Task<SaleDto?> DeleteSaleAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            var sale = await _context.Sales
                .Include(s => s.SaleItems)
                    .ThenInclude(si => si.Product)
                .FirstOrDefaultAsync(s => s.Id == saleId && s.MarketId == marketId, cancellationToken);

            if (sale is null)
            {
                _logger.LogWarning("Sale not found: {SaleId} in MarketId: {MarketId}", saleId, marketId);
                return null;
            }

            if (sale.IsDeleted)
            {
                _logger.LogWarning("Sale already deleted: {SaleId}", saleId);
                return null;
            }

            if (sale.Status != SaleStatus.Draft && sale.Status != SaleStatus.Paid)
            {
                _logger.LogWarning("Sale cannot be deleted: {SaleId}, Status: {Status}", saleId, sale.Status);
                throw new InvalidOperationException("Faqat draft yoki to'langan (Paid) savdolarini o'chirish mumkin! Qarzli savdolarni o'chirib bo'lmaydi.");
            }

            // Save sale items for DTO
            var saleItems = sale.SaleItems.ToList();
            _logger.LogInformation("Found {Count} sale items to delete", saleItems.Count);

            foreach (var saleItem in saleItems)
            {
                _logger.LogInformation("Deleting SaleItem: {SaleItemId}, Product: {ProductId}, Qty: {Quantity}, IsExternal: {IsExternal}",
                    saleItem.Id, saleItem.ProductId, saleItem.Quantity, saleItem.IsExternal);

                // ============================================
                // ✅ ISEXTERNAL SHARTI - STOKNI QAYTARISH
                // ============================================
                if (!saleItem.IsExternal && saleItem.Product != null)
                {
                    // Faqat oddiy mahsulotlar uchun stokni qaytarish
                    saleItem.Product.Quantity += saleItem.Quantity;
                    _unitOfWork.Products.Update(saleItem.Product);
                    _logger.LogInformation("Product stock restored: {ProductId}, Qty: +{Quantity}",
                        saleItem.ProductId, saleItem.Quantity);
                }
                // Tashqi mahsulotlar - stokni o'zgarmaslik
            }

            // Savdoni o'chirish (soft delete - IsDeleted = true)
            sale.IsDeleted = true;
            _context.Sales.Update(sale);
            _logger.LogInformation("Sale marked as deleted: {SaleId}", saleId);

            // Payments ham o'chirilishi kerak
            var payments = await _context.Payments
                .Where(p => p.SaleId == saleId)
                .ToListAsync(cancellationToken);

            // BEFORE deleting the payments, reverse the cash side. Otherwise a
            // Paid sale whose `CurrentBalance += amount` already landed in the
            // market's cash register would leave that money in the register
            // forever — effectively making the customer's cash disappear.
            // Card / Transfer / Click / Credit payments don't touch the
            // register so we only reverse Cash.
            //
            // netCashOnSale = positive cash payments + negative cash refunds
            //   > 0 : sale brought net cash in — back it out of the register
            //   < 0 : sale net-refunded the customer (overpaid/return) — the
            //         register was previously debited by `|net|`; add it back
            //   = 0 : nothing to do
            var netCashOnSale = payments
                .Where(p => p.PaymentType == PaymentType.Cash)
                .Sum(p => p.Amount);
            if (netCashOnSale != 0)
            {
                var cashRegister = await _context.CashRegisters
                    .FirstOrDefaultAsync(cr => cr.MarketId == sale.MarketId, cancellationToken);
                if (cashRegister != null)
                {
                    cashRegister.CurrentBalance -= netCashOnSale;
                    cashRegister.LastUpdated = DateTime.UtcNow;
                    _logger.LogInformation(
                        "Cash reversed on sale delete: SaleId={SaleId} NetCash={Amount} NewBalance={Balance}",
                        saleId, netCashOnSale, cashRegister.CurrentBalance);
                }
                else
                {
                    _logger.LogWarning(
                        "No CashRegister for MarketId={MarketId} when reversing sale {SaleId} (net {Amount} cash). " +
                        "Skipping reversal — this should not happen in a normally-seeded market.",
                        sale.MarketId, saleId, netCashOnSale);
                }
            }

            foreach (var payment in payments)
            {
                _context.Payments.Remove(payment);
                _logger.LogInformation("Payment deleted: {PaymentId}", payment.Id);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // DTO ni yaratish
            var itemsDto = new List<SaleItemDto>();
            foreach (var si in saleItems)
            {
                string productName;
                string unit = "";
                if (!si.IsExternal)
                {
                    productName = si.Product?.Name ?? "Unknown";
                    unit = si.Product?.GetUnitName() ?? "";
                }
                else
                {
                    productName = si.ExternalProductName ?? "Tashqi mahsulot";
                }
                itemsDto.Add(new SaleItemDto(
                    si.Id.ToString(),
                    si.SaleId.ToString(),
                    si.ProductId,
                    productName,
                    si.Quantity,
                    si.IsExternal ? si.ExternalCostPrice : si.CostPrice,
                    si.SalePrice,
                    si.TotalPrice,
                    (si.SalePrice - (si.IsExternal ? si.ExternalCostPrice : si.CostPrice)) * si.Quantity,
                    unit,
                    si.Comment,
                    si.IsExternal
                ));
            }

            var paymentsDto = payments.Select(p => new PaymentDto(
                p.Id,
                p.PaymentType.ToString(),
                p.Amount,
                p.CreatedAt,
                null,
                null,
                null
            )).ToList();

            var seller = await _unitOfWork.Users.GetByIdAsync(sale.SellerId, cancellationToken);
            var customer = sale.CustomerId.HasValue ? await _unitOfWork.Customers.GetByIdAsync(sale.CustomerId.Value, cancellationToken) : null;

            return new SaleDto(
                sale.Id,
                sale.SellerId,
                seller?.FullName ?? "Unknown",
                sale.CustomerId,
                customer?.FullName,
                customer?.Phone,
                sale.Status.ToString(),
                sale.TotalAmount,
                sale.PaidAmount,
                sale.TotalAmount - sale.PaidAmount,
                sale.CreatedAt,
                itemsDto,
                paymentsDto
            );
        }, cancellationToken);
    }

    /// <summary>
    /// Marks a sale as debt status
    /// </summary>
    public async Task<SaleDto?> MarkSaleAsDebtAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            var sales = await _unitOfWork.Sales.FindAsync(
                s => s.Id == saleId && s.MarketId == marketId,
                cancellationToken);
            var sale = sales.FirstOrDefault();

            if (sale is null)
                return null;

            if (sale.PaidAmount >= sale.TotalAmount)
                throw new InvalidOperationException("Sale is already fully paid, cannot mark as debt");

            sale.Status = SaleStatus.Debt;
            _unitOfWork.Sales.Update(sale);

            // Create or update debt record
            var existingDebt = await _unitOfWork.Debts.FindAsync(
                d => d.SaleId == saleId && d.MarketId == marketId,
                cancellationToken);
            var debt = existingDebt.FirstOrDefault();

            if (debt == null && sale.CustomerId.HasValue)
            {
                debt = new Debt
                {
                    Id = Guid.NewGuid(),
                    SaleId = sale.Id,
                    CustomerId = sale.CustomerId.Value,
                    MarketId = marketId,
                    TotalDebt = sale.TotalAmount,
                    RemainingDebt = sale.TotalAmount - sale.PaidAmount,
                    Status = DebtStatus.Open,
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.Debts.AddAsync(debt, cancellationToken);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return await MapToDtoAsync(sale, cancellationToken);
        }, cancellationToken);
    }

    /// <summary>
    /// Updates sale item price with role-based permissions
    /// </summary>
    public async Task<SaleItemDto?> UpdateSaleItemPriceAsync(Guid saleItemId, UpdateSaleItemPriceDto request, CancellationToken cancellationToken = default)
    {
        // S2 — guard against negative prices at the entry point. The
        // recalculated Sale.TotalAmount would otherwise silently go negative
        // and break every downstream report that sums TotalAmount.
        if (request.NewPrice < 0)
            throw new InvalidOperationException("Narx manfiy bo'lmasin");

        var marketId = _currentMarketService.GetCurrentMarketId();

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            var saleItems = await _unitOfWork.SaleItems.FindAsync(
                si => si.Id == saleItemId,
                cancellationToken,
                includeProperties: "Sale");
            var saleItem = saleItems.FirstOrDefault();

            if (saleItem == null)
                throw new InvalidOperationException("SaleItem topilmadi");

            var sale = saleItem.Sale;
            if (sale == null || sale.MarketId != marketId)
                throw new InvalidOperationException("Sotuv topilmadi");

            // S2 — refuse to mutate prices on a finalised sale. Previously the
            // method would happily overwrite SalePrice on a Paid / Debt /
            // Cancelled sale, corrupting the historic financial total even
            // though Sale.Xmin would block the eventual save — that's a
            // 500 to the user instead of a clean 400. Status check first.
            if (sale.Status != SaleStatus.Draft && sale.Status != SaleStatus.Debt)
                throw new InvalidOperationException(
                    "Narxni faqat Draft yoki Qarz holatidagi sotuvlarda o'zgartirish mumkin");

            // Update SaleItem price
            saleItem.SalePrice = request.NewPrice;
            _unitOfWork.SaleItems.Update(saleItem);

            // S2 — persist the SaleItem change first, then SUM straight from
            // the DB. The old code walked tracked entities in memory which
            // depended on EF identity-resolution semantics; aligning with
            // AddSaleItem's pattern (SaveChanges → RecalculateSaleTotalAsync
            // via SUM → SaveChanges) makes the result deterministic and
            // race-protected by Sale.Xmin.
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await RecalculateSaleTotalAsync(sale, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // Get product name for response
            string productName;
            string unit = "";

            if (!saleItem.IsExternal)
            {
                if (saleItem.ProductId.HasValue)
                {
                    var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId.Value, cancellationToken);
                    productName = product?.Name ?? "Unknown";
                    unit = product?.GetUnitName() ?? "";
                }
                else
                {
                    productName = "Unknown";
                }
            }
            else
            {
                productName = saleItem.ExternalProductName ?? "Tashqi mahsulot";
                unit = "";
            }

            return new SaleItemDto(
                saleItem.Id.ToString(),
                saleItem.SaleId.ToString(),
                saleItem.ProductId,
                productName,
                saleItem.Quantity,
                saleItem.IsExternal ? saleItem.ExternalCostPrice : saleItem.CostPrice,
                saleItem.SalePrice,
                saleItem.TotalPrice,
                (saleItem.SalePrice - (saleItem.IsExternal ? saleItem.ExternalCostPrice : saleItem.CostPrice)) * saleItem.Quantity,
                unit,
                saleItem.Comment,
                saleItem.IsExternal
            );
        }, cancellationToken);
    }

    /// <summary>
    /// Returns a sale item (partial or full return)
    /// </summary>
    public async Task<SaleItemDto?> ReturnSaleItemAsync(Guid saleId, ReturnSaleItemRequest request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        return await _unitOfWork.ExecuteInTransactionAsync<SaleItemDto?>(async () =>
        {
            var sale = await _context.Sales
                .Include(s => s.SaleItems)
                    .ThenInclude(si => si.Product)
                .Include(s => s.Payments)
                .FirstOrDefaultAsync(s => s.Id == saleId && s.MarketId == marketId, cancellationToken);

            if (sale == null)
                return null;

            var saleItem = sale.SaleItems.FirstOrDefault(si => si.Id.ToString() == request.SaleItemId);
            if (saleItem == null)
                return null;

            if (request.Quantity <= 0 || request.Quantity > saleItem.Quantity)
                return null;

            var returnQuantity = request.Quantity;
            var refundAmount = returnQuantity * saleItem.SalePrice;

            // Update sale item quantity or remove
            string originalComment = saleItem.Comment ?? "";
            var isFullReturn = returnQuantity >= saleItem.Quantity;

            if (isFullReturn)
            {
                _unitOfWork.SaleItems.Delete(saleItem);
            }
            else
            {
                saleItem.Quantity -= returnQuantity;

                var returnComment = !string.IsNullOrEmpty(request.Comment)
                    ? request.Comment
                    : $"Qaytarildi: {returnQuantity} ({DateTime.UtcNow:dd.MM.yyyy HH:mm})";
                saleItem.Comment = !string.IsNullOrEmpty(originalComment)
                    ? $"{originalComment} | {returnComment}"
                    : returnComment;

                _unitOfWork.SaleItems.Update(saleItem);
            }

            // Restore stock for ordinary products only
            if (!saleItem.IsExternal && saleItem.Product != null)
            {
                saleItem.Product.Quantity += returnQuantity;
                _context.Products.Update(saleItem.Product);
            }

            // Save the SaleItem deletion/update so SUM-from-items sees the
            // post-return state, then recompute Sale.TotalAmount as the
            // authoritative SUM. Replaces the old `-= refundAmount`
            // arithmetic with the same drift-resistant pattern used by
            // Add/Remove SaleItem.
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await RecalculateSaleTotalAsync(sale, cancellationToken);

            // Adjust paid amount if overpaid
            if (sale.PaidAmount > sale.TotalAmount)
            {
                var overpaid = sale.PaidAmount - sale.TotalAmount;
                sale.PaidAmount = sale.TotalAmount;

                // Use the same payment type the customer actually paid with.
                // Hardcoding Cash here would (a) lie in the audit trail when the
                // original was Terminal/Click/Transfer, and (b) cause the cash
                // register deduction below to debit money that was never in it.
                // Pick the type that dominates the positive payments on this sale.
                var dominantType = sale.Payments
                    .Where(p => p.Amount > 0)
                    .GroupBy(p => p.PaymentType)
                    .OrderByDescending(g => g.Sum(p => p.Amount))
                    .Select(g => (PaymentType?)g.Key)
                    .FirstOrDefault() ?? PaymentType.Cash;

                var refundPayment = new Payment
                {
                    Id = Guid.NewGuid(),
                    SaleId = sale.Id,
                    PaymentType = dominantType,
                    Amount = -overpaid,
                    MarketId = marketId,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Payments.Add(refundPayment);

                // ONLY touch the cash register when the original payment was Cash.
                // Terminal/Click/Transfer/Credit refunds happen out-of-band (bank
                // reversal, platform refund) and never move physical till money.
                if (dominantType == PaymentType.Cash)
                {
                    var cashRegister = await _context.CashRegisters
                        .FirstOrDefaultAsync(cr => cr.MarketId == marketId, cancellationToken);
                    if (cashRegister != null)
                    {
                        cashRegister.CurrentBalance -= overpaid;
                        cashRegister.LastUpdated = DateTime.UtcNow;
                        _logger.LogInformation(
                            "Cash refunded on item return: SaleId={SaleId} Amount={Amount} NewBalance={Balance}",
                            sale.Id, overpaid, cashRegister.CurrentBalance);
                    }
                    else
                    {
                        _logger.LogWarning(
                            "No CashRegister for MarketId={MarketId} during return of sale {SaleId}; refund record kept but balance unchanged.",
                            marketId, sale.Id);
                    }
                }
            }

            // Sync the Debt record if one exists. Without this, returning items
            // from a debt-sale left the customer's debt frozen at the original
            // amount even though they actually owe less now (e.g. 100k debt
            // with 50k paid; return 20k of items → debt is now 30k, not 50k).
            var debt = (await _unitOfWork.Debts.FindAsync(
                d => d.SaleId == saleId && d.MarketId == marketId,
                cancellationToken)).FirstOrDefault();
            if (debt != null && debt.Status == DebtStatus.Open)
            {
                // Source of truth = sale.TotalAmount and PaidAmount (already
                // updated above). RemainingDebt = TotalAmount - PaidAmount.
                var newRemaining = Math.Max(0m, sale.TotalAmount - sale.PaidAmount);
                debt.RemainingDebt = newRemaining;
                // Reduce TotalDebt proportionally so reports show the
                // adjusted debt amount, not the historic original.
                debt.TotalDebt = Math.Max(0m, debt.TotalDebt - refundAmount);
                if (newRemaining <= 0)
                {
                    debt.Status = DebtStatus.Closed;
                    _logger.LogInformation(
                        "Debt auto-closed by return: SaleId={SaleId} (full return covered remaining debt)",
                        sale.Id);
                }
                _unitOfWork.Debts.Update(debt);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            if (!isFullReturn && saleItem != null)
            {
                string productName;
                string unit = "";

                if (!saleItem.IsExternal)
                {
                    productName = saleItem.Product?.Name ?? "Unknown";
                    unit = saleItem.Product?.GetUnitName() ?? "";
                }
                else
                {
                    productName = saleItem.ExternalProductName ?? "Unknown";
                    unit = "";
                }

                return new SaleItemDto(
                    saleItem.Id.ToString(),
                    saleItem.SaleId.ToString(),
                    saleItem.ProductId,
                    productName,
                    saleItem.Quantity,
                    saleItem.IsExternal ? saleItem.ExternalCostPrice : saleItem.CostPrice,
                    saleItem.SalePrice,
                    saleItem.TotalPrice,
                    (saleItem.SalePrice - (saleItem.IsExternal ? saleItem.ExternalCostPrice : saleItem.CostPrice)) * saleItem.Quantity,
                    unit,
                    saleItem.Comment,
                    saleItem.IsExternal
                );
            }

            return null;
        }, cancellationToken);
    }

    /// <summary>
    /// Gets list of debtors
    /// </summary>
    public async Task<IEnumerable<CustomerDto>> GetDebtorsAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var debts = await _unitOfWork.Debts.FindAsync(
            d => d.MarketId == marketId && d.Status == DebtStatus.Open,
            cancellationToken,
            includeProperties: "Customer");

        var customers = debts
            .Where(d => d.Customer != null)
            .Select(d => new CustomerDto(
                d.Customer!.Id,
                d.Customer!.Phone ?? "",
                d.Customer!.FullName,
                d.Customer!.Comment,
                d.RemainingDebt
            ))
            .Distinct()
            .ToList();

        return customers;
    }
}
