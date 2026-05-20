using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;

namespace MarketSystem.Application.Services;

public class CustomerService : ICustomerService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CustomerService(IUnitOfWork unitOfWork, IAppDbContext context, ICurrentMarketService currentMarketService, IHttpContextAccessor httpContextAccessor)
    {
        _unitOfWork = unitOfWork;
        _context = context;
        _currentMarketService = currentMarketService;
        _httpContextAccessor = httpContextAccessor;
    }

    private Guid? GetCurrentUserId()
    {
        var userIdClaim = _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userIdClaim != null && Guid.TryParse(userIdClaim, out var userId))
        {
            return userId;
        }
        return null;
    }

    public async Task<CustomerDto?> GetCustomerByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ⭐ CRITICAL FIX: Use direct database query instead of UnitOfWork.FindAsync
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Id == id && c.MarketId == marketId && !c.IsDeleted, cancellationToken);

        if (customer is null)
            return null;

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<CustomerDto?> GetCustomerByPhoneAsync(string phone, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ⭐ CRITICAL FIX: Use direct database query instead of UnitOfWork.FindAsync
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Phone == phone && c.MarketId == marketId && !c.IsDeleted, cancellationToken);

        if (customer is null)
            return null;

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<IEnumerable<CustomerDto>> GetAllCustomersAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var customers = await _context.Customers
            .AsNoTracking()
            .Where(c => c.MarketId == marketId && !c.IsDeleted)
            .OrderBy(c => c.FullName)
            .ToListAsync(cancellationToken);

        if (customers.Count == 0)
            return [];

        var customerIds = customers.Select(c => c.Id).ToList();

        var debtsByCustomer = await _context.Debts
            .Where(d => customerIds.Contains(d.CustomerId) && d.MarketId == marketId && d.Status == DebtStatus.Open)
            .GroupBy(d => d.CustomerId)
            .Select(g => new { CustomerId = g.Key, Total = g.Sum(d => d.RemainingDebt) })
            .ToDictionaryAsync(x => x.CustomerId, x => x.Total, cancellationToken);

        return customers.Select(c => new CustomerDto(
            c.Id,
            c.Phone,
            c.FullName,
            c.Comment,
            debtsByCustomer.TryGetValue(c.Id, out var debt) ? debt : 0m
        )).ToList();
    }

    public async Task<PagedResult<CustomerDto>> GetAllCustomersPagedAsync(int page, int size, string? search = null, CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        size = Math.Clamp(size, 1, 200);

        var marketId = _currentMarketService.GetCurrentMarketId();

        var query = _context.Customers
            .AsNoTracking()
            .Where(c => c.MarketId == marketId && !c.IsDeleted);

        if (!string.IsNullOrWhiteSpace(search))
            // FullName / Phone are nullable on the entity — null-guard each
            // side so the query translates to safe SQL and the compiler is
            // satisfied. EF turns the null check into `IS NOT NULL AND ...`.
            query = query.Where(c =>
                (c.FullName != null && c.FullName.Contains(search)) ||
                (c.Phone != null && c.Phone.Contains(search)));

        var total = await query.CountAsync(cancellationToken);

        var customers = await query
            .OrderBy(c => c.FullName)
            .Skip((page - 1) * size)
            .Take(size)
            .ToListAsync(cancellationToken);

        if (customers.Count == 0)
            return PagedResult<CustomerDto>.From([], page, size, total);

        var customerIds = customers.Select(c => c.Id).ToList();

        var debtsByCustomer = await _context.Debts
            .Where(d => customerIds.Contains(d.CustomerId) && d.MarketId == marketId && d.Status == DebtStatus.Open)
            .GroupBy(d => d.CustomerId)
            .Select(g => new { CustomerId = g.Key, Total = g.Sum(d => d.RemainingDebt) })
            .ToDictionaryAsync(x => x.CustomerId, x => x.Total, cancellationToken);

        var items = customers.Select(c => new CustomerDto(
            c.Id,
            c.Phone,
            c.FullName,
            c.Comment,
            debtsByCustomer.TryGetValue(c.Id, out var debt) ? debt : 0m
        )).ToList();

        return PagedResult<CustomerDto>.From(items, page, size, total);
    }

    public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        // Phone is unique per market — check within this tenant only.
        if (await _context.Customers.AnyAsync(c => c.Phone == request.Phone && c.MarketId == marketId, cancellationToken))
            throw new InvalidOperationException($"Customer with phone '{request.Phone}' already exists");

        var customer = new Customer
        {
            Id = Guid.NewGuid(),
            Phone = request.Phone,
            FullName = request.FullName,
            Comment = request.Comment,
            IsDeleted = false,
            MarketId = marketId
        };

        await _context.Customers.AddAsync(customer, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);

        // Agar initial debt bor bo'lsa, dummy Sale va Debt yozuvlarini yaratamiz
        if (request.InitialDebt.HasValue && request.InitialDebt.Value > 0)
        {
            var currentUserId = GetCurrentUserId();

            if (!currentUserId.HasValue)
            {
                throw new UnauthorizedAccessException("Foydalanuvchi identifikatsiyasi aniqlashmadi. Iltimos, qayta tiling.");
            }

            // Dummy sale yaratamiz (mahsulotsiz, faqat qarz uchun)
            var dummySale = new MarketSystem.Domain.Entities.Sale
            {
                Id = Guid.NewGuid(),
                SellerId = currentUserId.Value,  // Hozirgi foydalanuvchi
                CustomerId = customer.Id,
                TotalAmount = request.InitialDebt.Value,
                PaidAmount = 0,
                Status = MarketSystem.Domain.Enums.SaleStatus.Debt,
                IsDeleted = false,
                CreatedAt = DateTime.UtcNow,
                MarketId = marketId
            };

            await _context.Sales.AddAsync(dummySale, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);

            // Debt yozuvini yaratamiz
            var debt = new MarketSystem.Domain.Entities.Debt
            {
                Id = Guid.NewGuid(),
                SaleId = dummySale.Id,  // Dummy sale ga bog'laymiz
                CustomerId = customer.Id,
                TotalDebt = request.InitialDebt.Value,
                RemainingDebt = request.InitialDebt.Value,
                Status = DebtStatus.Open,
                CreatedAt = DateTime.UtcNow,
                MarketId = marketId
            };

            await _context.Debts.AddAsync(debt, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
        }

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<CustomerDto?> UpdateCustomerAsync(UpdateCustomerDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Prefer the stable primary key. Legacy clients that only know the
        // phone (pre-Day-4 contract) can omit Id; we fall back to per-market
        // phone lookup so their requests don't break. When Id IS supplied we
        // always use it — Phone may be changing in this same request.
        Customer? customer;
        if (request.Id.HasValue && request.Id.Value != Guid.Empty)
        {
            customer = await _context.Customers
                .FirstOrDefaultAsync(c => c.Id == request.Id.Value && c.MarketId == marketId, cancellationToken);
        }
        else
        {
            if (string.IsNullOrWhiteSpace(request.Phone)) return null;
            customer = await _context.Customers
                .FirstOrDefaultAsync(c => c.Phone == request.Phone && c.MarketId == marketId, cancellationToken);
        }

        if (customer is null)
            return null;

        var changed = false;

        if (request.FullName is not null && request.FullName != customer.FullName)
        {
            customer.FullName = request.FullName;
            changed = true;
        }

        // Only treat Phone as an UPDATE target when the caller passed Id (i.e.
        // the legacy phone-lookup path can't accidentally rename the customer).
        if (request.Id.HasValue && request.Id.Value != Guid.Empty
            && !string.IsNullOrWhiteSpace(request.Phone)
            && request.Phone != customer.Phone)
        {
            var phoneTaken = await _context.Customers.AnyAsync(
                c => c.Phone == request.Phone && c.MarketId == marketId && c.Id != customer.Id,
                cancellationToken);
            if (phoneTaken)
                throw new InvalidOperationException($"'{request.Phone}' telefoni allaqachon boshqa mijozga tegishli.");
            customer.Phone = request.Phone;
            changed = true;
        }

        if (changed)
        {
            await _context.SaveChangesAsync(cancellationToken);
        }

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<bool> DeleteCustomerAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ⭐ CRITICAL FIX: Use direct database query instead of UnitOfWork.FindAsync
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Id == id && c.MarketId == marketId, cancellationToken);

        if (customer is null)
            return false;

        // Soft delete related sales
        var sales = await _context.Sales
            .Where(s => s.CustomerId == id && s.MarketId == marketId)
            .ToListAsync(cancellationToken);

        foreach (var sale in sales)
        {
            sale.IsDeleted = true;
        }

        // Close related debts (mark as Closed since Debt doesn't have IsDeleted)
        var debts = await _context.Debts
            .Where(d => d.CustomerId == id && d.MarketId == marketId && d.Status == DebtStatus.Open)
            .ToListAsync(cancellationToken);

        foreach (var debt in debts)
        {
            debt.Status = DebtStatus.Closed;
        }

        // Use soft delete instead of hard delete to avoid foreign key constraint violations
        customer.IsDeleted = true;
        _context.Customers.Update(customer);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<CustomerDeleteInfoDto> GetCustomerDeleteInfoAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ⭐ CRITICAL FIX: Use direct database query instead of UnitOfWork.FindAsync
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Id == id && c.MarketId == marketId, cancellationToken);
        if (customer is null)
        {
            return new CustomerDeleteInfoDto(
                false,
                0,
                0,
                0,
                0,
                "Mijoz topilmadi"
            );
        }

        // Count all sales (including drafts)
        var salesCount = await _context.Sales
            .Where(s => s.CustomerId == id && s.MarketId == marketId && !s.IsDeleted)
            .CountAsync(cancellationToken);

        // Count draft sales
        var draftSalesCount = await _context.Sales
            .Where(s => s.CustomerId == id && s.MarketId == marketId && !s.IsDeleted && s.Status == SaleStatus.Draft)
            .CountAsync(cancellationToken);

        // Count open debts
        var debtsCount = await _context.Debts
            .Where(d => d.CustomerId == id && d.MarketId == marketId && d.Status == DebtStatus.Open)
            .CountAsync(cancellationToken);

        // Calculate total debt
        var totalDebt = await _context.Debts
            .Where(d => d.CustomerId == id && d.MarketId == marketId && d.Status == DebtStatus.Open)
            .SumAsync(d => d.RemainingDebt, cancellationToken);

        // Build warning message
        var warningParts = new List<string>();
        if (salesCount > 0)
            warningParts.Add($"{salesCount} ta savdo");
        if (debtsCount > 0)
            warningParts.Add($"{debtsCount} ta qarz (jami {totalDebt:N0} so'm)");

        var warningMessage = warningParts.Count > 0
            ? $"Mijozni o'chirish bilan unga tegishli {string.Join(" va ", warningParts)} ham o'chib ketadi. Davom etasizmi?"
            : null;

        var canDelete = salesCount == 0 && debtsCount == 0;

        return new CustomerDeleteInfoDto(
            canDelete,
            salesCount,
            draftSalesCount,
            debtsCount,
            totalDebt,
            warningMessage
        );
    }

    public async Task<bool> SoftDeleteCustomerAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ⭐ CRITICAL FIX: Use direct database query instead of UnitOfWork.FindAsync
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Id == id && c.MarketId == marketId, cancellationToken);

        if (customer is null)
            return false;

        customer.IsDeleted = true;
        _context.Customers.Update(customer);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task<CustomerDto> MapToDtoAsync(Customer customer, CancellationToken cancellationToken)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Direct query for debts - more reliable than Include with Where
        var debts = await _context.Debts
            .Where(d => d.CustomerId == customer.Id
                && d.MarketId == marketId
                && d.Status == DebtStatus.Open)
            .ToListAsync(cancellationToken);

        var totalDebt = debts.Sum(d => d.RemainingDebt);

        return new CustomerDto(
            customer.Id,
            customer.Phone,
            customer.FullName,
            customer.Comment,
            totalDebt
        );
    }

    /// <summary>
    /// Gets customer's available credit from negative payments (refunds)
    /// This is used to auto-apply credits to new sales
    /// </summary>
    public async Task<decimal> GetAvailableCreditAsync(Guid customerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var saleIds = await _context.Sales
            .Where(s => s.CustomerId == customerId && s.MarketId == marketId)
            .Select(s => s.Id)
            .ToListAsync(cancellationToken);

        if (saleIds.Count == 0)
            return 0;

        // Refunds (negative payments) add to credit; Credit-typed payments consume it.
        // Net credit = |sum(negative)| - sum(PaymentType.Credit)
        var refundTotal = await _context.Payments
            .Where(p => saleIds.Contains(p.SaleId) && p.MarketId == marketId && p.Amount < 0)
            .SumAsync(p => p.Amount, cancellationToken);

        var creditConsumed = await _context.Payments
            .Where(p => saleIds.Contains(p.SaleId) && p.MarketId == marketId && p.PaymentType == PaymentType.Credit)
            .SumAsync(p => p.Amount, cancellationToken);

        var net = Math.Abs(refundTotal) - creditConsumed;
        return net > 0 ? net : 0;
    }
}
