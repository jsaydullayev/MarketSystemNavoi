using Microsoft.Extensions.Logging;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.Application.Services;

public class StockService : IStockService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<StockService> _logger;

    public StockService(IUnitOfWork unitOfWork, ILogger<StockService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<bool> CheckStockAvailabilityAsync(
        Guid productId,
        Guid branchId,
        decimal quantity,
        CancellationToken cancellationToken = default)
    {
        var branchProduct = await _unitOfWork.BranchProducts.GetByBranchAndProductAsync(branchId, productId, cancellationToken);

        if (branchProduct == null)
        {
            _logger.LogWarning("Product {ProductId} not found in branch {BranchId}", productId, branchId);
            return false;
        }

        var available = branchProduct.Quantity >= quantity;

        if (!available)
        {
            _logger.LogWarning("Insufficient stock for Product {ProductId}: Available={Available}, Required={Required}",
                productId, branchProduct.Quantity, quantity);
        }

        // Check if at/below threshold
        if (branchProduct.Quantity <= branchProduct.MinThreshold)
        {
            _logger.LogWarning("Product {ProductId} is at or below threshold. Current: {Current}, Threshold: {Threshold}",
                productId, branchProduct.Quantity, branchProduct.MinThreshold);
        }

        return available;
    }

    public async Task<BranchProduct?> GetBranchProductAsync(
        Guid productId,
        Guid branchId,
        CancellationToken cancellationToken = default)
    {
        return await _unitOfWork.BranchProducts.GetByBranchAndProductAsync(branchId, productId, cancellationToken);
    }

    public async Task DeductStockAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Deducting stock for sale {SaleId}", saleId);

        var sale = await _unitOfWork.Sales.GetWithItemsAsync(saleId, cancellationToken);

        if (sale == null)
        {
            throw new Exception($"Sale {saleId} not found");
        }

        foreach (var item in sale.SaleItems)
        {
            var branchProduct = await _unitOfWork.BranchProducts.GetByBranchAndProductAsync(
                sale.BranchId, item.ProductId, cancellationToken);

            if (branchProduct == null)
            {
                _logger.LogError("Branch product not found for ProductId {ProductId}", item.ProductId);
                throw new Exception($"Branch product not found for ProductId {item.ProductId}");
            }

            // Double-check stock availability
            if (branchProduct.Quantity < item.Quantity)
            {
                _logger.LogError("Insufficient stock for Product {ProductId} when finalizing sale. Available: {Available}, Required: {Required}",
                    item.ProductId, branchProduct.Quantity, item.Quantity);
                throw new Exception($"Insufficient stock for product {item.ProductId}. " +
                    $"Available: {branchProduct.Quantity}, Required: {item.Quantity}");
            }

            var previousQuantity = branchProduct.Quantity;
            branchProduct.Quantity -= item.Quantity;

            _logger.LogInformation("Deducted stock for Product {ProductId}: Previous={Previous}, Deducted={Deducted}, New={New}",
                item.ProductId, previousQuantity, item.Quantity, branchProduct.Quantity);

            // Check threshold after deduction
            if (branchProduct.Quantity <= branchProduct.MinThreshold)
            {
                _logger.LogWarning("Product {ProductId} is now at or below threshold after deduction. Current: {Current}, Threshold: {Threshold}",
                    item.ProductId, branchProduct.Quantity, branchProduct.MinThreshold);
            }
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }

    public async Task RestoreStockAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Restoring stock for sale {SaleId}", saleId);

        var sale = await _unitOfWork.Sales.GetWithItemsAsync(saleId, cancellationToken);

        if (sale == null)
        {
            throw new Exception($"Sale {saleId} not found");
        }

        foreach (var item in sale.SaleItems)
        {
            var branchProduct = await _unitOfWork.BranchProducts.GetByBranchAndProductAsync(
                sale.BranchId, item.ProductId, cancellationToken);

            if (branchProduct == null)
            {
                _logger.LogError("Branch product not found for ProductId {ProductId}", item.ProductId);
                throw new Exception($"Branch product not found for ProductId {item.ProductId}");
            }

            var previousQuantity = branchProduct.Quantity;
            branchProduct.Quantity += item.Quantity;

            _logger.LogInformation("Restored stock for Product {ProductId}: Previous={Previous}, Restored={Restored}, New={New}",
                item.ProductId, previousQuantity, item.Quantity, branchProduct.Quantity);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
