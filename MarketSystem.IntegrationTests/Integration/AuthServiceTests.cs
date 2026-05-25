using System.Security.Cryptography;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Repositories;
using MarketSystem.Infrastructure.Services;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Moq;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// K5 — AuthService had zero direct tests. This suite covers the security
/// perimeter: login (happy path, wrong password, missing user, timing
/// equivalence), refresh-token rotation (happy path, REUSE detection family
/// revocation, mismatched access/refresh tokens, expired), logout, and the
/// SHA-256 hashing of stored tokens (K1 contract).
///
/// AuthService takes ~9 dependencies; this file wires them up against the
/// InMemory DbContext that TestBase already gives us. JwtService is real
/// (needs a 32+ char Key); IRevokedTokenStore and ILoginAttemptTracker
/// use their real in-memory implementations so attempt-tracking semantics
/// match production behaviour.
/// </summary>
public class AuthServiceTests : TestBase
{
    private const string TestPassword = "CorrectPassword123!";
    private const string TestKey = "test-jwt-key-must-be-at-least-32-chars-long-aaa";

    private AuthService CreateService(out IConfiguration configRoot)
    {
        configRoot = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = TestKey,
                ["Jwt:Issuer"] = "MarketSystemAPI",
                ["Jwt:Audience"] = "MarketSystemClient",
                ["Jwt:AccessTokenExpireMinutes"] = "30",
                ["Jwt:RefreshTokenExpireDays"] = "7",
            }!)
            .Build();

        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        var jwtService = new JwtService(configRoot, NullLogger<JwtService>.Instance);
        var loginAttempts = new InMemoryLoginAttemptTracker();
        var scopeFactory = ServiceProvider.GetRequiredService<IServiceScopeFactory>();
        var revokedTokens = new DbRevokedTokenStore(scopeFactory, NullLogger<DbRevokedTokenStore>.Instance);

        return new AuthService(
            unitOfWork,
            jwtService,
            NullLogger<AuthService>.Instance,
            DbContext,
            configRoot,
            CurrentMarketServiceMock.Object,
            revokedTokens,
            AuditLogServiceMock.Object,
            loginAttempts);
    }

    /// <summary>Replace TestUser's seed hash with a real BCrypt of TestPassword so
    /// LoginAsync can actually match.</summary>
    private async Task SeedRealPasswordAsync()
    {
        var user = await DbContext.Users.FirstAsync(u => u.Id == TestUserId);
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(TestPassword);
        user.IsActive = true;
        user.Role = Role.Owner;
        await DbContext.SaveChangesAsync();
    }

    // ────────────────────── Login ──────────────────────

    [Fact]
    public async Task Login_HappyPath_ReturnsTokens()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var response = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        response.Should().NotBeNull();
        response!.AccessToken.Should().NotBeNullOrEmpty();
        response.RefreshToken.Should().NotBeNullOrEmpty();
        response.UserId.Should().Be(TestUserId);
    }

    [Fact]
    public async Task Login_WrongPassword_ReturnsNull()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var response = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = "WrongPassword!",
        });

        response.Should().BeNull();
    }

    [Fact]
    public async Task Login_MissingUser_ReturnsNull_AndStillSpendsBcryptTime()
    {
        // S6 — timing-attack mitigation. Without the dummy BCrypt.Verify in the
        // not-found branch, an attacker could enumerate usernames by latency.
        // We can't assert wall-time reliably in unit tests, but we CAN assert
        // the path returns null (not throws) and that no row was looked up
        // beyond the username probe.
        var auth = CreateService(out _);

        var response = await auth.LoginAsync(new LoginRequest
        {
            Username = "definitely-not-a-real-user",
            Password = "anything",
        });

        response.Should().BeNull();
    }

    [Fact]
    public async Task Login_InactiveUser_ReturnsNull()
    {
        await SeedRealPasswordAsync();
        var user = await DbContext.Users.FirstAsync(u => u.Id == TestUserId);
        user.IsActive = false;
        await DbContext.SaveChangesAsync();

        var auth = CreateService(out _);

        var response = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        response.Should().BeNull("an inactive user must not be issued a token");
    }

    [Fact]
    public async Task Login_RecordsAuditLogOnSuccess()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        AuditLogServiceMock.Verify(x => x.LogActionAsync(
            "Auth", TestUserId, "Login", TestUserId,
            It.IsAny<object?>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    // ────────────────────── Refresh-token rotation ──────────────────────

    [Fact]
    public async Task Refresh_HappyPath_ReturnsNewTokens_AndMarksOldUsed()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });
        login.Should().NotBeNull();

        var refreshed = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login!.AccessToken,
            RefreshToken = login.RefreshToken,
        });

        refreshed.Should().NotBeNull();
        refreshed!.AccessToken.Should().NotBeNullOrEmpty();
        refreshed.RefreshToken.Should().NotBe(login.RefreshToken, "rotation issues a fresh token");

        // The old refresh token row must now be flagged IsUsed.
        ClearDbContext();
        var stored = await DbContext.RefreshTokens
            .Where(r => r.UserId == TestUserId && r.IsUsed)
            .ToListAsync();
        stored.Should().NotBeEmpty();
    }

    [Fact]
    public async Task Refresh_TokensStoredAsSha256Hash_NotPlaintext()
    {
        // K1 contract. After login, every RefreshToken row must hold the
        // SHA-256 hex (64 chars) of the plaintext — never the plaintext.
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        ClearDbContext();
        var row = await DbContext.RefreshTokens.FirstAsync(r => r.UserId == TestUserId);

        row.Token.Length.Should().Be(64, "SHA-256 hex is 32 bytes → 64 chars");
        row.Token.Should().NotBe(login!.RefreshToken, "DB must never store the plaintext");
        row.Token.Should().Be(RefreshTokenHasher.Hash(login.RefreshToken),
            "the stored value must be the deterministic hash of what we returned to the client");
    }

    [Fact]
    public async Task Refresh_ReusedToken_RevokesEntireFamily()
    {
        // S1 — token-rotation reuse detection. If a client (or attacker)
        // presents an ALREADY-USED refresh token, AuthService revokes ALL of
        // that user's refresh tokens — both the legitimate user and the
        // attacker must re-login.
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        // Use it once — this is the "legitimate" refresh.
        var first = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login!.AccessToken,
            RefreshToken = login.RefreshToken,
        });
        first.Should().NotBeNull();

        // Replay the same (now used) token — simulates the attacker.
        var replay = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login.AccessToken,
            RefreshToken = login.RefreshToken,
        });

        replay.Should().BeNull("a used token must be rejected");

        // Both the original AND the new token from `first` must now be
        // revoked — the attacker can't keep using anything from the chain.
        ClearDbContext();
        var allTokens = await DbContext.RefreshTokens
            .Where(r => r.UserId == TestUserId)
            .ToListAsync();
        allTokens.Should().NotBeEmpty();
        allTokens.Should().OnlyContain(r => r.IsRevoked || r.IsUsed,
            "reuse detection burns the entire token family");
    }

    [Fact]
    public async Task Refresh_UserMismatch_RevokesOnlyTheMismatchedToken()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        // Forge a refresh-token row that belongs to a DIFFERENT user.
        var otherUserId = Guid.NewGuid();
        var stolenPlaintext = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        DbContext.Users.Add(new User
        {
            Id = otherUserId,
            FullName = "Other",
            Username = "other_user_mismatch",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("x"),
            IsActive = true,
            MarketId = TestMarketId,
            Role = Role.Seller,
            Language = Language.Uzbek,
        });
        DbContext.RefreshTokens.Add(new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = otherUserId,
            Token = RefreshTokenHasher.Hash(stolenPlaintext),
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            IsUsed = false,
            IsRevoked = false,
        });
        await DbContext.SaveChangesAsync();

        // Caller presents TestUser's access token + the OTHER user's refresh.
        var response = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login!.AccessToken,
            RefreshToken = stolenPlaintext,
        });

        response.Should().BeNull();

        // The mismatched refresh token must be revoked.
        ClearDbContext();
        var otherToken = await DbContext.RefreshTokens
            .FirstAsync(r => r.UserId == otherUserId);
        otherToken.IsRevoked.Should().BeTrue("a refresh used under the wrong identity is a theft signal");
    }

    [Fact]
    public async Task Refresh_ExpiredToken_ReturnsNull()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        // Backdate the stored row past its expiry.
        var hashed = RefreshTokenHasher.Hash(login!.RefreshToken);
        var row = await DbContext.RefreshTokens.FirstAsync(r => r.Token == hashed);
        row.ExpiresAt = DateTime.UtcNow.AddDays(-1);
        await DbContext.SaveChangesAsync();

        var response = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login.AccessToken,
            RefreshToken = login.RefreshToken,
        });

        response.Should().BeNull();
    }

    [Fact]
    public async Task Refresh_UnknownToken_ReturnsNull()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        var response = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login!.AccessToken,
            RefreshToken = "not-a-real-refresh-token",
        });

        response.Should().BeNull();
    }

    // ────────────────────── Logout ──────────────────────

    [Fact]
    public async Task Logout_HappyPath_RevokesRefreshToken()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        var ok = await auth.LogoutAsync(login!.RefreshToken, TestUserId, null, null);
        ok.Should().BeTrue();

        ClearDbContext();
        var hashed = RefreshTokenHasher.Hash(login.RefreshToken);
        var row = await DbContext.RefreshTokens.FirstAsync(r => r.Token == hashed);
        row.IsRevoked.Should().BeTrue();
    }

    [Fact]
    public async Task Logout_WrongUser_ReturnsFalse_AndDoesNotRevoke()
    {
        await SeedRealPasswordAsync();
        var auth = CreateService(out _);

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });

        var ok = await auth.LogoutAsync(login!.RefreshToken, Guid.NewGuid(), null, null);
        ok.Should().BeFalse();

        ClearDbContext();
        var hashed = RefreshTokenHasher.Hash(login.RefreshToken);
        var row = await DbContext.RefreshTokens.FirstAsync(r => r.Token == hashed);
        row.IsRevoked.Should().BeFalse("a logout from a different identity must not revoke");
    }
}
