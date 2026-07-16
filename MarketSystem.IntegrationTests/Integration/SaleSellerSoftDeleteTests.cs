using MarketSystem.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Regression tests for the "disappearing sales" bug: soft-deleting a seller
/// (Admin/Seller profile) must NOT hide the sales they made.
///
/// Root cause was the required <c>Sale.Seller</c> navigation combined with
/// User's <c>!IsDeleted</c> global query filter — <c>.Include(s =&gt; s.Seller)</c>
/// INNER-JOINs User and applies the filter, so on PostgreSQL every sale whose
/// seller was soft-deleted vanished from the list (and the paged COUNT, which
/// doesn't join Seller, desynced from the returned rows). The fix routes the
/// history queries through <c>IgnoreQueryFilters()</c> + a hand-applied
/// <c>!Sale.IsDeleted</c> guard, so the sale — and the seller's real name —
/// survive the seller's soft-delete.
/// </summary>
public class SaleSellerSoftDeleteTests : TestBase
{
    private async Task SoftDeleteSellerAsync()
    {
        // Mirror UserService.DeleteUserAsync: flip IsDeleted on the seller row.
        var seller = await DbContext.Users.IgnoreQueryFilters().FirstAsync(u => u.Id == TestUserId);
        seller.IsDeleted = true;
        await DbContext.SaveChangesAsync();
        ClearDbContext();
    }

    [Fact]
    public async Task GetAllSalesAsync_SellerSoftDeleted_SaleStaysVisibleWithRealName()
    {
        var sale = await CreateTestSaleAsync(totalAmount: 100m, paidAmount: 100m);
        await SoftDeleteSellerAsync();

        var sales = (await SaleService.GetAllSalesAsync()).ToList();

        sales.Should().ContainSingle(s => s.Id == sale.Id,
            "a sale must remain visible after its seller profile is soft-deleted");
        sales.Single(s => s.Id == sale.Id).SellerName.Should().Be("Test User",
            "history keeps the real seller name, not 'Unknown', after the seller is removed");
    }

    [Fact]
    public async Task GetSalesPagedAsync_SellerSoftDeleted_SaleCountedAndReturned()
    {
        var sale = await CreateTestSaleAsync(totalAmount: 100m, paidAmount: 100m);
        await SoftDeleteSellerAsync();

        var page = await SaleService.GetSalesPagedAsync(page: 1, size: 50);

        page.Total.Should().Be(1, "the count and the returned rows must agree");
        page.Items.Should().ContainSingle(s => s.Id == sale.Id,
            "the paged list must still include a sale whose seller was soft-deleted");
    }
}
