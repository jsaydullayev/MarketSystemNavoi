using MediatR;
using Microsoft.Extensions.Logging;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Commands;

public record CreateZakupCommand(CreateZakupRequest Request, Guid AdminId) : IRequest;

public class CreateZakupCommandHandler : IRequestHandler<CreateZakupCommand>
{
    private readonly AppDbContext _context;
    private readonly ILogger<CreateZakupCommandHandler> _logger;

    public CreateZakupCommandHandler(AppDbContext context, ILogger<CreateZakupCommandHandler> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task Handle(CreateZakupCommand command, CancellationToken cancellationToken)
    {
        var request = command.Request;
        var adminId = command.AdminId;

        _logger.LogInformation("Admin {AdminId} creating zakup: ProductId={ProductId}, BranchId={BranchId}, Quantity={Quantity}, CostPrice={CostPrice}",
            adminId, request.ProductId, request.BranchId, request.Quantity, request.CostPrice);

        try
        {
            using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);

            // Validate admin
            var admin = await _context.Users
                .Include(u => u.Branch)
                .FirstOrDefaultAsync(u => u.Id == adminId && u.IsActive, cancellationToken)
                ?? throw new Exception($"Admin with ID {adminId} not found or inactive");

            var zakup = new Zakup
            {
                Id = Guid.NewGuid(),
                ProductId = request.ProductId,
                BranchId = request.BranchId,
                Quantity = request.Quantity,
                CostPrice = request.CostPrice,
                CreatedByAdminId = adminId
            };

            _context.Zakups.Add(zakup);

            // Update or create BranchProduct
            var branchProduct = await _context.BranchProducts
                .Include(bp => bp.Product)
                .FirstOrDefaultAsync(bp => bp.ProductId == request.ProductId && bp.BranchId == request.BranchId, cancellationToken);

            if (branchProduct != null)
            {
                // Update existing - use weighted average for cost price
                var previousCostPrice = branchProduct.CostPrice;
                var previousQuantity = branchProduct.Quantity;

                var totalValue = (branchProduct.Quantity * branchProduct.CostPrice) + (request.Quantity * request.CostPrice);
                var totalQuantity = branchProduct.Quantity + request.Quantity;
                branchProduct.CostPrice = totalValue / totalQuantity;
                branchProduct.Quantity = totalQuantity;

                _logger.LogInformation("Updated existing BranchProduct for Product {ProductId}: " +
                    "Previous (CostPrice={PreviousCost}, Quantity={PreviousQty}), " +
                    "New Purchase (CostPrice={PurchaseCost}, Quantity={PurchaseQty}), " +
                    "Result (CostPrice={NewCost}, Quantity={NewQty})",
                    request.ProductId, previousCostPrice, previousQuantity,
                    request.CostPrice, request.Quantity,
                    branchProduct.CostPrice, branchProduct.Quantity);
            }
            else
            {
                // Create new branch product
                branchProduct = new BranchProduct
                {
                    Id = Guid.NewGuid(),
                    BranchId = request.BranchId,
                    ProductId = request.ProductId,
                    CostPrice = request.CostPrice,
                    SalePrice = request.CostPrice * 1.2m, // Default 20% markup
                    MinSalePrice = request.CostPrice,
                    Quantity = request.Quantity,
                    MinThreshold = 10 // Default threshold
                };
                _context.BranchProducts.Add(branchProduct);

                _logger.LogInformation("Created new BranchProduct for Product {ProductId}: " +
                    "CostPrice={CostPrice}, SalePrice={SalePrice}, Quantity={Quantity}",
                    request.ProductId, branchProduct.CostPrice, branchProduct.SalePrice, branchProduct.Quantity);
            }

            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            _logger.LogInformation("Zakup created successfully: ZakupId={ZakupId}, ProductId={ProductId}, Quantity={Quantity}",
                zakup.Id, request.ProductId, request.Quantity);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating zakup for Product {ProductId}: {Message}",
                request.ProductId, ex.Message);
            throw;
        }
    }
}
