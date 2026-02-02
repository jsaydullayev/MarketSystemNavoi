using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.Application.Services;

public class ZakupService : IZakupService
{
    private readonly IUnitOfWork _unitOfWork;

    public ZakupService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;
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

        // Update product stock and cost price
        product.Quantity += request.Quantity;
        product.CostPrice = request.CostPrice; // Update cost price to latest purchase price
        _unitOfWork.Products.Update(product);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return await MapToDtoAsync(zakup, cancellationToken);
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
