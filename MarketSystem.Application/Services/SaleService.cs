using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class SaleService : ISaleService
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
        var sales = await _context.Sales
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.MarketId == marketId)
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
            s.SaleItems.Select(si => MapSaleItemToDto(si, si.Product?.Name ?? "Unknown")).ToList(),
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
        var sales = await _context.Sales
            .Include(s => s.Seller)
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.MarketId == marketId && s.CreatedAt >= start && s.CreatedAt <= end)
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
            s.SaleItems.Select(si => MapSaleItemToDto(si, si.Product?.Name ?? "Unknown")).ToList(),
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
            s.SaleItems.Select(si => MapSaleItemToDto(si, si.Product?.Name ?? "Unknown")).ToList(),
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
            s.SaleItems.Select(si => MapSaleItemToDto(si, si.Product?.Name ?? "Unknown")).ToList(),
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
            await ApplyCustomerCreditAsync(sale.Id, request.CustomerId.Value, cancellationToken);
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
            await ApplyCustomerCreditAsync(saleId, request.CustomerId.Value, cancellationToken);
        }

        return await MapToDtoAsync(sale, cancellationToken);
    }

    public async Task<SaleItemDto?> AddSaleItemAsync(Guid saleId, AddSaleItemDto request, CancellationToken cancellationToken = default)
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

            // Load sale items separately
            var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == saleId, cancellationToken);

            var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId, cancellationToken);
            if (product is null)
                throw new InvalidOperationException("Product not found");

            // SECURITY: Verify product belongs to the same market as the sale
            if (product.MarketId != sale.MarketId)
                throw new InvalidOperationException("Product does not belong to this market");

            // Validate stock
            if (product.Quantity < request.Quantity)
                throw new InvalidOperationException($"Insufficient stock. Available: {product.Quantity}, Requested: {request.Quantity}");

            // Note: MinSalePrice validation is now UI-only warning, not enforced on backend
            // Sellers can sell below minimum price without comment if needed

            // Check threshold
            if (product.Quantity <= product.MinThreshold)
            {
                // Log warning - product is at or below threshold
                // This is allowed but should trigger warning in UI
            }

            SaleItem? resultSaleItem;
            decimal itemTotal;

            // CHECK: Is this product already in the sale?
            var existingItem = saleItems.FirstOrDefault(si => si.ProductId == request.ProductId);

            if (existingItem != null)
            {
                // Product exists - UPDATE existing item
                var oldQuantity = existingItem.Quantity;
                existingItem.Quantity += request.Quantity;
                // Keep the original sale price (or could use weighted average)
                // existingItem.SalePrice = existingItem.SalePrice; // Keep original price

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

            return MapSaleItemToDto(resultSaleItem, product.Name);
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

            // Get product
            var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId, cancellationToken);
            if (product is null)
                throw new InvalidOperationException("Product not found");

            // SECURITY: Verify product belongs to the same market as the sale
            if (product.MarketId != sale.MarketId)
                throw new InvalidOperationException("Product does not belong to this market");

            SaleItem? resultSaleItem;
            decimal itemTotal;

            if (request.Quantity == 0 || request.Quantity >= saleItem.Quantity)
            {
                // Remove entire item from sale
                _unitOfWork.SaleItems.Delete(saleItem);

                // Restore full stock
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

                // Restore partial stock
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

            return MapSaleItemToDto(resultSaleItem, product.Name);
        }, cancellationToken);
    }

    public async Task<PaymentDto?> AddPaymentAsync(Guid saleId, AddPaymentDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        
        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // CRITICAL FIX: Get sale WITH items to ensure TotalAmount is calculated
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

            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                SaleId = saleId,
                PaymentType = Enum.Parse<PaymentType>(request.PaymentType, true),
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
                            MarketId = sale.MarketId  // Multi-tenancy - inherit from Sale
                        };
                        await _unitOfWork.Debts.AddAsync(newDebt, cancellationToken);
                    }
                    else
                    {
                        existingDebt.RemainingDebt = sale.TotalAmount - sale.PaidAmount;
                        _unitOfWork.Debts.Update(existingDebt);
                    }
                }
                // Mijozsiz savdo uchun debt record yaratilmaydi, lekin status "debt" bo'ladi
            }
            // 3. TotalAmount 0 bo'lsa (hali mahsulotlar qo'shilgan yo'q), status Draft da qoladi
            else if (sale.TotalAmount == 0)
            {
                _logger.LogInformation("Sale {SaleId} has TotalAmount=0, keeping Draft status", saleId);
                // Status remains Draft - mahsulotlar qo'shilganda TotalAmount hisoblanadi
            }
            else
            {
                _logger.LogWarning("Unhandled case for sale {SaleId}: TotalAmount={TotalAmount}, PaidAmount={PaidAmount}",
                    sale.Id, sale.TotalAmount, sale.PaidAmount);
            }

            _logger.LogInformation("Sale {SaleId} final status: {Status}", sale.Id, sale.Status);

            // Explicitly update sale in unit of work
            _unitOfWork.Sales.Update(sale);

            _logger.LogInformation("Sale {SaleId} updated: Status={Status}, PaidAmount={Paid}, TotalAmount={Total}",
                saleId, sale.Status, sale.PaidAmount, sale.TotalAmount);

            // Use DbContext to explicitly mark sale as modified
            _context.Entry(sale).State = EntityState.Modified;
            await _unitOfWork.SaveChangesAsync(cancellationToken);

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
                var products = await _unitOfWork.Products.FindAsync(
                    p => p.Id == item.ProductId && p.MarketId == marketId,
                    cancellationToken);
                var product = products.FirstOrDefault();

                if (product != null)
                {
                    product.Quantity += item.Quantity;
                    _context.Entry(product).State = EntityState.Modified;
                    _unitOfWork.Products.Update(product);
                }
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

        // Get the sale to verify market
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
    private async Task ApplyCustomerCreditAsync(Guid saleId, Guid customerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Get available credit for the customer
        var availableCredit = await _customerService.GetAvailableCreditAsync(customerId, cancellationToken);

        if (availableCredit <= 0)
            return; // No credit available

        // Get the sale
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

        // Apply the credit to the sale
        // IMPORTANT: DO NOT create a payment record for credit application
        // Creating a payment would cause it to be counted in reports as "paid sales"
        // even though it's just a credit transfer, not actual revenue
        sale.PaidAmount += creditToApply;

        _context.Sales.Update(sale);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Credit applied successfully: SaleId={SaleId}, NewPaidAmount={NewPaidAmount}",
            saleId, sale.PaidAmount);
    }

    private async Task<SaleDto> MapToDtoAsync(Sale sale, CancellationToken cancellationToken)
    {
        // Get sale items
        var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == sale.Id, cancellationToken);
        var itemsDto = new List<SaleItemDto>();

        foreach (var item in saleItems)
        {
            // Get product and verify it belongs to the same market as the sale
            var products = await _unitOfWork.Products.FindAsync(
                p => p.Id == item.ProductId && p.MarketId == sale.MarketId,
                cancellationToken);
            var product = products.FirstOrDefault();

            itemsDto.Add(MapSaleItemToDto(item, product?.Name ?? "Unknown"));
        }

        // Get payments
        var payments = await _unitOfWork.Payments.FindAsync(p => p.SaleId == sale.Id, cancellationToken);
        var paymentsDto = payments.Select(p => new PaymentDto(
            p.Id,
            p.PaymentType.ToString().ToLowerInvariant(),
            p.Amount,
            p.CreatedAt,
            null, // SaleStatus not applicable in this context
            null, // SalePaidAmount not applicable
            null  // SaleTotalAmount not applicable
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

    private static SaleItemDto MapSaleItemToDto(SaleItem item, string productName)
    {
        return new SaleItemDto(
            item.Id.ToString(),
            item.SaleId.ToString(),
            item.ProductId,
            productName,
            item.Quantity,
            item.CostPrice,
            item.SalePrice,
            item.TotalPrice,  // Property from entity
            item.Profit,      // Property from entity
            "", // TODO: Get unit from product
            item.Comment
        );
    }

    public async Task<SaleItemDto?> UpdateSaleItemPriceAsync(UpdateSaleItemPriceDto request, Guid userId, string userRole, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Validation
        if (request.NewPrice <= 0)
            throw new InvalidOperationException("Narx 0 yoki manfiy bo'lishi mumkin emas");

        // Comment is optional for price update
        // if (string.IsNullOrWhiteSpace(request.Comment))
        //     throw new InvalidOperationException("Izoh (comment) majburiy");

        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
        {
            // Parse saleItemId from string to Guid
            var saleItemGuid = Guid.Parse(request.SaleItemId);

            // Get SaleItem with Sale and Debt
            var saleItems = await _unitOfWork.SaleItems.FindAsync(
                si => si.Id == saleItemGuid,
                cancellationToken,
                includeProperties: "Sale");

            var saleItem = saleItems.FirstOrDefault();
            if (saleItem == null)
                throw new InvalidOperationException("SaleItem topilmadi");

            var sale = saleItem.Sale;
            if (sale == null || sale.MarketId != marketId)
                throw new InvalidOperationException("Sotuv topilmadi");

            // Check if debt exists and get its status
            Debt? debt = null;
            if (sale.CustomerId.HasValue)
            {
                var debts = await _unitOfWork.Debts.FindAsync(
                    d => d.SaleId == sale.Id && d.MarketId == marketId,
                    cancellationToken);
                debt = debts.FirstOrDefault();
            }

            // Role-based authorization
            if (debt != null && debt.Status == DebtStatus.Closed)
            {
                // Only Owner and Admin can edit closed debts
                if (userRole != "Owner" && userRole != "Admin")
                {
                    throw new UnauthorizedAccessException("Yopilgan qarzni tahrirlash huquqi yo'q (faqat Owner/Admin)");
                }
            }

            // Store old price
            var oldPrice = saleItem.SalePrice;

            // Update SaleItem price
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

            var oldTotalAmount = sale.TotalAmount;
            sale.TotalAmount = newTotalAmount;
            _unitOfWork.Sales.Update(sale);

            // Recalculate Debt if exists
            if (debt != null)
            {
                var oldTotalDebt = debt.TotalDebt;
                debt.TotalDebt = newTotalAmount;
                debt.RemainingDebt = newTotalAmount - sale.PaidAmount;
                _unitOfWork.Debts.Update(debt);

                _logger.LogInformation($"Debt {debt.Id} recalculated: {oldTotalDebt} -> {newTotalAmount}");
            }

            // Create audit log
            var auditLog = new DebtAuditLog
            {
                Id = Guid.NewGuid(),
                SaleId = sale.Id,
                SaleItemId = saleItem.Id,
                OldPrice = oldPrice,
                NewPrice = request.NewPrice,
                ChangedByUserId = userId,
                Comment = request.Comment ?? "Narx o'zgartirildi",
                MarketId = marketId,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.DebtAuditLogs.AddAsync(auditLog, cancellationToken);

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitTransactionAsync(cancellationToken);

            _logger.LogInformation($"SaleItem {saleItem.Id} price updated: {oldPrice} -> {request.NewPrice} by User {userId}");

            // Get product name for response
            var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId, cancellationToken);

            return MapSaleItemToDto(saleItem, product?.Name ?? "Unknown");
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            throw;
        }
    }

    public async Task<SaleDto?> DeleteSaleAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("=== DELETE SALE DEBUG ===");
        _logger.LogInformation("Sale ID: {SaleId}", saleId);
        _logger.LogInformation("===========================");

        var marketId = _currentMarketService.GetCurrentMarketId();

        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.Id == saleId && s.MarketId == marketId,
            cancellationToken);

        var sale = sales.FirstOrDefault();

        if (sale is null)
        {
            _logger.LogWarning("Sale not found: {SaleId}", saleId);
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            return null;
        }

        // Faqat Draft va Paid statusdagi savdolarni o'chirish mumkin
        // Debt statusdagi savdolarni o'chirish mumkin emas, chunki ularda qarz bor
        // Closed va Cancelled statusdagi savdolarni ham o'chirish mumkin emas
        if (sale.Status != SaleStatus.Draft && sale.Status != SaleStatus.Paid)
        {
            _logger.LogWarning("Sale cannot be deleted: {SaleId}, Status: {Status}", saleId, sale.Status);
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            throw new InvalidOperationException("Faqat draft yoki to'langan (Paid) savdolarini o'chirish mumkin! Qarzli savdolarni o'chirib bo'lmaydi.");
        }

        // Sale items ni o'chirish (cascade delete bo'lishi kerak)
        var saleItems = await _unitOfWork.SaleItems.FindAsync(
            si => si.SaleId == saleId,
            cancellationToken
        );

        foreach (var saleItem in saleItems)
        {
            _unitOfWork.SaleItems.Delete(saleItem);
            _logger.LogInformation("SaleItem deleted: {SaleItemId}, Product: {ProductId}, Qty: {Quantity}",
                saleItem.Id, saleItem.ProductId, saleItem.Quantity);

            // Mahsulotni qaytarib olish (stock ni qaytarish)
            var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId, cancellationToken);
            if (product != null)
            {
                product.Quantity += saleItem.Quantity;
                _unitOfWork.Products.Update(product);
                _logger.LogInformation("Product stock restored: {ProductId}, Qty: +{Quantity}",
                    product.Id, saleItem.Quantity);
            }
        }

        // Savdoni o'chirish
        _unitOfWork.Sales.Delete(sale);
        _logger.LogInformation("Sale deleted: {SaleId}", saleId);

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        await _unitOfWork.CommitTransactionAsync(cancellationToken);

        _logger.LogInformation("=== DELETE SALE SUCCESS ===");

        return await MapToDtoAsync(sale, cancellationToken);
    }

    public async Task<IEnumerable<DebtorDto>> GetDebtorsAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Barcha Debt statusdagi savdolarni olish
        var debtSales = await _context.Sales
            .Include(s => s.Customer)
            .Include(s => s.SaleItems)
                .ThenInclude(si => si.Product)
            .Include(s => s.Payments)
            .Where(s => s.MarketId == marketId && s.Status == SaleStatus.Debt && s.CustomerId != null)
            .OrderByDescending(s => s.CreatedAt)
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        // Mijoz bo'yicha guruhlash
        var debtorGroups = debtSales
            .GroupBy(s => s.CustomerId)
            .Select(group => new DebtorDto(
                group.Key!.Value,
                group.First().Customer?.FullName,
                group.First().Customer?.Phone,
                group.Sum(s => s.TotalAmount), // Total debt (jami summa)
                group.Sum(s => s.PaidAmount),  // Paid amount (to'langan)
                group.Sum(s => s.TotalAmount - s.PaidAmount), // Remaining debt (qolgan qarz)
                group.Count(), // Debt count (nechta savdo)
                group.Min(s => s.CreatedAt), // Eng eski qarz sanasi
                group.Select(s => new SaleDto(
                    s.Id,
                    s.SellerId,
                    null, // SellerName - kerak emas
                    s.CustomerId,
                    s.Customer?.FullName,
                    s.Customer?.Phone,
                    s.Status.ToString(),
                    s.TotalAmount,
                    s.PaidAmount,
                    s.TotalAmount - s.PaidAmount,
                    s.CreatedAt,
                    s.SaleItems.Select(si => MapSaleItemToDto(si, si.Product?.Name ?? "Unknown")).ToList(),
                    s.Payments.Select(p => new PaymentDto(
                        p.Id,
                        p.PaymentType.ToString(),
                        p.Amount,
                        p.CreatedAt,
                        null,
                        null,
                        null
                    )).ToList()
                )).ToList()
            ))
            .OrderByDescending(d => d.OldestDebtDate)
            .ToList();

        return debtorGroups;
    }

    public async Task<SaleItemDto?> ReturnSaleItemAsync(Guid saleId, ReturnSaleItemRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var marketId = _currentMarketService.GetCurrentMarketId();

            _logger.LogInformation("=== RETURN SALE ITEM START ===");
            _logger.LogInformation("SaleId: {SaleId}, SaleItemId: {SaleItemId}, Quantity: {Quantity}, Comment: {Comment}",
                saleId, request.SaleItemId, request.Quantity, request.Comment);

            // Savdo va sale itemni topish
            var sale = await _context.Sales
                .Include(s => s.SaleItems)
                    .ThenInclude(si => si.Product)
                .Include(s => s.Payments)
                .FirstOrDefaultAsync(s => s.Id == saleId && s.MarketId == marketId, cancellationToken);

            if (sale == null)
            {
                _logger.LogWarning("Sale not found: {SaleId}", saleId);
                return null;
            }

            var saleItem = sale.SaleItems.FirstOrDefault(si => si.Id.ToString() == request.SaleItemId);
            if (saleItem == null)
            {
                _logger.LogWarning("Sale item not found: {SaleItemId}", request.SaleItemId);
                return null;
            }

            if (request.Quantity <= 0 || request.Quantity > saleItem.Quantity)
            {
                _logger.LogWarning("Invalid return quantity: {Quantity}, Item quantity: {ItemQuantity}",
                    request.Quantity, saleItem.Quantity);
                return null;
            }

            var returnQuantity = request.Quantity;
            var refundAmount = returnQuantity * saleItem.SalePrice;

            _logger.LogInformation("Return Amount: {RefundAmount}, Sale Price: {SalePrice}, Return Qty: {ReturnQty}",
                refundAmount, saleItem.SalePrice, returnQuantity);

            // Execute in transaction with execution strategy
            return await _unitOfWork.ExecuteInTransactionAsync<SaleItemDto?>(async () =>
            {
                // 1. Sale item quantity yangilash yoki o'chirish
                string originalComment = saleItem.Comment ?? "";
                var originalQuantity = saleItem.Quantity; // Saqlab qo'yymiz
                var isFullReturn = returnQuantity >= saleItem.Quantity;

                if (isFullReturn)
                {
                    // To'liq qaytarish - itemni o'chirish
                    _logger.LogInformation("Full return: Removing item completely. OriginalQty={OriginalQty}, ReturnQty={ReturnQty}",
                        originalQuantity, returnQuantity);
                    _context.SaleItems.Remove(saleItem);
                }
                else
                {
                    // Qisman qaytarish - quantity kamaytirish
                    _logger.LogInformation("Partial return: OldQty={OldQty}, ReturnQty={ReturnQty}, NewQty={NewQty}",
                        saleItem.Quantity, returnQuantity, saleItem.Quantity - returnQuantity);
                    saleItem.Quantity -= returnQuantity;  // ✅ DECIMAL

                    // Izohga qaytarish haqida yozish
                    var returnComment = !string.IsNullOrEmpty(request.Comment)
                        ? request.Comment
                        : $"Qaytarildi: {returnQuantity} ({DateTime.UtcNow:dd.MM.yyyy HH:mm})";
                    saleItem.Comment = !string.IsNullOrEmpty(originalComment)
                        ? $"{originalComment} | {returnComment}"
                        : returnComment;
                }

                // 2. Mahsulot stock'iga qaytarish
                if (saleItem.Product != null)
                {
                    var oldStock = saleItem.Product.Quantity;
                    saleItem.Product.Quantity += returnQuantity;  // ✅ DECIMAL
                    _context.Products.Update(saleItem.Product);
                    _logger.LogInformation("Product stock updated: ProductId={ProductId}, OldStock={OldStock}, NewStock={NewStock}",
                        saleItem.ProductId, oldStock, saleItem.Product.Quantity);
                }

                // 3. Savdo summalarini yangilash
                var oldTotalAmount = sale.TotalAmount;
                sale.TotalAmount -= refundAmount;

                _logger.LogInformation("Sale total updated: SaleId={SaleId}, OldTotal={OldTotal}, NewTotal={NewTotal}",
                    saleId, oldTotalAmount, sale.TotalAmount);

                // 4. To'langan summani tartibga solish (Negative debt va xato balans paydo bo'lmasligi u.n)
                if (sale.PaidAmount > sale.TotalAmount)
                {
                    var overpaid = sale.PaidAmount - sale.TotalAmount;
                    _logger.LogInformation("PaidAmount ({PaidAmount}) exceeds NewTotal ({NewTotal}). Adjusting PaidAmount to {NewTotal} & refunding {Overpaid}.", 
                        sale.PaidAmount, sale.TotalAmount, sale.TotalAmount, overpaid);
                    
                    sale.PaidAmount = sale.TotalAmount;

                    // Balans (hisobotlarda) to'g'ri chiqishi uchun manfiy payment qayd etiladi
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

                    // Kassadan pulni ham yechib olish va tarixga yozish
                    var cashRegister = await _context.CashRegisters.FirstOrDefaultAsync(cancellationToken);
                    if (cashRegister != null)
                    {
                        cashRegister.CurrentBalance -= overpaid; // Kassadagi pulni ham qaytarish
                        cashRegister.LastUpdated = DateTime.UtcNow;
                        _context.CashRegisters.Update(cashRegister);
                    }

                    // Tizimda chiqim sifatida "-5000" tushishi uchun manfiy kiritiladi yoki commentga yoziladi
                    var withdrawal = new CashWithdrawal
                    {
                        Id = Guid.NewGuid(),
                        Amount = -overpaid, // Mijoz "pul olish tarixiga -5000 qo'shib qo'y" degani uchun
                        Comment = $"Mahsulot qaytarilgani sababli mijozga qaytarildi (Savdo: {sale.Id})",
                        WithdrawalDate = DateTime.UtcNow,
                        UserId = null,  // Tizim tomonidan qilingan avtomatik qaytarish
                        WithdrawType = "cash"
                    };
                    _context.CashWithdrawals.Add(withdrawal);
                }

                // 5. Status yangilash
                var oldStatus = sale.Status;

                if (sale.TotalAmount == 0 || sale.SaleItems.Count == 0)
                {
                    sale.Status = SaleStatus.Closed;
                }
                else if (sale.PaidAmount < sale.TotalAmount)
                {
                    sale.Status = SaleStatus.Debt;
                }
                else
                {
                    sale.Status = SaleStatus.Paid;
                }

                _logger.LogInformation("Sale status: SaleId={SaleId}, OldStatus={OldStatus}, NewStatus={NewStatus}",
                    saleId, oldStatus, sale.Status);

                // 6. DEBT JADVALINI YANGILASH
                if (sale.CustomerId.HasValue)
                {
                    var existingDebt = await _context.Debts
                        .FirstOrDefaultAsync(d => d.SaleId == saleId && d.MarketId == marketId, cancellationToken);

                    if (existingDebt != null)
                    {
                        var newRemainingDebt = sale.TotalAmount - sale.PaidAmount;
                        existingDebt.TotalDebt = sale.TotalAmount;
                        existingDebt.RemainingDebt = newRemainingDebt > 0 ? newRemainingDebt : 0;
                        existingDebt.Status = newRemainingDebt > 0 ? DebtStatus.Open : DebtStatus.Closed;

                        _context.Debts.Update(existingDebt);
                    }
                }

                // Explicitly update sale
                _context.Sales.Update(sale);

                await _context.SaveChangesAsync(cancellationToken);

                _logger.LogInformation("=== RETURN SALE ITEM SUCCESS ===");
                
                // Updated sale item ni qaytarish (faqat partial return bo'lsa)
                if (!isFullReturn && saleItem != null)
                {
                    return MapSaleItemToDto(saleItem, saleItem.Product?.Name ?? "Unknown");
                }

                return null;
            }, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error returning sale item");
            throw;
        }
    }

    /// <summary>
    /// Applies customer's available credit (from negative payments/refunds) to a sale.
    /// This is a public method that can be called manually to apply credit to an existing sale.
    /// </summary>
    public async Task<SaleDto?> ApplyCustomerCreditAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Get the sale
        var sale = await _context.Sales
            .FirstOrDefaultAsync(s => s.Id == saleId && s.MarketId == marketId, cancellationToken);

        if (sale == null)
            return null;

        if (!sale.CustomerId.HasValue)
        {
            _logger.LogWarning("Cannot apply credit: Sale {SaleId} has no customer", saleId);
            return null;
        }

        await ApplyCustomerCreditAsync(saleId, sale.CustomerId.Value, cancellationToken);

        return await MapToDtoAsync(sale, cancellationToken);
    }

    public async Task<SaleDto?> MarkSaleAsDebtAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        try
        {
            // Get sale with items
            var sale = await _unitOfWork.Sales.GetWithItemsAsync(saleId, cancellationToken);

            if (sale is null)
                throw new InvalidOperationException("Sale not found");

            if (sale.MarketId != marketId)
                throw new InvalidOperationException("Sale not found in current market");

            if (sale.Status != SaleStatus.Draft)
                throw new InvalidOperationException($"Only Draft sales can be marked as Debt. Current status: {sale.Status}");

            if (!sale.CustomerId.HasValue || sale.CustomerId.Value == Guid.Empty)
                throw new InvalidOperationException("Cannot mark sale as Debt without a customer");

            // Recalculate TotalAmount from SaleItems
            decimal calculatedTotal = sale.SaleItems?.Sum(si => si.SalePrice * si.Quantity) ?? 0;

            if (calculatedTotal == 0)
                throw new InvalidOperationException("Cannot mark sale as Debt with zero total amount");

            // Update sale
            sale.TotalAmount = calculatedTotal;
            var oldStatus = sale.Status;
            sale.Status = SaleStatus.Debt;

            _logger.LogInformation("=== MARK SALE AS DEBT ===");
            _logger.LogInformation("Sale ID: {SaleId}", saleId);
            _logger.LogInformation("Old Status: {OldStatus}, New Status: {NewStatus}", oldStatus, sale.Status);
            _logger.LogInformation("Total Amount: {Total}", calculatedTotal);
            _logger.LogInformation("Customer ID: {CustomerId}", sale.CustomerId);

            _unitOfWork.Sales.Update(sale);

            // Create debt record
            var newDebt = new Debt
            {
                Id = Guid.NewGuid(),
                SaleId = saleId,
                CustomerId = sale.CustomerId.Value,
                TotalDebt = sale.TotalAmount,
                RemainingDebt = sale.TotalAmount - sale.PaidAmount, // Should be full amount since PaidAmount = 0
                Status = DebtStatus.Open,
                MarketId = sale.MarketId
            };
            await _unitOfWork.Debts.AddAsync(newDebt, cancellationToken);

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("=== SALE SAVED TO DATABASE ===");
            _logger.LogInformation("Sale {SaleId} marked as Debt. Total: {Total}, Customer: {CustomerId}",
                saleId, sale.TotalAmount, sale.CustomerId);

            return await MapToDtoAsync(sale, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking sale as Debt");
            throw;
        }
    }
}
