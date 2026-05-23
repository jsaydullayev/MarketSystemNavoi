using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Application.Interfaces;
using Microsoft.Extensions.Logging;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Application.Settings;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;

namespace MarketSystem.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IJwtService _jwtService;
    private readonly ILogger<AuthService> _logger;
    private readonly IAppDbContext _context;
    private readonly JwtSetting _jwtSetting;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly IRevokedTokenStore _revokedTokens;
    private readonly IAuditLogService _auditLogService;
    private readonly ILoginAttemptTracker _loginAttempts;

    // S6 — a real BCrypt hash we verify against when the username is unknown
    // so the response time is indistinguishable from a real-user-wrong-password
    // path (BCrypt.Verify is the dominant cost — ~100 ms at cost factor 11).
    // Computed once at type init so the value's well-formed; we never compare
    // any real input against it and the original plaintext is discarded.
    private static readonly string DummyBcryptHash =
        BCrypt.Net.BCrypt.HashPassword(Guid.NewGuid().ToString());

    public AuthService(
        IUnitOfWork unitOfWork,
        IJwtService jwtService,
        ILogger<AuthService> logger,
        IAppDbContext context,
        IConfiguration configuration,
        ICurrentMarketService currentMarketService,
        IRevokedTokenStore revokedTokens,
        IAuditLogService auditLogService,
        ILoginAttemptTracker loginAttempts)
    {
        _unitOfWork = unitOfWork;
        _jwtService = jwtService;
        _logger = logger;
        _context = context;
        _jwtSetting = configuration.GetSection("Jwt").Get<JwtSetting>()!;
        _currentMarketService = currentMarketService;
        _revokedTokens = revokedTokens;
        _auditLogService = auditLogService;
        _loginAttempts = loginAttempts;
    }

    public async Task<AuthResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Login attempt for username: {Username}", request.Username);

        // Audit a failed authentication attempt. The username may not map to any
        // real account, so userId is unknown — Guid.Empty is used and the username
        // travels in the payload; the client IP is captured by AuditLogService.
        // LogActionAsync swallows its own errors, so a failed audit never masks
        // the 401 nor breaks the login flow.
        Task LogLoginFailedAsync() => _auditLogService.LogActionAsync(
            AuditEntityTypes.Auth, Guid.Empty, AuditActions.LoginFailed, Guid.Empty,
            new { username = request.Username }, cancellationToken);

        // Record a failure against the brute-force tracker AND audit-log it.
        // If this failure tripped the threshold, surface a LoginLockedException
        // so the client sees "try again in N minutes" instead of yet another
        // generic 401 — and so an attacker enumerating passwords learns we
        // notice. The IP-based rate limiter still gates burst rates; this
        // catches a distributed attacker hitting one username from many IPs.
        async Task<AuthResponse?> RejectAndMaybeLockAsync()
        {
            await LogLoginFailedAsync();
            var attempt = _loginAttempts.RecordFailure(request.Username);
            if (attempt.LockedUntilUtc is { } lockedUntil)
            {
                _logger.LogWarning(
                    "Account locked after {Count} failures: {Username} until {Until:O}",
                    attempt.FailureCount, request.Username, lockedUntil);
                throw new MarketSystem.Domain.Exceptions.LoginLockedException(
                    request.Username, lockedUntil, attempt.FailureCount);
            }
            return null;
        }

        // Cheap lock check before touching the DB — a locked username should
        // not be able to keep timing the password hash.
        var lockedUntilUtc = _loginAttempts.GetLockedUntilUtc(request.Username);
        if (lockedUntilUtc is { } existingLockUntil)
        {
            _logger.LogWarning(
                "Login refused — account already locked until {Until:O}: {Username}",
                existingLockUntil, request.Username);
            await LogLoginFailedAsync();
            throw new MarketSystem.Domain.Exceptions.LoginLockedException(
                request.Username, existingLockUntil, 0);
        }

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
            // S6 — timing-attack mitigation. Without this, a missing-username
            // path returns ~instantly while a real-username-wrong-password
            // path takes the BCrypt.Verify hit (~100ms). That gap lets an
            // attacker enumerate valid usernames just by measuring latency.
            // Burn one verify against a fixed dummy hash so both paths spend
            // roughly the same wall time. We discard the result.
            _ = BCrypt.Net.BCrypt.Verify(request.Password, DummyBcryptHash);
            _logger.LogWarning("User not found or inactive: {Username}", request.Username);
            return await RejectAndMaybeLockAsync();
        }

        // P7 — short-circuit on the first BCrypt match. The old code verified
        // EVERY candidate against the same password just to detect the
        // "two users share both username AND password" edge case — astronomically
        // unlikely once you account for BCrypt's per-row salt, and worth at most
        // a warning, not a 100 ms × N hit on every login. With N=5 cross-tenant
        // username collisions that was a half-second wasted on every successful
        // login.
        if (candidates.Count > 1)
        {
            _logger.LogWarning(
                "Login {Username} resolved to {Count} candidate users — username collides across tenants",
                request.Username, candidates.Count);
        }
        User? matched = null;
        foreach (var candidate in candidates)
        {
            if (BCrypt.Net.BCrypt.Verify(request.Password, candidate.PasswordHash))
            {
                matched = candidate;
                break;
            }
        }

        if (matched is null)
        {
            _logger.LogWarning("Invalid password for user: {Username}", request.Username);
            return await RejectAndMaybeLockAsync();
        }

        // Market block check — reject login before issuing a token when the
        // tenant has been administratively blocked. SuperAdmin (MarketId=null)
        // bypasses this so the SuperAdmin can always reach the console even if
        // every tenant is blocked. The body of the 423 (built by the global
        // exception handler) carries the reason so the client can render
        // "Market blocked — contact admin" with context.
        if (matched.MarketId.HasValue)
        {
            var block = await _context.Markets
                .AsNoTracking()
                .Where(m => m.Id == matched.MarketId.Value)
                .Select(m => new { m.IsBlocked, m.BlockedAt, m.BlockedReason })
                .FirstOrDefaultAsync(cancellationToken);
            if (block is { IsBlocked: true })
            {
                _logger.LogWarning(
                    "Login blocked — market {MarketId} is blocked. User={Username} Reason={Reason}",
                    matched.MarketId, matched.Username, block.BlockedReason);
                throw new MarketSystem.Domain.Exceptions.MarketBlockedException(
                    matched.MarketId.Value, block.BlockedReason, block.BlockedAt);
            }
        }

        // Shift gate — a Seller whose shift is Blocked, or outside its
        // scheduled window, may not log in. Owner/Admin/SuperAdmin have no
        // shift so they are never gated here.
        if (matched.Role == Role.Seller && !matched.IsShiftActiveNow())
        {
            _logger.LogWarning("Login blocked — shift inactive for seller {Username}", matched.Username);
            throw new InvalidOperationException(
                "Ish smenangiz hozir faol emas. Administrator bilan bog'laning.");
        }

        _logger.LogInformation("Login successful for user: {Username}, ID: {UserId}", matched.Username, matched.Id);
        // Wipe the brute-force counter — a user who got the password right
        // after one typo shouldn't stay one failure closer to a lockout for
        // the next 15 minutes.
        _loginAttempts.RecordSuccess(request.Username);
        await _auditLogService.LogActionAsync(
            AuditEntityTypes.Auth, matched.Id, AuditActions.Login, matched.Id,
            new { username = matched.Username, role = matched.Role.ToString() }, cancellationToken);
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
                string subdomain = $"{sanitizedUsername}{Guid.NewGuid().ToString("N")[..12]}";

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
                await _unitOfWork.SaveChangesAsync(cancellationToken);

                await tx.CommitAsync(cancellationToken);

                _logger.LogInformation("User registered successfully: {Username}, ID: {UserId}, MarketId: {MarketId}", user.Username, user.Id, newMarket.Id);

                return await GenerateAuthResponseAsync(user, cancellationToken);
            }
            catch (Exception)
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

        if (refreshToken is null || refreshToken.ExpiresAt < DateTime.UtcNow)
            return null;

        // S1 — refresh-token rotation reuse detection (RFC 6749 §10.4 / OAuth
        // best-current-practice). If someone presents an ALREADY-USED or
        // REVOKED token, that's a strong signal of theft: the legitimate
        // user rotated it (or we revoked it on another security event) and
        // a second copy is now in the attacker's hand. Don't just refuse —
        // burn the entire family for that user so the attacker can't keep
        // refreshing with another stolen token from the same chain.
        if (refreshToken.IsUsed || refreshToken.IsRevoked)
        {
            _logger.LogWarning(
                "Refresh-token reuse detected for user {UserId} (token IsUsed={IsUsed}, IsRevoked={IsRevoked}). " +
                "Revoking ALL refresh tokens for this user as a defensive measure.",
                refreshToken.UserId, refreshToken.IsUsed, refreshToken.IsRevoked);
            await _unitOfWork.RefreshTokens.RevokeAllForUserAsync(refreshToken.UserId, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);
            await _auditLogService.LogActionAsync(
                AuditEntityTypes.Auth, refreshToken.UserId, AuditActions.LoginFailed, Guid.Empty,
                new { reason = "refresh_token_reuse_detected", tokenId = refreshToken.Id },
                cancellationToken);
            return null;
        }

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

        // Block-state check on refresh — without this, an owner whose market
        // gets blocked could keep issuing fresh access tokens (and bombarding
        // the TenantResolutionMiddleware with 423s) until the refresh token
        // itself expires. Surface the same MarketBlockedException as Login
        // so the client sees one consistent failure shape.
        if (user.MarketId.HasValue)
        {
            var block = await _context.Markets
                .AsNoTracking()
                .Where(m => m.Id == user.MarketId.Value && m.IsBlocked)
                .Select(m => new { m.BlockedAt, m.BlockedReason })
                .FirstOrDefaultAsync(cancellationToken);
            if (block != null)
            {
                _logger.LogWarning(
                    "Refresh denied — market {MarketId} is blocked. User={Username}",
                    user.MarketId, user.Username);
                throw new MarketSystem.Domain.Exceptions.MarketBlockedException(
                    user.MarketId.Value, block.BlockedReason, block.BlockedAt);
            }
        }

        // Shift gate — stop minting fresh tokens once a seller's shift ends
        // (e.g. a scheduled window elapsed since they last refreshed).
        if (user.Role == Role.Seller && !user.IsShiftActiveNow())
        {
            _logger.LogWarning("Refresh denied — shift inactive for seller {Username}", user.Username);
            return null;
        }

        // Mark current refresh token as used (one-time use)
        refreshToken.IsUsed = true;
        _unitOfWork.RefreshTokens.Update(refreshToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // Revoke the OLD access token's jti so the previous bearer can no
        // longer hit authenticated endpoints with it. Without this, an attacker
        // who phished the access token would keep working access until the
        // natural 30-minute TTL expires even after the legitimate user refreshed.
        var oldToken = _jwtService.GetJtiAndExpiry(request.AccessToken);
        if (oldToken is { } ot)
        {
            await _revokedTokens.RevokeAsync(ot.Jti, ot.ExpiresAtUtc, cancellationToken);
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
            await _revokedTokens.RevokeAsync(accessTokenJti, accessTokenExpiry.Value, cancellationToken);
        }

        await _auditLogService.LogActionAsync(
            AuditEntityTypes.Auth, callerUserId, AuditActions.Logout, callerUserId,
            null, cancellationToken);

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
                DateTime.UtcNow.AddMinutes(_jwtSetting.AccessTokenExpireMinutes),
                user.GetEffectivePermissions()
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
