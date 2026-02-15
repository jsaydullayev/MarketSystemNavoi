using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Application.Services;

public class MarketService : IMarketService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<MarketService> _logger;
    private readonly AppDbContext _context;

    public MarketService(IUnitOfWork unitOfWork, ILogger<MarketService> logger, AppDbContext context)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _context = context;
    }

    public async Task<MarketDto?> CreateMarketAsync(CreateMarketRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Creating new market: {MarketName}", request.Name);

        // 1. Check if subdomain already exists
        if (!string.IsNullOrEmpty(request.Subdomain))
        {
            var existingSubdomain = await _context.Markets
                .AnyAsync(m => m.Subdomain == request.Subdomain, cancellationToken);
            if (existingSubdomain)
            {
                _logger.LogWarning("Subdomain already exists: {Subdomain}", request.Subdomain);
                throw new InvalidOperationException($"Subdomain '{request.Subdomain}' already exists");
            }
        }

        // 2. Create Market
        var market = new Market
        {
            Id = 0, // Auto-increment
            Name = request.Name,
            Subdomain = request.Subdomain,
            Description = request.Description,
            IsActive = true,
            ExpiresAt = request.ExpiresAt,
            CreatedAt = DateTime.UtcNow
        };

        _context.Markets.Add(market);
        await _context.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Market created with ID: {MarketId}", market.Id);

        // 3. Create Owner user for this market
        var owner = new User
        {
            Id = Guid.NewGuid(),
            FullName = request.AdminFullName,
            Username = request.AdminUsername,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.AdminPassword),
            Role = Role.Owner,
            Language = Language.Uzbek,
            IsActive = true,
            MarketId = market.Id
        };

        await _unitOfWork.Users.AddAsync(owner, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Owner user created for market {MarketId}: {Username}", market.Id, owner.Username);

        return new MarketDto(
            market.Id,
            market.Name,
            market.Subdomain,
            market.Description,
            market.IsActive,
            market.ExpiresAt,
            market.CreatedAt
        );
    }

    public async Task<List<MarketDto>> GetAllMarketsAsync(CancellationToken cancellationToken = default)
    {
        var markets = await _context.Markets
            .OrderBy(m => m.Name)
            .ToListAsync(cancellationToken);

        return markets.Select(m => new MarketDto(
            m.Id,
            m.Name,
            m.Subdomain,
            m.Description,
            m.IsActive,
            m.ExpiresAt,
            m.CreatedAt
        )).ToList();
    }

    public async Task<MarketDto?> GetMarketByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var market = await _context.Markets.FindAsync(id, cancellationToken);
        if (market is null) return null;

        return new MarketDto(
            market.Id,
            market.Name,
            market.Subdomain,
            market.Description,
            market.IsActive,
            market.ExpiresAt,
            market.CreatedAt
        );
    }

    public async Task<bool> UpdateMarketAsync(int id, string name, string? description, CancellationToken cancellationToken = default)
    {
        var market = await _context.Markets.FindAsync(id, cancellationToken);
        if (market is null) return false;

        market.Name = name;
        market.Description = description;

        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeleteMarketAsync(int id, CancellationToken cancellationToken = default)
    {
        var market = await _context.Markets.FindAsync(id, cancellationToken);
        if (market is null) return false;

        _context.Markets.Remove(market);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }
}
