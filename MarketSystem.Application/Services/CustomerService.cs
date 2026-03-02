using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;

namespace MarketSystem.Application.Services;

public class CustomerService : ICustomerService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly AppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CustomerService(IUnitOfWork unitOfWork, AppDbContext context, ICurrentMarketService currentMarketService, IHttpContextAccessor httpContextAccessor)
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

        // ⭐ CRITICAL FIX: Use direct database query instead of UnitOfWork.FindAsync
        // FindAsync caches results in memory, causing stale data issues
        var customers = await _context.Customers
            .Where(c => c.MarketId == marketId && !c.IsDeleted)
            .OrderBy(c => c.FullName)
            .ToListAsync(cancellationToken);

        var result = new List<CustomerDto>();

        foreach (var customer in customers)
        {
            var dto = await MapToDtoAsync(customer, cancellationToken);
            Console.WriteLine($"📊 [Backend] Customer: {dto.FullName} ({dto.Phone}), TotalDebt: {dto.TotalDebt}");
            result.Add(dto);
        }

        return result;
    }

    public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto request, CancellationToken cancellationToken = default)
    {
        // Check if phone already exists
        if (await _context.Customers.AnyAsync(c => c.Phone == request.Phone, cancellationToken))
            throw new InvalidOperationException($"Customer with phone '{request.Phone}' already exists");

        var customer = new Customer
        {
            Id = Guid.NewGuid(),
            Phone = request.Phone,
            FullName = request.FullName,
            Comment = request.Comment,
            IsDeleted = false,
            MarketId = _currentMarketService.GetCurrentMarketId()  // Multi-tenancy
        };

        await _context.Customers.AddAsync(customer, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);

        // Agar initial debt bor bo'lsa, dummy Sale va Debt yozuvlarini yaratamiz
        if (request.InitialDebt.HasValue && request.InitialDebt.Value > 0)
        {
            var marketId = _currentMarketService.GetCurrentMarketId();
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

        // ⭐ CRITICAL FIX: Use direct database query instead of UnitOfWork.FindAsync
        var customer = await _context.Customers
            .FirstOrDefaultAsync(c => c.Phone == request.Phone && c.MarketId == marketId, cancellationToken);

        if (customer is null)
            return null;

        // Only update FullName if provided
        if (request.FullName is not null)
        {
            customer.FullName = request.FullName;
            _context.Entry(customer).State = EntityState.Modified;
            _context.Customers.Update(customer);
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
        _context.Entry(customer).State = EntityState.Modified;
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

        // 🔍 DEBUG: Log each debt found
        Console.WriteLine($"🔍 [MapToDto] Customer: {customer.FullName} ({customer.Phone})");
        Console.WriteLine($"   Found {debts.Count} open debts:");
        foreach (var debt in debts)
        {
            Console.WriteLine($"   - DebtId: {debt.Id}, SaleId: {debt.SaleId}, TotalDebt: {debt.TotalDebt}, RemainingDebt: {debt.RemainingDebt}, Status: {debt.Status}");
        }

        var totalDebt = debts.Sum(d => d.RemainingDebt);
        Console.WriteLine($"   ✅ Calculated TotalDebt: {totalDebt}");

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

        // Find all sales for this customer
        var saleIds = await _context.Sales
            .Where(s => s.CustomerId == customerId && s.MarketId == marketId)
            .Select(s => s.Id)
            .ToListAsync(cancellationToken);

        if (saleIds.Count == 0)
            return 0;

        // Sum all negative payments (refunds) for these sales
        var availableCredit = await _context.Payments
            .Where(p => saleIds.Contains(p.SaleId) && p.MarketId == marketId && p.Amount < 0)
            .SumAsync(p => p.Amount, cancellationToken);

        // Convert negative sum to positive credit amount
        return Math.Abs(availableCredit);
    }
}
