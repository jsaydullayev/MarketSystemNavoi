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
    private readonly IRevokedTokenStore _revokedTokens;

    public AuthService(
        IUnitOfWork unitOfWork,
        IJwtService jwtService,
        ILogger<AuthService> logger,
        AppDbContext context,
        IConfiguration configuration,
        ICurrentMarketService currentMarketService,
        IRevokedTokenStore revokedTokens)
    {
        _unitOfWork = unitOfWork;
        _jwtService = jwtService;
        _logger = logger;
        _context = context;
        _jwtSetting = configuration.GetSection("Jwt").Get<JwtSetting>()!;
        _currentMarketService = currentMarketService;
        _revokedTokens = revokedTokens;
    }

    public async Task<AuthResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Login attempt for username: {Username}", request.Username);

        // Username uniqueness is enforced PER MARKET (partial index). A tenant user and a
        // cross-tenant user (e.g. SuperAdmin with MarketId=NULL) can therefore share the same
        // username. Iterate all candidates and pick the one whose password hash matches.
        // This is constant-time-ish (BCrypt.Verify per candidate) and there are at most a
        // handful of collisions in practice.
        var candidates = (await _unitOfWork.Users.FindAsync(
            u => u.Username == request.Username && u.IsActive,
            cancellationToken)).ToList();

        if (candidates.Count == 0)
        {
            _logger.LogWarning("User not found or inactive: {Username}", request.Username);
            return null;
        }

        User? matched = null;
        foreach (var candidate in candidates)
        {
            if (BCrypt.Net.BCrypt.Verify(request.Password, candidate.PasswordHash))
            {
                if (matched is not null)
                {
                    // Two distinct accounts share the same username AND password.
                    // Refuse to log in rather than guess which identity to grant.
                    _logger.LogError("Ambiguous login: multiple users with username {Username} accepted the same password", request.Username);
                    return null;
                }
                matched = candidate;
            }
        }

        if (matched is null)
        {
            _logger.LogWarning("Invalid password for user: {Username}", request.Username);
            return null;
        }

        _logger.LogInformation("Login successful for user: {Username}, ID: {UserId}", matched.Username, matched.Id);
        return await GenerateAuthResponseAsync(matched, cancellationToken);
    }

    public async Task<AuthResponse?> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Register attempt for username: {Username}", request.Username);

        // Public self-registration always creates an Owner with a new market.
        // Role from the request body is IGNORED to prevent privilege escalation
        // (admin/seller creation must go through an authenticated admin endpoint).
        if (await _unitOfWork.Users.AnyAsync(u => u.Username == request.Username, cancellationToken))
        {
            _logger.LogWarning("Username already exists: {Username}", request.Username);
            throw new InvalidOperationException($"Username '{request.Username}' already exists");
        }

        Language language = request.Language?.ToLowerInvariant() switch
        {
            "uz" => Language.Uzbek,
            "ru" => Language.Russian,
            _ => Language.Uzbek
        };

        var userId = Guid.NewGuid();

        var user = new User
        {
            Id = userId,
            FullName = request.FullName,
            Username = request.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = Role.Owner,
            Language = language,
            IsActive = true,
            MarketId = null
        };

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                await _unitOfWork.Users.AddAsync(user, cancellationToken);
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                string marketName = !string.IsNullOrWhiteSpace(request.MarketName)
                    ? request.MarketName
                    : $"{user.FullName}'s Market";

                var sanitizedUsername = new string(user.Username.ToLower().Where(c => char.IsLetterOrDigit(c)).ToArray());
                if (string.IsNullOrEmpty(sanitizedUsername))
                    sanitizedUsername = "market";
                string subdomain = $"{sanitizedUsername}{Guid.NewGuid().ToString("N")[..6]}";

                var newMarket = new Market
                {
                    Name = marketName,
                    Subdomain = subdomain,
                    IsActive = true,
                    OwnerId = userId
                };

                await _context.Markets.AddAsync(newMarket, cancellationToken);
                await _context.SaveChangesAsync(cancellationToken);

                // Seed the per-market CashRegister immediately so the first sale can't race
                // two parallel inserts into a UNIQUE-violation. 1 Market → exactly 1 Register.
                _context.CashRegisters.Add(new CashRegister
                {
                    Id = Guid.NewGuid(),
                    MarketId = newMarket.Id,
                    CurrentBalance = 0m,
                    LastUpdated = DateTime.UtcNow
                });

                user.MarketId = newMarket.Id;
                _context.Entry(user).State = EntityState.Modified;
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                await tx.CommitAsync(cancellationToken);

                _logger.LogInformation("User registered successfully: {Username}, ID: {UserId}, MarketId: {MarketId}", user.Username, user.Id, newMarket.Id);

                return await GenerateAuthResponseAsync(user, cancellationToken);
            }
            catch
            {
                await tx.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    public async Task<AuthResponse?> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default)
    {
        var (isValid, userIdStr) = _jwtService.ValidateAndGetUser(request.AccessToken);
        if (!isValid || userIdStr is null || !Guid.TryParse(userIdStr, out var userId))
            return null;

        var refreshToken = await _unitOfWork.RefreshTokens
            .GetByTokenAsync(request.RefreshToken, cancellationToken);

        if (refreshToken is null || refreshToken.IsUsed || refreshToken.IsRevoked || refreshToken.ExpiresAt < DateTime.UtcNow)
            return null;

        // Ensure the refresh token belongs to the same user as the access token.
        if (refreshToken.UserId != userId)
        {
            _logger.LogWarning("Refresh token user mismatch. AccessTokenUser={AccessUser} RefreshTokenUser={RefreshUser}", userId, refreshToken.UserId);
            // Defensive: revoke the leaked refresh token to limit blast radius.
            refreshToken.IsRevoked = true;
            refreshToken.RevokedAt = DateTime.UtcNow;
            _unitOfWork.RefreshTokens.Update(refreshToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            return null;
        }

        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken);
        if (user is null || !user.IsActive)
            return null;

        // Mark current refresh token as used (one-time use)
        refreshToken.IsUsed = true;
        _context.Entry(refreshToken).State = EntityState.Modified;
        _unitOfWork.RefreshTokens.Update(refreshToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Revoke the OLD access token's jti so the previous bearer can no
        // longer hit authenticated endpoints with it. Without this, an attacker
        // who phished the access token would keep working access until the
        // natural 30-minute TTL expires even after the legitimate user refreshed.
        var oldToken = _jwtService.GetJtiAndExpiry(request.AccessToken);
        if (oldToken is { } ot)
        {
            _revokedTokens.Revoke(ot.Jti, ot.ExpiresAtUtc);
        }

        return await GenerateAuthResponseAsync(user, cancellationToken);
    }

    public async Task<bool> LogoutAsync(string refreshToken, Guid callerUserId, string? accessTokenJti, DateTime? accessTokenExpiry, CancellationToken cancellationToken = default)
    {
        var token = await _unitOfWork.RefreshTokens
            .GetByTokenAsync(refreshToken, cancellationToken);

        if (token is null || token.UserId != callerUserId)
            return false;

        token.IsRevoked = true;
        token.RevokedAt = DateTime.UtcNow;
        _unitOfWork.RefreshTokens.Update(token);

        await _unitOfWork.RefreshTokens.RevokeAllForUserAsync(token.UserId, cancellationToken);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Revoke the access token that authenticated this logout call too,
        // otherwise it would remain usable for the rest of its 30-min TTL.
        if (!string.IsNullOrEmpty(accessTokenJti) && accessTokenExpiry.HasValue)
        {
            _revokedTokens.Revoke(accessTokenJti, accessTokenExpiry.Value);
        }

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

            string languageCode = user.Language switch
            {
                Language.Uzbek => "uz",
                Language.Russian => "ru",
                _ => "uz"
            };

            return new AuthResponse(
                user.Id,
                user.Username,
                user.FullName,
                user.Role.ToString(),
                languageCode,
                accessToken.AccessToken,
                refreshToken,
                DateTime.UtcNow.AddMinutes(_jwtSetting.AccessTokenExpireMinutes)
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
