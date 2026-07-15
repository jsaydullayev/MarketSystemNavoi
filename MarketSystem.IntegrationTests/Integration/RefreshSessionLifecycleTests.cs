using System.Security.Cryptography;
using FluentAssertions;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Repositories;
using MarketSystem.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Refresh-token SESSIYA HAYOT SIKLI invariantlari.
///
/// Bu testlar auditda topilgan va tuzatilgan xatolarni qotirib qo'yadi:
///  • rotatsiya poygasi / yo'qolgan javob — foydalanuvchini tizimdan CHIQARMASLIGI kerak,
///  • grace oynasidan tashqaridagi replay — haqiqiy o'g'irlik, oila kuydiriladi,
///  • sessiyaning MUTLAQ umri — cheksiz uzaymasligi kerak,
///  • lekin mutlaq limit BOSHQA (yangi) sessiyani o'ldirmasligi kerak,
///  • begona token bilan majburiy-logout qilib bo'lmasligi kerak.
/// </summary>
public class RefreshSessionLifecycleTests : TestBase
{
    private const string TestPassword = "CorrectPassword123!";
    private const string TestKey = "test-jwt-key-must-be-at-least-32-chars-long-aaa";
    private const int GraceSeconds = 60;
    private const int MaxSessionDays = 30;

    private AuthService CreateService()
    {
        var config = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Key"] = TestKey,
                ["Jwt:Issuer"] = "MarketSystemAPI",
                ["Jwt:Audience"] = "MarketSystemClient",
                ["Jwt:AccessTokenExpireMinutes"] = "30",
                ["Jwt:RefreshTokenExpireDays"] = "7",
                ["Jwt:MaxSessionDays"] = MaxSessionDays.ToString(),
                ["Jwt:RefreshRaceGraceSeconds"] = GraceSeconds.ToString(),
            }!)
            .Build();

        var scopeFactory = ServiceProvider.GetRequiredService<IServiceScopeFactory>();

        return new AuthService(
            new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance),
            new JwtService(config, NullLogger<JwtService>.Instance),
            NullLogger<AuthService>.Instance,
            DbContext,
            config,
            CurrentMarketServiceMock.Object,
            new DbRevokedTokenStore(scopeFactory, NullLogger<DbRevokedTokenStore>.Instance),
            AuditLogServiceMock.Object,
            new InMemoryLoginAttemptTracker());
    }

    private async Task<AuthResponse> LoginAsync(AuthService auth)
    {
        var user = await DbContext.Users.FirstAsync(u => u.Id == TestUserId);
        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(TestPassword);
        await DbContext.SaveChangesAsync();

        var login = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });
        login.Should().NotBeNull();
        return login!;
    }

    private async Task<RefreshToken> RowFor(string plaintextToken)
    {
        var hash = RefreshTokenHasher.Hash(plaintextToken);
        return await DbContext.RefreshTokens.FirstAsync(r => r.Token == hash);
    }

    // ── Poyga / yo'qolgan javob — foydalanuvchi tizimdan CHIQMASLIGI kerak ──

    [Fact]
    public async Task Replay_WithinGraceWindow_ReIssuesFromSameChain_AndKeepsFamilyAlive()
    {
        // Ikki holatni bir vaqtda modellaydi:
        //  1) ikki tab bir vaqtda refresh qildi (yutqazgan tab), yoki
        //  2) server rotatsiya qildi, lekin javob yo'lda yo'qoldi (502/timeout)
        //     va klient hali ham ESKI tokenni ushlab turibdi.
        // Ikkalasida ham klient eski tokenni qayta yuboradi. Bu O'G'IRLIK EMAS —
        // uni rad etsak, klient tsiklga tushib, grace tugagach oila kuydirilardi
        // va foydalanuvchi baribir tizimdan chiqib ketardi.
        var auth = CreateService();
        var login = await LoginAsync(auth);

        var first = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login.AccessToken,
            RefreshToken = login.RefreshToken,
        });
        first.Should().NotBeNull();

        // Xuddi shu (endi sarflangan) tokenni DARHOL qayta yuboramiz.
        var replay = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login.AccessToken,
            RefreshToken = login.RefreshToken,
        });

        replay.Should().NotBeNull(
            "grace oynasi ichidagi qayta taqdim etish xayrixoh — yangi juftlik berilishi kerak");
        replay!.RefreshToken.Should().NotBe(first!.RefreshToken);

        // Eng muhimi: oila TIRIK. Foydalanuvchi tizimdan chiqarilmagan.
        ClearDbContext();
        var live = await DbContext.RefreshTokens
            .Where(r => r.UserId == TestUserId && !r.IsRevoked && !r.IsUsed)
            .ToListAsync();
        live.Should().NotBeEmpty("hech qanday o'g'irlik yo'q — oila kuydirilmasligi kerak");
    }

    [Fact]
    public async Task Replay_WithinGrace_InheritsSessionStart_SoTheAbsoluteCapCannotBeReset()
    {
        // Xayrixoh replay yangi juftlik beradi — lekin u sessiya soatini
        // NOLDAN boshlamasligi kerak, aks holda hujumchi grace oynasida
        // aylantirib mutlaq limitdan qochib qutulardi.
        var auth = CreateService();
        var login = await LoginAsync(auth);

        var originalStart = (await RowFor(login.RefreshToken)).SessionStartedAt;

        var first = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login.AccessToken,
            RefreshToken = login.RefreshToken,
        });
        var replay = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login.AccessToken,
            RefreshToken = login.RefreshToken,
        });

        ClearDbContext();
        (await RowFor(first!.RefreshToken)).SessionStartedAt.Should().Be(originalStart);
        (await RowFor(replay!.RefreshToken)).SessionStartedAt.Should().Be(originalStart);
    }

    // ── Mutlaq sessiya umri ──

    [Fact]
    public async Task Refresh_AfterAbsoluteSessionCap_IsRejected_EvenIfTokenItselfIsFresh()
    {
        // ExpiresAt har rotatsiyada yangilanadi, shuning uchun token "yangi"
        // ko'rinadi. Mutlaq limit esa zanjir BOSHIDAN hisoblanadi — o'g'irlangan
        // tokenni cheksiz aylantirib hisobni abadiy ushlab turish mumkin emas.
        var auth = CreateService();
        var login = await LoginAsync(auth);

        var row = await RowFor(login.RefreshToken);
        row.SessionStartedAt = DateTime.UtcNow.AddDays(-(MaxSessionDays + 1));
        row.ExpiresAt = DateTime.UtcNow.AddDays(7); // token o'zi hali "tirik"
        await DbContext.SaveChangesAsync();

        var result = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login.AccessToken,
            RefreshToken = login.RefreshToken,
        });

        result.Should().BeNull("sessiyaning mutlaq umri tugagan — qayta login majburiy");

        ClearDbContext();
        (await RowFor(login.RefreshToken)).IsRevoked.Should().BeTrue();
    }

    [Fact]
    public async Task AbsoluteCap_RevokesOnlyThatChain_NotTheUsersOtherSessions()
    {
        // REGRESSIYA: ilgari limit RevokeAllForUserAsync chaqirardi — ya'ni
        // 30 kunlik eski desktop sessiyasi foydalanuvchining KECHA telefonda
        // ochgan mutlaqo yangi sessiyasini ham o'ldirib yuborardi.
        var auth = CreateService();

        // 1-sessiya (eski desktop) — limitdan oshgan.
        var oldSession = await LoginAsync(auth);
        var oldRow = await RowFor(oldSession.RefreshToken);
        oldRow.SessionStartedAt = DateTime.UtcNow.AddDays(-(MaxSessionDays + 1));
        await DbContext.SaveChangesAsync();

        // 2-sessiya (yangi telefon) — mutlaqo yangi, limit ichida.
        var freshSession = await auth.LoginAsync(new LoginRequest
        {
            Username = "testuser",
            Password = TestPassword,
        });
        freshSession.Should().NotBeNull();

        // Eski sessiya limitga urildi.
        var rejected = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = oldSession.AccessToken,
            RefreshToken = oldSession.RefreshToken,
        });
        rejected.Should().BeNull();

        // Yangi sessiya BUZILMAGAN bo'lishi kerak — hali ham refresh qila oladi.
        ClearDbContext();
        (await RowFor(freshSession!.RefreshToken)).IsRevoked.Should().BeFalse();

        var stillWorks = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = freshSession.AccessToken,
            RefreshToken = freshSession.RefreshToken,
        });
        stillWorks.Should().NotBeNull(
            "boshqa qurilmadagi yangi sessiya eski zanjirning limiti tufayli o'lmasligi kerak");
    }

    // ── Majburiy-logout DoS ──

    [Fact]
    public async Task ForeignRefreshToken_CannotBeUsedToForceLogoutTheVictim()
    {
        // Hujumchi = istalgan autentifikatsiyalangan foydalanuvchi (o'z access
        // tokeni bilan) + qurbonning refresh token satri. Ilgari server bunday
        // holatda qurbonning tokenini "himoya yuzasidan" bekor qilardi — ya'ni
        // ishlatib bo'lmaydigan oshkor token majburiy-logout quroliga aylanardi.
        var auth = CreateService();
        var victimLogin = await LoginAsync(auth);

        // Hujumchi — boshqa foydalanuvchi, o'z haqiqiy access tokeni bilan.
        var attackerId = Guid.NewGuid();
        DbContext.Users.Add(new User
        {
            Id = attackerId,
            FullName = "Attacker",
            Username = "attacker_seller",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(TestPassword),
            IsActive = true,
            MarketId = TestMarketId,
            Role = Role.Seller,
            Language = Language.Uzbek,
        });
        await DbContext.SaveChangesAsync();

        var attackerLogin = await auth.LoginAsync(new LoginRequest
        {
            Username = "attacker_seller",
            Password = TestPassword,
        });
        attackerLogin.Should().NotBeNull();

        // Hujumchi o'z access tokeni + QURBONNING refresh tokenini yuboradi.
        var attack = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = attackerLogin!.AccessToken,
            RefreshToken = victimLogin.RefreshToken,
        });
        attack.Should().BeNull("begona refresh token hech qachon qabul qilinmasligi kerak");

        // ENG MUHIMI: qurbonning sessiyasi TIRIK qolishi kerak.
        ClearDbContext();
        (await RowFor(victimLogin.RefreshToken)).IsRevoked.Should().BeFalse();

        var victimStillWorks = await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = victimLogin.AccessToken,
            RefreshToken = victimLogin.RefreshToken,
        });
        victimStillWorks.Should().NotBeNull(
            "qurbon hujumchining harakati tufayli tizimdan chiqib ketmasligi kerak");
    }

    // ── Bir martalik ishlatish hali ham kuchda ──

    [Fact]
    public async Task Rotation_MarksParentUsed_AndStampsUsedAt()
    {
        var auth = CreateService();
        var login = await LoginAsync(auth);

        await auth.RefreshTokenAsync(new RefreshTokenRequest
        {
            AccessToken = login.AccessToken,
            RefreshToken = login.RefreshToken,
        });

        ClearDbContext();
        var parent = await RowFor(login.RefreshToken);
        parent.IsUsed.Should().BeTrue();
        parent.UsedAt.Should().NotBeNull("grace oynasi qarorini UsedAt hal qiladi");
        parent.UsedAt!.Value.Should().BeCloseTo(DateTime.UtcNow, TimeSpan.FromMinutes(1));
    }
}
