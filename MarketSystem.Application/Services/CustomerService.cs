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

        var customers = await _unitOfWork.Customers.FindAsync(
            c => c.Id == id && c.MarketId == marketId,
            cancellationToken);

        var customer = customers.FirstOrDefault();

        if (customer is null)
            return null;

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<CustomerDto?> GetCustomerByPhoneAsync(string phone, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var customers = await _unitOfWork.Customers.FindAsync(
            c => c.Phone == phone && c.MarketId == marketId,
            cancellationToken);

        var customer = customers.FirstOrDefault();
        if (customer is null)
            return null;

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<IEnumerable<CustomerDto>> GetAllCustomersAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var customers = await _unitOfWork.Customers.FindAsync(
            c => c.MarketId == marketId,
            cancellationToken);

        var result = new List<CustomerDto>();

        foreach (var customer in customers)
        {
            result.Add(await MapToDtoAsync(customer, cancellationToken));
        }

        return result;
    }

    public async Task<CustomerDto> CreateCustomerAsync(CreateCustomerDto request, CancellationToken cancellationToken = default)
    {
        // Check if phone already exists
        if (await _unitOfWork.Customers.AnyAsync(c => c.Phone == request.Phone, cancellationToken))
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

        await _unitOfWork.Customers.AddAsync(customer, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

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

            await _unitOfWork.Sales.AddAsync(dummySale, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

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

            await _unitOfWork.Debts.AddAsync(debt, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<CustomerDto?> UpdateCustomerAsync(UpdateCustomerDto request, CancellationToken cancellationToken = default)
    {
        // Find customer by phone number
        var customers = await _unitOfWork.Customers.FindAsync(
            c => c.Phone == request.Phone,
            cancellationToken);
        var customer = customers.FirstOrDefault();

        if (customer is null)
            return null;

        // Only update FullName if provided
        if (request.FullName is not null)
        {
            customer.FullName = request.FullName;
            _context.Entry(customer).State = EntityState.Modified;
            _unitOfWork.Customers.Update(customer);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }

        return await MapToDtoAsync(customer, cancellationToken);
    }

    public async Task<bool> DeleteCustomerAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var customers = await _unitOfWork.Customers.FindAsync(
            c => c.Id == id && c.MarketId == marketId,
            cancellationToken);
        var customer = customers.FirstOrDefault();

        if (customer is null)
            return false;

        // Use soft delete instead of hard delete to avoid foreign key constraint violations
        customer.IsDeleted = true;
        _unitOfWork.Customers.Update(customer);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> SoftDeleteCustomerAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var customers = await _unitOfWork.Customers.FindAsync(
            c => c.Id == id && c.MarketId == marketId,
            cancellationToken);
        var customer = customers.FirstOrDefault();

        if (customer is null)
            return false;

        customer.IsDeleted = true;
        _context.Entry(customer).State = EntityState.Modified;
        _unitOfWork.Customers.Update(customer);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
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
}
