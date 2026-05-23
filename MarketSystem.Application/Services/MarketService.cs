using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using CommonDTOs = MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Services;

public class MarketService : IMarketService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<MarketService> _logger;
    private readonly IAppDbContext _context;

    public MarketService(IUnitOfWork unitOfWork, ILogger<MarketService> logger, IAppDbContext context)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _context = context;
    }

    public async Task<MarketDto?> CreateMarketAsync(CreateMarketRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Creating new market: {MarketName}", request.Name);

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

        return await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            // 1. Owner user yaratish (Id avval kerak)
            var owner = new User
            {
                Id = Guid.NewGuid(),
                FullName = request.AdminFullName,
                Username = request.AdminUsername,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.AdminPassword),
                Role = Role.Owner,
                Language = Language.Uzbek,
                IsActive = true
            };
            await _unitOfWork.Users.AddAsync(owner, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // 2. Market yaratish — OwnerId bilan
            var market = new Market
            {
                Name = request.Name,
                Subdomain = request.Subdomain,
                Description = request.Description,
                IsActive = true,
                ExpiresAt = request.ExpiresAt,
                CreatedAt = DateTime.UtcNow,
                OwnerId = owner.Id
            };
            _context.Markets.Add(market);
            await _context.SaveChangesAsync(cancellationToken);

            // 3. Owner'ga MarketId biriktirish
            owner.MarketId = market.Id;
            _unitOfWork.Users.Update(owner);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Market {MarketId} va owner {Username} yaratildi", market.Id, owner.Username);

            return new MarketDto(
                market.Id,
                market.Name,
                market.Subdomain,
                market.Description,
                market.IsActive,
                market.ExpiresAt,
                market.CreatedAt
            );
        }, cancellationToken);
    }

    public async Task<RegisterMarketResponse?> RegisterMarketForOwnerAsync(RegisterMarketRequest request, Guid ownerId, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Owner {OwnerId} registering new market: {MarketName}", ownerId, request.Name);

        // 1. Check if Owner already has a market
        var owner = await _unitOfWork.Users.GetByIdAsync(ownerId, cancellationToken);
        if (owner is null)
            throw new InvalidOperationException("Foydalanuvchi topilmadi");

        if (owner.Role != Role.Owner)
            throw new InvalidOperationException("Faqat Owner rolidagi foydalanuvchilar market registratsiya qilishi mumkin");

        if (owner.MarketId.HasValue)
            throw new InvalidOperationException("Siz allaqachon marketga tegishlisiz. Bir nechta marketga ega bo'la olmaysiz.");

        // 2. Check if subdomain already exists
        if (!string.IsNullOrEmpty(request.Subdomain))
        {
            var existingSubdomain = await _context.Markets
                .AnyAsync(m => m.Subdomain == request.Subdomain, cancellationToken);
            if (existingSubdomain)
            {
                _logger.LogWarning("Subdomain already exists: {Subdomain}", request.Subdomain);
                throw new InvalidOperationException($"Subdomain '{request.Subdomain}' allaqachon mavjud");
            }
        }

        // 3. Create Market AND link the owner atomically.
        // Y4 — previously: two separate SaveChanges back-to-back. If the
        // second one (linking owner.MarketId) failed for any reason, the
        // Market row was already persisted but the owner believed they had
        // none — their next register attempt would 23505 on the subdomain
        // unique index, leaving them stuck. Wrap both writes in one
        // transaction so either both land or neither does.
        var market = new Market
        {
            Id = 0, // Auto-increment
            Name = request.Name,
            Subdomain = request.Subdomain,
            Description = request.Description,
            IsActive = true,
            ExpiresAt = request.ExpiresAt,
            CreatedAt = DateTime.UtcNow,
            OwnerId = ownerId  // Set OwnerId to link market to owner
        };

        await _unitOfWork.ExecuteInTransactionAsync(async () =>
        {
            _context.Markets.Add(market);
            await _context.SaveChangesAsync(cancellationToken);

            owner.MarketId = market.Id;
            _unitOfWork.Users.Update(owner);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
        }, cancellationToken);

        _logger.LogInformation("Owner {OwnerId} linked to market {MarketId}", ownerId, market.Id);

        // 5. Return response with market and updated owner
        var marketDto = new MarketDto(
            market.Id,
            market.Name,
            market.Subdomain,
            market.Description,
            market.IsActive,
            market.ExpiresAt,
            market.CreatedAt
        );

        var ownerDto = new CommonDTOs.UserDto(
            owner.Id,
            owner.FullName,
            owner.Username,
            owner.ProfileImage,
            owner.Role.ToString(),
            owner.Language.ToString().ToLowerInvariant(),
            owner.IsActive,
            owner.MarketId,
            owner.ShiftStatus.ToString(),
            owner.ShiftStartUtc,
            owner.ShiftEndUtc,
            owner.IsShiftActiveNow(),
            owner.GetEffectivePermissions()
        );

        return new RegisterMarketResponse(marketDto, ownerDto);
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
