using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

/// <summary>
/// Goods-supplier directory CRUD. Mirrors <see cref="CustomerService"/>: every
/// query is scoped to the current market and soft-delete is used so historical
/// receipts keep their supplier link. "Outstanding debt" is the sum the shop
/// still owes the supplier across all their goods-receipts.
/// </summary>
public class SupplierService : ISupplierService
{
    private readonly IAppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;

    public SupplierService(IAppDbContext context, ICurrentMarketService currentMarketService)
    {
        _context = context;
        _currentMarketService = currentMarketService;
    }

    public async Task<SupplierDto?> GetSupplierByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var supplier = await _context.Suppliers
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id && s.MarketId == marketId && !s.IsDeleted, cancellationToken);

        if (supplier is null)
            return null;

        var (debt, count) = await GetBalanceAsync(id, marketId, cancellationToken);
        return ToDto(supplier, debt, count);
    }

    public async Task<IEnumerable<SupplierDto>> GetAllSuppliersAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var suppliers = await _context.Suppliers
            .AsNoTracking()
            .Where(s => s.MarketId == marketId && !s.IsDeleted)
            .OrderBy(s => s.Name)
            .ToListAsync(cancellationToken);

        if (suppliers.Count == 0)
            return [];

        var balances = await GetBalancesAsync(suppliers.Select(s => s.Id).ToList(), marketId, cancellationToken);

        return suppliers.Select(s =>
        {
            balances.TryGetValue(s.Id, out var b);
            return ToDto(s, b.Debt, b.Count);
        }).ToList();
    }

    public async Task<PagedResult<SupplierDto>> GetAllSuppliersPagedAsync(int page, int size, string? search = null, CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        size = Math.Clamp(size, 1, 200);

        var marketId = _currentMarketService.GetCurrentMarketId();

        var query = _context.Suppliers
            .AsNoTracking()
            .Where(s => s.MarketId == marketId && !s.IsDeleted);

        if (!string.IsNullOrWhiteSpace(search))
            query = query.Where(s =>
                s.Name.Contains(search) ||
                (s.Phone != null && s.Phone.Contains(search)));

        var total = await query.CountAsync(cancellationToken);

        var suppliers = await query
            .OrderBy(s => s.Name)
            .Skip((page - 1) * size)
            .Take(size)
            .ToListAsync(cancellationToken);

        if (suppliers.Count == 0)
            return PagedResult<SupplierDto>.From([], page, size, total);

        var balances = await GetBalancesAsync(suppliers.Select(s => s.Id).ToList(), marketId, cancellationToken);

        var items = suppliers.Select(s =>
        {
            balances.TryGetValue(s.Id, out var b);
            return ToDto(s, b.Debt, b.Count);
        }).ToList();

        return PagedResult<SupplierDto>.From(items, page, size, total);
    }

    public async Task<SupplierDto> CreateSupplierAsync(CreateSupplierDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var name = request.Name.Trim();
        // Name is unique per market (case-insensitive) — avoid duplicate suppliers.
        var exists = await _context.Suppliers
            .AnyAsync(s => s.MarketId == marketId && !s.IsDeleted && s.Name.ToLower() == name.ToLower(), cancellationToken);
        if (exists)
            throw new InvalidOperationException($"'{name}' nomli yetkazib beruvchi allaqachon mavjud.");

        var supplier = new Supplier
        {
            Id = Guid.NewGuid(),
            Name = name,
            Phone = request.Phone,
            Address = request.Address,
            Comment = request.Comment,
            IsDeleted = false,
            MarketId = marketId,
        };

        await _context.Suppliers.AddAsync(supplier, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);

        return ToDto(supplier, 0m, 0);
    }

    public async Task<SupplierDto?> UpdateSupplierAsync(UpdateSupplierDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var supplier = await _context.Suppliers
            .FirstOrDefaultAsync(s => s.Id == request.Id && s.MarketId == marketId && !s.IsDeleted, cancellationToken);
        if (supplier is null)
            return null;

        var changed = false;

        if (!string.IsNullOrWhiteSpace(request.Name) && request.Name.Trim() != supplier.Name)
        {
            var name = request.Name.Trim();
            var taken = await _context.Suppliers.AnyAsync(
                s => s.MarketId == marketId && !s.IsDeleted && s.Id != supplier.Id && s.Name.ToLower() == name.ToLower(),
                cancellationToken);
            if (taken)
                throw new InvalidOperationException($"'{name}' nomli yetkazib beruvchi allaqachon mavjud.");
            supplier.Name = name;
            changed = true;
        }

        if (request.Phone is not null && request.Phone != supplier.Phone) { supplier.Phone = request.Phone; changed = true; }
        if (request.Address is not null && request.Address != supplier.Address) { supplier.Address = request.Address; changed = true; }
        if (request.Comment is not null && request.Comment != supplier.Comment) { supplier.Comment = request.Comment; changed = true; }

        if (changed)
            await _context.SaveChangesAsync(cancellationToken);

        var (debt, count) = await GetBalanceAsync(supplier.Id, marketId, cancellationToken);
        return ToDto(supplier, debt, count);
    }

    public async Task<bool> SoftDeleteSupplierAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var supplier = await _context.Suppliers
            .FirstOrDefaultAsync(s => s.Id == id && s.MarketId == marketId, cancellationToken);
        if (supplier is null)
            return false;

        // Soft delete only — historical receipts keep pointing at this supplier
        // (loaded with IgnoreQueryFilters when rendering history) so the shop's
        // past deliveries never lose their supplier name.
        supplier.IsDeleted = true;
        _context.Suppliers.Update(supplier);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<SupplierDeleteInfoDto> GetSupplierDeleteInfoAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var supplier = await _context.Suppliers
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id && s.MarketId == marketId && !s.IsDeleted, cancellationToken);
        if (supplier is null)
            return new SupplierDeleteInfoDto(false, 0, 0m, "Yetkazib beruvchi topilmadi");

        var (debt, count) = await GetBalanceAsync(id, marketId, cancellationToken);

        var warning = debt > 0
            ? $"Bu yetkazib beruvchiga {debt:N0} so'm qarzingiz bor. O'chirsangiz ham xaridlar tarixi saqlanadi."
            : (count > 0 ? "Yetkazib beruvchini o'chirsangiz ham xaridlar tarixi saqlanadi." : null);

        // Soft-delete is always allowed; the warning just informs the operator.
        return new SupplierDeleteInfoDto(true, count, debt, warning);
    }

    // ── helpers ─────────────────────────────────────────────────────────────

    private async Task<(decimal Debt, int Count)> GetBalanceAsync(Guid supplierId, int marketId, CancellationToken cancellationToken)
    {
        var agg = await _context.ZakupReceipts
            .AsNoTracking()
            .Where(r => r.SupplierId == supplierId && r.MarketId == marketId)
            .GroupBy(r => r.SupplierId)
            .Select(g => new { Debt = g.Sum(r => r.TotalAmount - r.PaidAmount), Count = g.Count() })
            .FirstOrDefaultAsync(cancellationToken);

        return agg is null ? (0m, 0) : (agg.Debt, agg.Count);
    }

    private async Task<Dictionary<Guid, (decimal Debt, int Count)>> GetBalancesAsync(List<Guid> supplierIds, int marketId, CancellationToken cancellationToken)
    {
        var rows = await _context.ZakupReceipts
            .AsNoTracking()
            .Where(r => r.SupplierId != null && supplierIds.Contains(r.SupplierId.Value) && r.MarketId == marketId)
            .GroupBy(r => r.SupplierId!.Value)
            .Select(g => new { SupplierId = g.Key, Debt = g.Sum(r => r.TotalAmount - r.PaidAmount), Count = g.Count() })
            .ToListAsync(cancellationToken);

        return rows.ToDictionary(x => x.SupplierId, x => (x.Debt, x.Count));
    }

    private static SupplierDto ToDto(Supplier s, decimal outstandingDebt, int receiptCount) => new(
        s.Id,
        s.Name,
        s.Phone,
        s.Address,
        s.Comment,
        outstandingDebt,
        receiptCount
    );
}
