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

    public SaleService(IUnitOfWork unitOfWork, IAuditLogService auditLogService, AppDbContext context, ILogger<SaleService> logger, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _auditLogService = auditLogService;
        _context = context;
        _logger = logger;
        _currentMarketService = currentMarketService;
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

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.MarketId == marketId,
            cancellationToken);

        var result = new List<SaleDto>();

        foreach (var sale in sales)
        {
            result.Add(await MapToDtoAsync(sale, cancellationToken));
        }

        return result;
    }

    public async Task<IEnumerable<SaleDto>> GetSalesByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.MarketId == marketId && s.CreatedAt >= start && s.CreatedAt <= end,
            cancellationToken);

        var result = new List<SaleDto>();
        foreach (var sale in sales)
        {
            result.Add(await MapToDtoAsync(sale, cancellationToken));
        }

        return result;
    }

    public async Task<IEnumerable<SaleDto>> GetDraftSalesBySellerAsync(Guid sellerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.MarketId == marketId && s.SellerId == sellerId && s.Status == SaleStatus.Draft,
            cancellationToken);

        var result = new List<SaleDto>();
        foreach (var sale in sales)
        {
            result.Add(await MapToDtoAsync(sale, cancellationToken));
        }

        return result;
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

        // Audit log (temporarily disabled for testing)
        // await _auditLogService.LogSaleActionAsync(sale.Id, "Create", sellerId, cancellationToken);

        return await MapToDtoAsync(sale, cancellationToken);
    }

    public async Task<SaleItemDto?> AddSaleItemAsync(Guid saleId, AddSaleItemDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
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
            await _unitOfWork.CommitTransactionAsync(cancellationToken);

            return MapSaleItemToDto(resultSaleItem, product.Name);
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            throw;
        }
    }

    public async Task<PaymentDto?> AddPaymentAsync(Guid saleId, AddPaymentDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
        {
            var sales = await _unitOfWork.Sales.FindAsync(
                s => s.Id == saleId && s.MarketId == marketId,
                cancellationToken);
            var sale = sales.FirstOrDefault();

            if (sale is null)
                throw new InvalidOperationException("Sale not found");

            if (sale.Status == SaleStatus.Paid || sale.Status == SaleStatus.Closed || sale.Status == SaleStatus.Cancelled)
                throw new InvalidOperationException($"Cannot add payment to sale with status: {sale.Status}");

            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                SaleId = saleId,
                PaymentType = Enum.Parse<PaymentType>(request.PaymentType, true),
                Amount = request.Amount,
                MarketId = sale.MarketId  // Multi-tenancy - inherit from Sale
            };

            await _unitOfWork.Payments.AddAsync(payment, cancellationToken);

            // Update sale paid amount
            sale.PaidAmount += request.Amount;

            // Determine new status
            if (sale.PaidAmount >= sale.TotalAmount)
            {
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
            else if (sale.PaidAmount > 0)
            {
                // Set status to Debt for partial payments
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

            _unitOfWork.Sales.Update(sale);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitTransactionAsync(cancellationToken);

            // Audit log
            await _auditLogService.LogPaymentActionAsync(payment.Id, sale.SellerId, cancellationToken);

            return new PaymentDto(
                payment.Id,
                payment.PaymentType.ToString(),
                payment.Amount,
                payment.CreatedAt
            );
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            throw;
        }
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

        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
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
            await _unitOfWork.CommitTransactionAsync(cancellationToken);

            // Audit log
            await _auditLogService.LogSaleActionAsync(saleId, "Cancel", adminGuid, cancellationToken);

            return await MapToDtoAsync(sale, cancellationToken);
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            throw;
        }
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
            p.PaymentType.ToString(),
            p.Amount,
            p.CreatedAt
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
            item.SalePrice,
            item.Quantity * item.SalePrice, // totalPrice
            item.Comment
        );
    }
}
