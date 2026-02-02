using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.Application.Services;

public class SaleService : ISaleService
{
    private readonly IUnitOfWork _unitOfWork;

    public SaleService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
    }

    public async Task<SaleDto?> GetSaleByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var sale = await _unitOfWork.Sales.GetWithDetailsAsync(id, cancellationToken);
        if (sale is null)
            return null;

        return await MapToDtoAsync(sale, cancellationToken);
    }

    public async Task<IEnumerable<SaleDto>> GetAllSalesAsync(CancellationToken cancellationToken = default)
    {
        var sales = await _unitOfWork.Sales.GetAllAsync(cancellationToken);
        var result = new List<SaleDto>();

        foreach (var sale in sales)
        {
            result.Add(await MapToDtoAsync(sale, cancellationToken));
        }

        return result;
    }

    public async Task<IEnumerable<SaleDto>> GetSalesByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default)
    {
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt <= end,
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
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.SellerId == sellerId && s.Status == SaleStatus.Draft,
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
            PaidAmount = 0
        };

        await _unitOfWork.Sales.AddAsync(sale, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return await MapToDtoAsync(sale, cancellationToken);
    }

    public async Task<SaleItemDto?> AddSaleItemAsync(Guid saleId, AddSaleItemDto request, CancellationToken cancellationToken = default)
    {
        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
        {
            var sale = await _unitOfWork.Sales.GetByIdAsync(saleId, cancellationToken);
            if (sale is null || sale.Status != SaleStatus.Draft)
                throw new InvalidOperationException("Sale not found or not in Draft status");

            var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId, cancellationToken);
            if (product is null)
                throw new InvalidOperationException("Product not found");

            // Validate stock
            if (product.Quantity < request.Quantity)
                throw new InvalidOperationException($"Insufficient stock. Available: {product.Quantity}, Requested: {request.Quantity}");

            // MinSalePrice validation - if sale price is less than min, comment is required
            if (request.SalePrice < product.MinSalePrice && string.IsNullOrWhiteSpace(request.Comment))
                throw new InvalidOperationException($"Comment is required when selling below minimum price. MinPrice: {product.MinSalePrice}, YourPrice: {request.SalePrice}");

            // Check threshold
            if (product.Quantity <= product.MinThreshold)
            {
                // Log warning - product is at or below threshold
                // This is allowed but should trigger warning in UI
            }

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
            _unitOfWork.Products.Update(product);

            // Update sale total
            var itemTotal = request.Quantity * request.SalePrice;
            sale.TotalAmount += itemTotal;
            _unitOfWork.Sales.Update(sale);

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitTransactionAsync(cancellationToken);

            return MapSaleItemToDto(saleItem, product.Name);
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            throw;
        }
    }

    public async Task<PaymentDto?> AddPaymentAsync(Guid saleId, AddPaymentDto request, CancellationToken cancellationToken = default)
    {
        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
        {
            var sale = await _unitOfWork.Sales.GetByIdAsync(saleId, cancellationToken);
            if (sale is null)
                throw new InvalidOperationException("Sale not found");

            if (sale.Status == SaleStatus.Paid || sale.Status == SaleStatus.Closed || sale.Status == SaleStatus.Cancelled)
                throw new InvalidOperationException($"Cannot add payment to sale with status: {sale.Status}");

            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                SaleId = saleId,
                PaymentType = Enum.Parse<PaymentType>(request.PaymentType, true),
                Amount = request.Amount
            };

            await _unitOfWork.Payments.AddAsync(payment, cancellationToken);

            // Update sale paid amount
            sale.PaidAmount += request.Amount;

            // Determine new status
            if (sale.PaidAmount >= sale.TotalAmount)
            {
                sale.Status = SaleStatus.Paid;

                // Close any associated debt
                if (sale.Debt != null)
                {
                    sale.Debt.Status = DebtStatus.Closed;
                    sale.Debt.RemainingDebt = 0;
                    _unitOfWork.Debts.Update(sale.Debt);
                }
            }
            else if (sale.PaidAmount > 0)
            {
                sale.Status = SaleStatus.Debt;

                // Create or update debt
                if (sale.Debt == null)
                {
                    sale.Debt = new Debt
                    {
                        Id = Guid.NewGuid(),
                        SaleId = saleId,
                        CustomerId = sale.CustomerId ?? Guid.Empty,
                        TotalDebt = sale.TotalAmount,
                        RemainingDebt = sale.TotalAmount - sale.PaidAmount,
                        Status = DebtStatus.Open
                    };
                    await _unitOfWork.Debts.AddAsync(sale.Debt, cancellationToken);
                }
                else
                {
                    sale.Debt.RemainingDebt = sale.TotalAmount - sale.PaidAmount;
                    _unitOfWork.Debts.Update(sale.Debt);
                }
            }

            _unitOfWork.Sales.Update(sale);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitTransactionAsync(cancellationToken);

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

    public async Task<SaleDto?> CancelSaleAsync(Guid saleId, Guid adminId, CancellationToken cancellationToken = default)
    {
        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
        {
            var sale = await _unitOfWork.Sales.GetByIdAsync(saleId, cancellationToken);
            if (sale is null)
                return null;

            if (sale.Status == SaleStatus.Cancelled)
                throw new InvalidOperationException("Sale is already cancelled");

            // Restore stock for all items
            var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == saleId, cancellationToken);
            foreach (var item in saleItems)
            {
                var product = await _unitOfWork.Products.GetByIdAsync(item.ProductId, cancellationToken);
                if (product != null)
                {
                    product.Quantity += item.Quantity;
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
        var saleItem = await _unitOfWork.SaleItems.GetByIdAsync(saleItemId, cancellationToken);
        if (saleItem is null)
            return false;

        var product = await _unitOfWork.Products.GetByIdAsync(saleItem.ProductId, cancellationToken);
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
            var product = await _unitOfWork.Products.GetByIdAsync(item.ProductId, cancellationToken);
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
            item.ProductId,
            productName,
            item.Quantity,
            item.CostPrice,
            item.SalePrice,
            item.Profit,
            item.Comment
        );
    }
}
