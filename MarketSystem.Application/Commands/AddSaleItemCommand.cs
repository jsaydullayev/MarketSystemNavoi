using MediatR;
using Microsoft.Extensions.Logging;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Commands;

public record AddSaleItemCommand(AddSaleItemRequest Request) : IRequest<SaleItemResponse>;

public class AddSaleItemCommandHandler : IRequestHandler<AddSaleItemCommand, SaleItemResponse>
{
    private readonly AppDbContext _context;
    private readonly ILogger<AddSaleItemCommandHandler> _logger;

    public AddSaleItemCommandHandler(AppDbContext context, ILogger<AddSaleItemCommandHandler> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<SaleItemResponse> Handle(AddSaleItemCommand command, CancellationToken cancellationToken)
    {
        var request = command.Request;

        _logger.LogInformation("Adding item to sale {SaleId}: ProductId={ProductId}, Quantity={Quantity}",
            request.SaleId, request.ProductId, request.Quantity);

        try
        {
            // Start transaction for atomic operation
            using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);

            // Get sale
            var sale = await _context.Sales
                .Include(s => s.SaleItems)
                .FirstOrDefaultAsync(s => s.Id == request.SaleId, cancellationToken)
                ?? throw new Exception($"Sale with ID {request.SaleId} not found");

            if (sale.Status != SaleStatus.Draft)
            {
                _logger.LogWarning("Attempt to add item to non-draft sale {SaleId} with status {Status}",
                    request.SaleId, sale.Status);
                throw new Exception($"Can only add items to draft sales. Current status: {sale.Status}");
            }

            // Get branch product
            var branchProduct = await _context.BranchProducts
                .Include(bp => bp.Product)
                .FirstOrDefaultAsync(bp => bp.ProductId == request.ProductId && bp.BranchId == sale.BranchId, cancellationToken)
                ?? throw new Exception($"Product {request.ProductId} not found in branch {sale.BranchId}");

            // Validate quantity (only check, don't deduct yet)
            if (branchProduct.Quantity < request.Quantity)
            {
                _logger.LogWarning("Insufficient stock for Product {ProductId}: Available={Available}, Requested={Requested}",
                    request.ProductId, branchProduct.Quantity, request.Quantity);
                throw new Exception($"Insufficient stock. Available: {branchProduct.Quantity}, Requested: {request.Quantity}");
            }

            // Check if below threshold
            var isLowStock = branchProduct.Quantity <= branchProduct.MinThreshold;
            if (isLowStock)
            {
                _logger.LogWarning("Product {ProductId} is at or below threshold. Current: {Current}, Threshold: {Threshold}",
                    request.ProductId, branchProduct.Quantity, branchProduct.MinThreshold);
            }

            // Validate sale price
            var isBelowMinPrice = request.SalePrice < branchProduct.MinSalePrice;
            if (isBelowMinPrice && string.IsNullOrEmpty(request.Comment))
            {
                _logger.LogWarning("Attempt to sell Product {ProductId} below minimum price without comment. SalePrice={SalePrice}, MinPrice={MinPrice}",
                    request.ProductId, request.SalePrice, branchProduct.MinSalePrice);
                throw new Exception("Comment required when selling below minimum price");
            }

            if (isBelowMinPrice)
            {
                _logger.LogWarning("Product {ProductId} sold below minimum price with comment: {Comment}",
                    request.ProductId, request.Comment);
            }

            var saleItem = new SaleItem
            {
                Id = Guid.NewGuid(),
                SaleId = request.SaleId,
                ProductId = request.ProductId,
                Quantity = request.Quantity,
                CostPrice = branchProduct.CostPrice,
                SalePrice = request.SalePrice,
                Comment = request.Comment
            };

            _context.SaleItems.Add(saleItem);

            // Update sale total
            sale.TotalAmount += request.SalePrice * request.Quantity;

            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            _logger.LogInformation("Successfully added item to sale {SaleId}. SaleItem ID: {SaleItemId}, New Total: {TotalAmount}",
                request.SaleId, saleItem.Id, sale.TotalAmount);

            return new SaleItemResponse(
                saleItem.Id,
                saleItem.ProductId,
                branchProduct.Product.Name,
                saleItem.Quantity,
                saleItem.CostPrice,
                saleItem.SalePrice,
                saleItem.Profit,
                saleItem.Comment
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding item to sale {SaleId}: {Message}", request.SaleId, ex.Message);
            throw;
        }
    }
}
