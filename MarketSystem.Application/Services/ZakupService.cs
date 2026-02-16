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
        var marketId = _currentMarketService.GetCurrentMarketId();

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.Id == id && z.MarketId == marketId,
            cancellationToken);

        var zakup = zakups.FirstOrDefault();

        if (zakup is null)
            return null;

        return await MapToDtoAsync(zakup, cancellationToken);
    }

    public async Task<IEnumerable<ZakupDto>> GetAllZakupsAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.MarketId == marketId,
            cancellationToken);

        var result = new List<ZakupDto>();

        foreach (var zakup in zakups)
        {
            result.Add(await MapToDtoAsync(zakup, cancellationToken));
        }

        return result;
    }

    public async Task<IEnumerable<ZakupDto>> GetZakupsByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.MarketId == marketId && z.CreatedAt >= start && z.CreatedAt <= end,
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
        var marketId = _currentMarketService.GetCurrentMarketId();
        await _unitOfWork.BeginTransactionAsync(cancellationToken);

        try
        {
            var products = await _unitOfWork.Products.FindAsync(
                p => p.Id == request.ProductId && p.MarketId == marketId,
                cancellationToken);
            var product = products.FirstOrDefault();

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
        // Get product and verify it belongs to the same market as the zakup
        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == zakup.ProductId && p.MarketId == zakup.MarketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        // Get admin - admin should be from the same market
        var admins = await _unitOfWork.Users.FindAsync(
            u => u.Id == zakup.CreatedByAdminId && u.MarketId == zakup.MarketId,
            cancellationToken);
        var admin = admins.FirstOrDefault();

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
