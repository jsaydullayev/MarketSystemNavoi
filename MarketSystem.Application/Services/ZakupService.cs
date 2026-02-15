using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

public class ZakupService : IZakupService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditLogService _auditLogService;
    private readonly AppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;

    public ZakupService(IUnitOfWork unitOfWork, IAuditLogService auditLogService, AppDbContext context, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _auditLogService = auditLogService;
        _context = context;
        _currentMarketService = currentMarketService;
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
                CreatedByAdminId = adminId,
                MarketId = _currentMarketService.GetCurrentMarketId()  // Multi-tenancy
            };

            await _unitOfWork.Zakups.AddAsync(zakup, cancellationToken);

            // Update product stock and cost price with latest purchase price
            product.Quantity += request.Quantity;
            product.CostPrice = request.CostPrice; // Use latest purchase price

            // Ensure EF Core tracks the product entity explicitly
            _context.Entry(product).State = EntityState.Modified;
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
