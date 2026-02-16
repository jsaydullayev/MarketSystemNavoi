using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Application.Interfaces;
using Microsoft.Extensions.Logging;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using MarketSystem.Domain.Common;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace MarketSystem.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IJwtService _jwtService;
    private readonly ILogger<AuthService> _logger;
    private readonly AppDbContext _context;
    private readonly JwtSetting _jwtSetting;
    private readonly ICurrentMarketService _currentMarketService;

    public AuthService(IUnitOfWork unitOfWork, IJwtService jwtService, ILogger<AuthService> logger, AppDbContext context, IConfiguration configuration, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _jwtService = jwtService;
        _logger = logger;
        _context = context;
        _jwtSetting = configuration.GetSection("Jwt").Get<JwtSetting>()!;
        _currentMarketService = currentMarketService;
    }

    public async Task<AuthResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Login attempt for username: {Username}", request.Username);

        var users = await _unitOfWork.Users.FindAsync(u => u.Username == request.Username && u.IsActive, cancellationToken);
        var user = users.FirstOrDefault();

        if (user is null)
        {
            _logger.LogWarning("User not found or inactive: {Username}", request.Username);
            return null;
        }

        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            _logger.LogWarning("Invalid password for user: {Username}", request.Username);
            return null;
        }

        _logger.LogInformation("Login successful for user: {Username}, ID: {UserId}", user.Username, user.Id);
        return await GenerateAuthResponseAsync(user, cancellationToken);
    }

    public async Task<AuthResponse?> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Register attempt for username: {Username}", request.Username);

        // Check if username already exists
        if (await _unitOfWork.Users.AnyAsync(u => u.Username == request.Username, cancellationToken))
        {
            _logger.LogWarning("Username already exists: {Username}", request.Username);
            throw new InvalidOperationException($"Username '{request.Username}' already exists");
        }

        // Map language codes to Language enum
        Language language = request.Language?.ToLowerInvariant() switch
        {
            "uz" => Language.Uzbek,
            "ru" => Language.Russian,
            _ => Language.Uzbek // Default to Uzbek
        };

        // For registration, marketId comes from request (when Admin/Owner creates user)
        // For Owner self-registration with marketName, market will be created below
        int? marketId = request.MarketId;

        // Generate user ID early
        var userId = Guid.NewGuid();

        // Create user FIRST (without MarketId initially)
        var role = Enum.Parse<Role>(request.Role, ignoreCase: true);
        var user = new User
        {
            Id = userId,
            FullName = request.FullName,
            Username = request.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = role,
            Language = language,
            IsActive = true,
            MarketId = null  // Will be set after market is created
        };

        await _unitOfWork.Users.AddAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("User created: {Username}, ID: {UserId}", user.Username, user.Id);

        // Create market for EVERY new user (regardless of role)
        // If no marketId provided, create new market automatically
        if (marketId == null)
        {
            // Generate market name from user's full name or provided marketName
            string marketName = !string.IsNullOrWhiteSpace(request.MarketName)
                ? request.MarketName
                : $"{user.FullName}'s Market";

            // Generate unique subdomain from username
            string subdomain = $"{user.Username.ToLower().Replace("@", "").Replace(".", "")}{Guid.NewGuid().ToString("N")[..6]}";

            var newMarket = new Market
            {
                Name = marketName,
                Subdomain = subdomain,
                IsActive = true,
                OwnerId = userId  // Every user is the owner of their own market
            };

            await _context.Markets.AddAsync(newMarket, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);

            marketId = newMarket.Id;
            _logger.LogInformation("New market created for user: {Username}, Market: {MarketName}, ID: {MarketId}", user.Username, newMarket.Name, newMarket.Id);
        }

        // Update user with MarketId
        user.MarketId = marketId;
        _context.Entry(user).State = EntityState.Modified;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("User registered successfully: {Username}, ID: {UserId}", user.Username, user.Id);
        return await GenerateAuthResponseAsync(user, cancellationToken);
    }

    public async Task<AuthResponse?> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
    {
        // Validate access token
        var (isValid, userIdStr) = _jwtService.ValidateAndGetUser(request.AccessToken);
        if (!isValid || userIdStr is null)
            return null;

        var userId = Guid.Parse(userIdStr);

        // Get refresh token
        var refreshToken = await _unitOfWork.RefreshTokens
            .GetByTokenAsync(request.RefreshToken, cancellationToken);

        if (refreshToken is null || refreshToken.IsUsed || refreshToken.IsRevoked || refreshToken.ExpiresAt < DateTime.UtcNow)
            return null;

        // Get user
        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken);
        if (user is null || !user.IsActive)
            return null;

        // Mark current refresh token as used
        refreshToken.IsUsed = true;
        _context.Entry(refreshToken).State = EntityState.Modified;
        _unitOfWork.RefreshTokens.Update(refreshToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Revoke all old refresh tokens for this user
        await _unitOfWork.RefreshTokens.RevokeAllForUserAsync(user.Id, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Generate new tokens
        return await GenerateAuthResponseAsync(user, cancellationToken);
    }

    public async Task<bool> LogoutAsync(string refreshToken, CancellationToken cancellationToken = default)
    {
        var token = await _unitOfWork.RefreshTokens
            .GetByTokenAsync(refreshToken, cancellationToken);

        if (token is null)
            return false;

        // Revoke the refresh token
        token.IsRevoked = true;
        token.RevokedAt = DateTime.UtcNow;
        _unitOfWork.RefreshTokens.Update(token);

        // Revoke all other refresh tokens for this user
        await _unitOfWork.RefreshTokens.RevokeAllForUserAsync(token.UserId, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    private async Task<AuthResponse> GenerateAuthResponseAsync(User user, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("Generating tokens for user: {UserId}, {Username}", user.Id, user.Username);

            var accessToken = _jwtService.GenerateToken(user, true);
            var refreshToken = GenerateRefreshToken();

            var refreshTokenEntity = new RefreshToken
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Token = refreshToken,
                ExpiresAt = DateTime.UtcNow.AddDays(_jwtSetting.RefreshTokenExpireDays),
                IsUsed = false,
                IsRevoked = false
            };

            await _unitOfWork.RefreshTokens.AddAsync(refreshTokenEntity, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Tokens generated successfully for user: {UserId}", user.Id);

            // Map Language enum to ISO language codes
            string languageCode = user.Language switch
            {
                Language.Uzbek => "uz",
                Language.Russian => "ru",
                _ => "uz" // Default to Uzbek
            };

            return new AuthResponse(
                user.Id,
                user.Username,
                user.FullName,
                user.Role.ToString(),
                languageCode,
                accessToken.AccessToken,
                refreshToken,
                DateTime.UtcNow.AddHours(_jwtSetting.AccessTokenExpireHours)
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating tokens for user: {UserId}", user.Id);
            throw;
        }
    }

    private static string GenerateRefreshToken()
    {
        var randomBytes = new byte[64];
        using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
        rng.GetBytes(randomBytes);
        return Convert.ToBase64String(randomBytes);
    }
}
