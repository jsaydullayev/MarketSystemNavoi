using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.Application.Services;

public class ZakupService : IZakupService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditLogService _auditLogService;

    public ZakupService(IUnitOfWork unitOfWork, IAuditLogService auditLogService)
    {
        _unitOfWork = unitOfWork;
        _auditLogService = auditLogService;
    }

    public async Task<ZakupDto?> GetZakupByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var zakup = await _unitOfWork.Zakups.GetByIdAsync(id, cancellationToken);
        if (zakup is null)
            return null;

        return await MapToDtoAsync(zakup, cancellationToken);
    }

    public async Task<IEnumerable<ZakupDto>> GetAllZakupsAsync(CancellationToken cancellationToken = default)
    {
        var zakups = await _unitOfWork.Zakups.GetAllAsync(cancellationToken);
        var result = new List<ZakupDto>();

        foreach (var zakup in zakups)
        {
            result.Add(await MapToDtoAsync(zakup, cancellationToken));
        }

        return result;
    }

    public async Task<IEnumerable<ZakupDto>> GetZakupsByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default)
    {
        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= start && z.CreatedAt <= end,
            cancellationToken);

        var result = new List<ZakupDto>();
        foreach (var zakup in zakups)
        {
            result.Add(await MapToDtoAsync(zakup, cancellationToken));
        }

        return result;
    }

    public async Task<ZakupDto> CreateZakupAsync(CreateZakupDto request, Guid adminId, CancellationToken cancellationToken = default)
    {
        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
        {
            var product = await _unitOfWork.Products.GetByIdAsync(request.ProductId, cancellationToken);
            if (product is null)
                throw new InvalidOperationException("Product not found");

            var zakup = new Zakup
            {
                Id = Guid.NewGuid(),
                ProductId = request.ProductId,
                Quantity = request.Quantity,
                CostPrice = request.CostPrice,
                CreatedByAdminId = adminId
            };

            await _unitOfWork.Zakups.AddAsync(zakup, cancellationToken);

            // WEIGHTED AVERAGE FORMULA:
            // NewCostPrice = (OldTotalCost + NewCost) / (OldQuantity + NewQuantity)
            var oldTotalCost = product.Quantity * product.CostPrice;
            var newTotalCost = request.Quantity * request.CostPrice;
            var totalQuantity = product.Quantity + request.Quantity;

            // Update product stock and cost price with weighted average
            product.Quantity += request.Quantity;
            product.CostPrice = totalQuantity > 0 ? (oldTotalCost + newTotalCost) / totalQuantity : request.CostPrice;

            // Optionally update SalePrice and MinSalePrice if provided (admin discretion)
            // For now, we keep them unchanged as per TZ

            _unitOfWork.Products.Update(product);

            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _unitOfWork.CommitTransactionAsync(cancellationToken);

            // Audit log
            await _auditLogService.LogZakupActionAsync(zakup.Id, adminId, cancellationToken);

            return await MapToDtoAsync(zakup, cancellationToken);
        }
        catch
        {
            await _unitOfWork.RollbackTransactionAsync(cancellationToken);
            throw;
        }
    }

    private async Task<ZakupDto> MapToDtoAsync(Zakup zakup, CancellationToken cancellationToken)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(zakup.ProductId, cancellationToken);
        var admin = await _unitOfWork.Users.GetByIdAsync(zakup.CreatedByAdminId, cancellationToken);

        return new ZakupDto(
            zakup.Id,
            zakup.ProductId,
            product?.Name ?? "Unknown",
            zakup.Quantity,
            zakup.CostPrice,
            zakup.CreatedAt,
            admin?.FullName ?? "Unknown"
        );
    }
}
