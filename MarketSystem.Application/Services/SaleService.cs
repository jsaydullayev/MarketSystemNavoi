using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public partial class SaleService : ISaleService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditLogService _auditLogService;
    private readonly AppDbContext _context;
    private readonly ILogger<SaleService> _logger;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly ICustomerService _customerService;

    public SaleService(IUnitOfWork unitOfWork, IAuditLogService auditLogService, AppDbContext context, ILogger<SaleService> logger, ICurrentMarketService currentMarketService, ICustomerService customerService)
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

    public async Task<IEnumerable<SaleDto>> GetAllSalesAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ✅ OPTIMIZED: Single query with eager loading - no N+1 problem
        // ✅ FIX: Add Distinct() to prevent duplicate sales from being returned
        var sales = await _context.Sales
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.MarketId == marketId)
            .OrderByDescending(s => s.CreatedAt)
            .Distinct()
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        return sales.Select(s => new SaleDto(
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
            s.SaleItems.Select(si => {
                // ✅ ISEXTERNAL SHARTI - Product name olish
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
        ));
    }

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
            .Distinct()
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        return sales.Select(s => new SaleDto(
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
            s.SaleItems.Select(si => {
                // ✅ ISEXTERNAL SHARTI - Product name olish
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
        ));
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

        return sales.Select(s => new SaleDto(
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
            s.SaleItems.Select(si => {
                // ✅ ISEXTERNAL SHARTI - Product name olish
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
        ));
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

        return sales.Select(s => new SaleDto(
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
            s.SaleItems.Select(si => {
                // ✅ ISEXTERNAL SHARTI - Product name olish
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
        ));
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

        // Audit log (temporarily disabled for testing)
        // await _auditLogService.LogSaleActionAsync(sale.Id, "Create", sellerId, cancellationToken);

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

                    // LOG: New item create
                    _logger.LogInformation("[AddSaleItem] CREATE NEW - Quantity: {Quantity}, ProductId: {ProductId}",
                        saleItem.Quantity, saleItem.ProductId);

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

                    // LOG: Existing item update
                    _logger.LogInformation("[AddSaleItem] UPDATE EXTERNAL - OldQty: {OldQty}, RequestQty: {RequestQty}, NewQty: {NewQty}",
                        oldQuantity, request.Quantity, existingItem.Quantity);

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

                    // LOG: New item create
                    _logger.LogInformation("[AddSaleItem] CREATE EXTERNAL - Quantity: {Quantity}, ProductName: {ProductName}",
                        saleItem.Quantity, request.ExternalProductName);

                    await _unitOfWork.SaleItems.AddAsync(saleItem, cancellationToken);

                    // ✅ NO STOCK UPDATE - Tashqi mahsulotlar ombor qoldig'iga ta'sir qilmaydi

                    // Update sale total
                    itemTotal = request.Quantity * request.SalePrice;
                    sale.TotalAmount += itemTotal;
                    _unitOfWork.Sales.Update(sale);

                    resultSaleItem = saleItem;
                }

                await _unitOfWork.SaveChangesAsync(cancellationToken);

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
                    _context.Entry(product).State = EntityState.Modified;
                    _unitOfWork.Products.Update(product);

                    // Update sale total
                    itemTotal = saleItem.Quantity * saleItem.SalePrice;
                    sale.TotalAmount -= itemTotal;
                    _unitOfWork.Sales.Update(sale);

                    resultSaleItem = saleItem; // Return deleted item info
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
                    saleItem,
                    saleItem.ExternalProductName ?? "Unknown",
                    ""
                );
            }
        }, cancellationToken);
    }

    public async Task<PaymentDto?> AddPaymentAsync(Guid saleId, AddPaymentDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // ✅ CRITICAL FIX: Get sale WITH items to ensure TotalAmount is calculated
            var sale = await _unitOfWork.Sales.GetWithItemsAsync(saleId, cancellationToken);

            if (sale is null)
                throw new InvalidOperationException("Sale not found");

            // Verify market ownership for multi-tenancy
            if (sale.MarketId != marketId)
                throw new InvalidOperationException("Sale not found in current market");

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

            // ✅ NEW: Update cash register balance for cash payments
            if (payment.PaymentType == PaymentType.Cash)
            {
                var cashRegister = await _context.CashRegisters
                    .OrderByDescending(cr => cr.LastUpdated)
                    .FirstOrDefaultAsync(cancellationToken);

                if (cashRegister != null)
                {
                    cashRegister.CurrentBalance += request.Amount;
                    cashRegister.LastUpdated = DateTime.UtcNow;
                    _context.CashRegisters.Update(cashRegister);
                }
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
                _logger.LogInformation("Sale {SaleId} is fully paid, setting status to Paid", saleId);
                sale.Status = SaleStatus.Paid;

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
            _context.Entry(sale).State = EntityState.Modified;
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
    public async Task<SaleDto?> CancelSaleAsync(Guid saleId, string adminId, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("=== CANCEL SALE DEBUG ===");
        _logger.LogInformation("Sale ID: {SaleId}", saleId);
        _logger.LogInformation("Admin ID (string): {AdminId}", adminId);
        _logger.LogInformation("===========================");

        // Parse adminId from string to Guid
        if (!Guid.TryParse(adminId, out var adminGuid))
        {
            _logger.LogWarning("Invalid Admin ID format: {AdminId}", adminId);
            throw new InvalidOperationException("Invalid Admin ID format");
        }

        _logger.LogInformation("Admin ID (parsed): {AdminGuid}", adminGuid);

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

            // Restore stock for all items
            var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == saleId, cancellationToken);
            foreach (var item in saleItems)
            {
                /// <summary>
                /// ============================================
                /// ✅ ISEXTERNAL SHARTI - STOKNI QAYTARISH
                /// ============================================
                /// </summary>
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

            // Update sale status
            sale.Status = SaleStatus.Cancelled;
            _unitOfWork.Sales.Update(sale);

            // Close associated debt if exists
            if (sale.Debt != null && sale.Debt.Status == DebtStatus.Open)
            {
                sale.Debt.Status = DebtStatus.Closed;
                _unitOfWork.Debts.Update(sale.Debt);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // Audit log
            await _auditLogService.LogSaleActionAsync(saleId, "Cancel", adminGuid, cancellationToken);

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
    /// Applies customer's available credit (from negative payments/refunds) to a sale.
    /// This is called when a customer is associated with a sale or when finalizing a sale.
    /// </summary>
    private async Task ApplyCustomerCreditInternalAsync(Guid saleId, Guid customerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Get available credit for customer
        var availableCredit = await _customerService.GetAvailableCreditAsync(customerId, cancellationToken);

        if (availableCredit <= 0)
            return; // No credit available

        // Get sale
        var sale = await _context.Sales
            .Include(s => s.Payments)
            .FirstOrDefaultAsync(s => s.Id == saleId && s.MarketId == marketId, cancellationToken);

        if (sale == null)
            return;

        // Calculate how much credit can be applied (cannot exceed TotalAmount - PaidAmount)
        var creditToApply = Math.Min(availableCredit, sale.TotalAmount - sale.PaidAmount);

        if (creditToApply <= 0)
            return; // No credit can be applied (either sale already fully paid or TotalAmount is 0)

        _logger.LogInformation("Applying customer credit: SaleId={SaleId}, CustomerId={CustomerId}, CreditToApply={CreditToApply}, AvailableCredit={AvailableCredit}",
            saleId, customerId, creditToApply, availableCredit);

        // Apply credit to sale
        // IMPORTANT: DO NOT create a payment record for credit application
        // Creating a payment would cause it to be counted in reports as "paid sales"
        // even though it's just a credit transfer, not actual revenue
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
            .Select(si => si.ProductId.Value)
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
                // Oddiy mahsulot - Product table'dan nomini olish
                if (products.TryGetValue(item.ProductId.Value, out var product))
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
        _logger.LogInformation("=== DELETE SALE DEBUG ===");
        _logger.LogInformation("Sale ID: {SaleId}", saleId);
        _logger.LogInformation("===========================");

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
                    _context.Entry(saleItem.Product).State = EntityState.Modified;
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

            foreach (var payment in payments)
            {
                _context.Payments.Remove(payment);
                _logger.LogInformation("Payment deleted: {PaymentId}", payment.Id);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("=== DELETE SALE SUCCESS ===");

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
                    si.Profit,
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

            // Update SaleItem price
            var oldPrice = saleItem.SalePrice;
            saleItem.SalePrice = request.NewPrice;
            _unitOfWork.SaleItems.Update(saleItem);

            // Recalculate Sale.TotalAmount
            var allSaleItems = await _unitOfWork.SaleItems.FindAsync(
                si => si.SaleId == sale.Id,
                cancellationToken);
            var newTotalAmount = 0m;
            foreach (var item in allSaleItems)
            {
                newTotalAmount += item.SalePrice * item.Quantity;
            }
            sale.TotalAmount = newTotalAmount;
            _unitOfWork.Sales.Update(sale);

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
                saleItem.Profit,
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

            // Update sale total
            sale.TotalAmount -= refundAmount;
            _context.Sales.Update(sale);

            // Adjust paid amount if overpaid
            if (sale.PaidAmount > sale.TotalAmount)
            {
                var overpaid = sale.PaidAmount - sale.TotalAmount;
                sale.PaidAmount = sale.TotalAmount;

                var refundPayment = new Payment
                {
                    Id = Guid.NewGuid(),
                    SaleId = sale.Id,
                    PaymentType = PaymentType.Cash,
                    Amount = -overpaid,
                    MarketId = marketId,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Payments.Add(refundPayment);
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
                    saleItem.Profit,
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
