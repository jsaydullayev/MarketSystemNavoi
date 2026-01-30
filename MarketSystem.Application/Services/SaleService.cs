using Microsoft.Extensions.Logging;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Application.Services;

public class SaleService : ISaleService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<SaleService> _logger;

    public SaleService(IUnitOfWork unitOfWork, ILogger<SaleService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<Sale> CreateSaleAsync(
        Guid branchId,
        Guid sellerId,
        Guid? customerId,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Creating sale: BranchId={BranchId}, SellerId={SellerId}, CustomerId={CustomerId}",
            branchId, sellerId, customerId);

        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            BranchId = branchId,
            SellerId = sellerId,
            CustomerId = customerId,
            Status = SaleStatus.Draft,
            TotalAmount = 0,
            PaidAmount = 0
        };

        await _unitOfWork.Sales.AddAsync(sale, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Sale created successfully: SaleId={SaleId}", sale.Id);
        return sale;
    }

    public async Task<Sale?> GetSaleAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        return await _unitOfWork.Sales.GetWithDetailsAsync(saleId, cancellationToken);
    }

    public async Task<bool> CanAddItemAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        var sale = await _unitOfWork.Sales.GetByIdAsync(saleId, cancellationToken);
        return sale != null && sale.Status == SaleStatus.Draft;
    }

    public async Task AddItemAsync(
        Guid saleId,
        Guid productId,
        decimal quantity,
        decimal costPrice,
        decimal salePrice,
        string? comment,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Adding item to sale {SaleId}: ProductId={ProductId}, Quantity={Quantity}, Price={Price}",
            saleId, productId, quantity, salePrice);

        var sale = await _unitOfWork.Sales.GetWithItemsAsync(saleId, cancellationToken);

        if (sale == null)
        {
            throw new Exception($"Sale {saleId} not found");
        }

        if (sale.Status != SaleStatus.Draft)
        {
            throw new Exception($"Cannot add items to sale with status {sale.Status}");
        }

        var saleItem = new SaleItem
        {
            Id = Guid.NewGuid(),
            SaleId = saleId,
            ProductId = productId,
            Quantity = quantity,
            CostPrice = costPrice,
            SalePrice = salePrice,
            Comment = comment
        };

        await _unitOfWork.SaleItems.AddAsync(saleItem, cancellationToken);

        // Update sale total
        sale.TotalAmount += salePrice * quantity;

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Item added successfully: SaleItemID={SaleItemId}, New Total={Total}",
            saleItem.Id, sale.TotalAmount);
    }

    public async Task CancelSaleAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Cancelling sale {SaleId}", saleId);

        var sale = await _unitOfWork.Sales.GetWithDetailsAsync(saleId, cancellationToken);

        if (sale == null)
        {
            throw new Exception($"Sale {saleId} not found");
        }

        if (sale.Status == SaleStatus.Cancelled)
        {
            throw new Exception("Sale already cancelled");
        }

        // Restore stock if sale was paid
        if (sale.Status == SaleStatus.Paid || sale.Status == SaleStatus.Closed)
        {
            await RestoreStockAsync(sale, cancellationToken);
        }

        sale.Status = SaleStatus.Cancelled;

        // Close debt if exists
        if (sale.Debt != null)
        {
            sale.Debt.Status = DebtStatus.Closed;
            sale.Debt.RemainingDebt = 0;
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Sale cancelled successfully: SaleId={SaleId}", saleId);
    }

    private async Task RestoreStockAsync(Sale sale, CancellationToken cancellationToken)
    {
        foreach (var item in sale.SaleItems)
        {
            var branchProduct = await _unitOfWork.BranchProducts.GetByBranchAndProductAsync(
                sale.BranchId, item.ProductId, cancellationToken);

            if (branchProduct == null)
            {
                throw new Exception($"Branch product not found for ProductId {item.ProductId}");
            }

            branchProduct.Quantity += item.Quantity;
        }
    }
}
