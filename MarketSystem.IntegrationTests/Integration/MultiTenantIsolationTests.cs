using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Repositories;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Guards the multi-tenant data isolation contract (Plan 05 Bosqich 2).
/// Every service that takes an ID must scope the query by the caller's market,
/// otherwise an Owner of Market A could probe Guids and exfiltrate Market B's
/// data. These tests seed a *second* market alongside the test fixture's
/// market, point CurrentMarketService at Market A, then try every reasonable
/// service entry point against Market B's IDs — they must all come back
/// null / false / empty.
/// </summary>
public class MultiTenantIsolationTests : TestBase
{
    // The TestBase fixture is "Market A". We seed a sibling Market B with
    // its own user / customer / sale / phone, then attempt to reach them
    // from Market A's context.
    private const int OtherMarketId = 9999;

    private Guid _otherUserId;
    private Guid _otherCustomerId;
    private Guid _otherSaleId;
    private const string _otherCustomerPhone = "+998999999999";

    private async Task SeedSecondMarketAsync()
    {
        DbContext.Markets.Add(new Market
        {
            Id = OtherMarketId,
            Name = "Other Market",
            Subdomain = "other",
            OwnerId = Guid.NewGuid(),
        });

        _otherUserId = Guid.NewGuid();
        DbContext.Users.Add(new User
        {
            Id = _otherUserId,
            FullName = "Other Owner",
            Username = "other_owner",
            PasswordHash = "x",
            Role = Role.Owner,
            Language = Language.Uzbek,
            IsActive = true,
            MarketId = OtherMarketId,
        });

        _otherCustomerId = Guid.NewGuid();
        DbContext.Customers.Add(new Customer
        {
            Id = _otherCustomerId,
            FullName = "Other Customer",
            Phone = _otherCustomerPhone,
            Comment = "from another market",
            MarketId = OtherMarketId,
        });

        _otherSaleId = Guid.NewGuid();
        DbContext.Sales.Add(new Sale
        {
            Id = _otherSaleId,
            SellerId = _otherUserId,
            CustomerId = _otherCustomerId,
            TotalAmount = 50_000m,
            PaidAmount = 50_000m,
            Status = SaleStatus.Paid,
            MarketId = OtherMarketId,
        });

        await DbContext.SaveChangesAsync();
        ClearDbContext();
    }

    private UserService CreateUserService()
    {
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new UserService(
            unitOfWork, DbContext, CurrentMarketServiceMock.Object, new FakeUserTokenEpochStore());
    }

    // ─── UserService ─────────────────────────────────────────────────────

    [Fact]
    public async Task GetUserByIdAsync_OtherMarketUserId_ReturnsNull()
    {
        await SeedSecondMarketAsync();
        var users = CreateUserService();

        var result = await users.GetUserByIdAsync(_otherUserId);

        result.Should().BeNull("a user from another market must not be visible by Guid lookup");
    }

    [Fact]
    public async Task DeleteUserAsync_OtherMarketUserId_ReturnsFalse_AndDoesNotMutate()
    {
        await SeedSecondMarketAsync();
        var users = CreateUserService();

        var ok = await users.DeleteUserAsync(_otherUserId);

        ok.Should().BeFalse("cross-tenant delete must be rejected silently");
        // The "other" user must still be alive and in their own market.
        ClearDbContext();
        var stillThere = await DbContext.Users
            .IgnoreQueryFilters()
            .FirstAsync(u => u.Id == _otherUserId);
        stillThere.IsDeleted.Should().BeFalse();
        stillThere.IsActive.Should().BeTrue();
    }

    [Fact]
    public async Task GetAllUsersAsync_OnlyReturnsCallersMarket()
    {
        await SeedSecondMarketAsync();
        var users = CreateUserService();

        var list = (await users.GetAllUsersAsync()).ToList();

        list.Should().NotBeEmpty("the caller's own market has at least TestUser");
        list.Should().OnlyContain(u => u.MarketId == TestMarketId,
            "no row from any other market may leak into the response");
    }

    // ─── CustomerService ─────────────────────────────────────────────────

    [Fact]
    public async Task GetCustomerByIdAsync_OtherMarketCustomerId_ReturnsNull()
    {
        await SeedSecondMarketAsync();

        var result = await CustomerService.GetCustomerByIdAsync(_otherCustomerId);

        result.Should().BeNull();
    }

    [Fact]
    public async Task GetCustomerByPhoneAsync_OtherMarketsPhone_ReturnsNull()
    {
        await SeedSecondMarketAsync();

        // Phone lookup is a classic IDOR vector — even when phone numbers
        // are technically unique, the response shape ("customer found vs
        // not") must NOT reveal cross-tenant existence.
        var result = await CustomerService.GetCustomerByPhoneAsync(_otherCustomerPhone);

        result.Should().BeNull();
    }

    // ─── SaleService ─────────────────────────────────────────────────────

    [Fact]
    public async Task GetSaleByIdAsync_OtherMarketSaleId_ReturnsNull()
    {
        await SeedSecondMarketAsync();

        var result = await SaleService.GetSaleByIdAsync(_otherSaleId);

        result.Should().BeNull();
    }

    [Fact]
    public async Task GetAllSalesAsync_OnlyReturnsCallersMarket()
    {
        await SeedSecondMarketAsync();
        // Add one sale to the caller's market so the assertion is meaningful.
        await CreateTestSaleAsync(totalAmount: 100m, paidAmount: 100m);

        var sales = (await SaleService.GetAllSalesAsync()).ToList();

        sales.Should().NotBeEmpty();
        // The cross-market sale must NOT be in the result.
        sales.Should().NotContain(s => s.Id == _otherSaleId,
            "Market B's sale must not leak into Market A's list");
    }

    // ─── CashRegisterService (K2) ────────────────────────────────────────

    [Fact]
    public async Task GetCashRegisterAsync_OrphanWithdrawalsFromOtherMarket_DoNotLeak()
    {
        // Regression test for K2: the old query did
        //   .Where(x => x.User == null || x.User.MarketId == marketId)
        // which accepted every UserId=null row, so an orphan withdrawal that
        // belonged to Market B leaked into Market A's withdrawal list as soon
        // as Market B's user was hard-deleted. We now filter by
        // CashWithdrawal.MarketId directly — orphans must stay in their own
        // market.

        await SeedSecondMarketAsync();

        // Seed two withdrawals belonging to "Other Market" — one with a live
        // user FK, one orphaned (UserId NULL after a hard-delete).
        DbContext.CashWithdrawals.Add(new CashWithdrawal
        {
            Id = Guid.NewGuid(),
            Amount = 100m,
            Comment = "Other market — live user",
            WithdrawalDate = DateTime.UtcNow,
            WithdrawType = "cash",
            UserId = _otherUserId,
            MarketId = OtherMarketId,
        });
        DbContext.CashWithdrawals.Add(new CashWithdrawal
        {
            Id = Guid.NewGuid(),
            Amount = 200m,
            Comment = "Other market — orphan",
            WithdrawalDate = DateTime.UtcNow,
            WithdrawType = "cash",
            UserId = null, // simulates the post-hard-delete state
            MarketId = OtherMarketId,
        });
        await DbContext.SaveChangesAsync();
        ClearDbContext();

        // Act — caller is still on TestMarketId (Market A).
        var register = await CashRegisterService.GetCashRegisterAsync();

        // Assert — none of Market B's withdrawals appear in Market A's view.
        register.Should().NotBeNull();
        register!.Withdrawals.Should().BeEmpty(
            "withdrawals scoped to another market must not appear here, " +
            "even when they're orphaned (UserId NULL)");
    }
}
