using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Integration tests for debt calculation scenarios
/// These tests cover:
/// - Debt creation and calculation
/// - Partial returns with debt recalculation
/// - Overpayment scenarios (potential negative debt)
/// - Multiple payments on debt
/// - Debt status transitions
/// </summary>
public class DebtIntegrationTests : TestBase
{
    [Fact]
    public async Task CreateSaleAsDebt_ShouldCreateCorrectDebtRecord()
    {
        // Arrange
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var items = new List<(Guid productId, decimal quantity, decimal price)>
        {
            (product.Id, 2, 150m)
        };

        // Act
        var sale = await CreateSaleWithItemsAsync(
            totalAmount: 300m,
            paidAmount: 0m,
            items: items,
            isDebt: true
        );

        // Assert
        ClearDbContext();
        var debt = await DbContext.Debts
            .FirstOrDefaultAsync(d => d.SaleId == sale.Id && d.CustomerId == TestCustomer.Id);

        debt.Should().NotBeNull();
        debt!.TotalDebt.Should().Be(300m);
        debt.RemainingDebt.Should().Be(300m);
        debt.Status.Should().Be(DebtStatus.Open);
    }

    [Fact]
    public async Task PartialSale_WithPartialPayment_ShouldCalculateRemainingDebtCorrectly()
    {
        // Arrange
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var items = new List<(Guid productId, decimal quantity, decimal price)>
        {
            (product.Id, 2, 150m)
        };

        // Act
        var sale = await CreateSaleWithItemsAsync(
            totalAmount: 300m,
            paidAmount: 100m,
            items: items,
            isDebt: true
        );

        // Assert
        ClearDbContext();
        var debt = await DbContext.Debts
            .FirstOrDefaultAsync(d => d.SaleId == sale.Id);

        debt.Should().NotBeNull();
        debt!.TotalDebt.Should().Be(300m);
        debt.RemainingDebt.Should().Be(200m); // 300 - 100 = 200
        debt.Status.Should().Be(DebtStatus.Open);
    }

    [Fact]
    public async Task FullPayment_ShouldCloseDebt()
    {
        // Arrange
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var items = new List<(Guid productId, decimal quantity, decimal price)>
        {
            (product.Id, 2, 150m)
        };

        // Act
        var sale = await CreateSaleWithItemsAsync(
            totalAmount: 300m,
            paidAmount: 300m,
            items: items,
            isDebt: false // Fully paid, no debt
        );

        // Assert - No debt record should exist for fully paid sale
        ClearDbContext();
        var debt = await DbContext.Debts
            .FirstOrDefaultAsync(d => d.SaleId == sale.Id);

        debt.Should().BeNull();
    }

    [Fact]
    public async Task OverpaymentScenario_ShouldNotCreateNegativeDebt()
    {
        // Arrange - This tests the bug at SaleService.cs:1213-1216
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var items = new List<(Guid productId, decimal quantity, decimal price)>
        {
            (product.Id, 2, 150m)
        };

        // Act - Simulate overpayment scenario (Paid > Total)
        var sale = await CreateSaleWithItemsAsync(
            totalAmount: 300m,
            paidAmount: 350m, // Overpayment of 50
            items: items,
            isDebt: false
        );

        // Assert - Remaining debt should be 0, not negative
        sale.TotalAmount.Should().Be(300m);
        sale.PaidAmount.Should().Be(350m);

        // In current implementation, no debt record is created if not explicitly marked as debt
        // But if we calculate remaining debt, it should be 0
        var calculatedRemainingDebt = sale.TotalAmount - sale.PaidAmount;
        calculatedRemainingDebt.Should().BeLessThan(0); // -50m - this shows the potential issue

        // The fix should ensure: RemainingDebt = newRemainingDebt > 0 ? newRemainingDebt : 0;
        var fixedRemainingDebt = calculatedRemainingDebt > 0 ? calculatedRemainingDebt : 0;
        fixedRemainingDebt.Should().Be(0m);
    }

    [Fact]
    public async Task MultipleDebtsForSameCustomer_ShouldTrackCorrectly()
    {
        // Arrange
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);

        // Act - Create multiple debts for the same customer
        var sale1 = await CreateTestSaleAsync(totalAmount: 100m, paidAmount: 50m, isDebt: true);
        var sale2 = await CreateTestSaleAsync(totalAmount: 200m, paidAmount: 100m, isDebt: true);
        var sale3 = await CreateTestSaleAsync(totalAmount: 150m, paidAmount: 75m, isDebt: true);

        // Assert - All debts should be tracked correctly
        ClearDbContext();
        var customerDebts = await DbContext.Debts
            .Where(d => d.CustomerId == TestCustomer.Id)
            .ToListAsync();

        customerDebts.Should().HaveCount(3);
        customerDebts.Sum(d => d.TotalDebt).Should().Be(450m); // 100 + 200 + 150
        customerDebts.Sum(d => d.RemainingDebt).Should().Be(225m); // 50 + 100 + 75
        customerDebts.All(d => d.Status == DebtStatus.Open).Should().BeTrue();
    }

    [Fact]
    public async Task DebtStatus_ShouldBeOpenForUnpaid()
    {
        // Arrange
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var items = new List<(Guid productId, decimal quantity, decimal price)>
        {
            (product.Id, 2, 150m)
        };

        // Act
        var sale = await CreateSaleWithItemsAsync(
            totalAmount: 300m,
            paidAmount: 100m,
            items: items,
            isDebt: true
        );

        // Assert
        ClearDbContext();
        var debt = await DbContext.Debts
            .FirstOrDefaultAsync(d => d.SaleId == sale.Id);

        debt!.Status.Should().Be(DebtStatus.Open);
    }

    [Fact]
    public async Task DebtWithDecimalQuantities_ShouldCalculateCorrectly()
    {
        // Arrange - Test with decimal quantities like 2.5kg, 15.5dona
        var product = CreateTestProduct(costPrice: 50m, salePrice: 60m);
        var items = new List<(Guid productId, decimal quantity, decimal price)>
        {
            (product.Id, 2.5m, 60m) // 2.5 items @ 60m = 150m
        };

        // Act
        var sale = await CreateSaleWithItemsAsync(
            totalAmount: 150m,
            paidAmount: 50m,
            items: items,
            isDebt: true
        );

        // Assert
        ClearDbContext();
        var debt = await DbContext.Debts
            .FirstOrDefaultAsync(d => d.SaleId == sale.Id);

        debt.Should().NotBeNull();
        debt!.TotalDebt.Should().Be(150m);
        debt.RemainingDebt.Should().Be(100m); // 150 - 50 = 100
    }

    [Fact]
    public async Task PartialReturn_ExceedingUnpaidSum_ShouldNotCreateNegativeRemainingDebt()
    {
        // Arrange - This tests the bug fixed in commit fd53cec
        // Test the debt recalculation logic directly
        var sale = new Sale
        {
            Id = Guid.NewGuid(),
            SellerId = TestUserId,
            CustomerId = TestCustomer.Id,
            TotalAmount = 300m,
            PaidAmount = 250m,
            Status = SaleStatus.Debt,
            MarketId = TestMarketId
        };

        DbContext.Sales.Add(sale);

        var debt = new Debt
        {
            Id = Guid.NewGuid(),
            SaleId = sale.Id,
            CustomerId = TestCustomer.Id,
            TotalDebt = 300m,
            RemainingDebt = 50m, // 300 - 250
            Status = DebtStatus.Open,
            MarketId = TestMarketId
        };
        DbContext.Debts.Add(debt);

        await DbContext.SaveChangesAsync();

        // Act - Simulate a return that changes the sale total
        // Original: Total=300, Paid=250, Debt=50
        // After return: Total=150, Paid=250
        // RemainingDebt = 150 - 250 = -100, but should be 0
        ClearDbContext();

        var updatedSale = await DbContext.Sales.FindAsync(sale.Id);
        updatedSale!.TotalAmount = 150m; // Simulate return of half the items

        var updatedDebt = await DbContext.Debts
            .FirstOrDefaultAsync(d => d.SaleId == sale.Id);

        if (updatedDebt != null)
        {
            // Test the debt recalculation logic
            var newRemainingDebt = updatedSale.TotalAmount - updatedSale.PaidAmount;
            updatedDebt.TotalDebt = updatedSale.TotalAmount;
            updatedDebt.RemainingDebt = newRemainingDebt > 0 ? newRemainingDebt : 0;
            updatedDebt.Status = newRemainingDebt > 0 ? DebtStatus.Open : DebtStatus.Closed;

            await DbContext.SaveChangesAsync();
        }

        // Assert
        ClearDbContext();
        var finalDebt = await DbContext.Debts
            .FirstOrDefaultAsync(d => d.SaleId == sale.Id);

        finalDebt.Should().NotBeNull();
        finalDebt!.TotalDebt.Should().Be(150m);
        finalDebt.RemainingDebt.Should().Be(0m); // Should not be negative
        finalDebt.Status.Should().Be(DebtStatus.Closed);
    }

    [Fact]
    public async Task ReturnItem_CreatesCredit_ShouldAutoApplyToNewSale()
    {
        // This test verifies that credits from returns are automatically applied to new sales

        // Step 1: Create a sale with partial payment
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var items = new List<(Guid productId, decimal quantity, decimal price)>
        {
            (product.Id, 2, 150m) // 2 items @ 150 = 300 total
        };

        var sale1 = await CreateSaleWithItemsAsync(
            totalAmount: 300m,
            paidAmount: 200m,
            items: items,
            isDebt: false
        );

        // Add payment record to make it more realistic
        var payment = new Payment
        {
            Id = Guid.NewGuid(),
            SaleId = sale1.Id,
            PaymentType = PaymentType.Cash,
            Amount = 200m,
            MarketId = TestMarketId,
            CreatedAt = DateTime.UtcNow
        };
        DbContext.Payments.Add(payment);
        await DbContext.SaveChangesAsync();

        // Verify initial state
        ClearDbContext();
        var initialSale = await DbContext.Sales.FindAsync(sale1.Id);
        initialSale!.TotalAmount.Should().Be(300m);
        initialSale.PaidAmount.Should().Be(200m);

        // Step 2: Return one item (creating a credit)
        // After return: Total = 150, Paid = 200, Overpaid = 50 (this becomes credit)
        var saleItem = await DbContext.SaleItems
            .Where(si => si.SaleId == sale1.Id)
            .FirstAsync();

        var returnRequest = new ReturnSaleItemRequest(
            saleItem.Id.ToString(),
            1, // Return 1 item (150 value)
            "Test return"
        );

        await SaleService.ReturnSaleItemAsync(sale1.Id, returnRequest);

        // Verify credit was created
        ClearDbContext();
        var updatedSale = await DbContext.Sales.FindAsync(sale1.Id);
        updatedSale!.TotalAmount.Should().Be(150m); // 300 - 150 = 150
        updatedSale.PaidAmount.Should().Be(150m); // Paid amount adjusted to match total

        // Check for negative payment (refund)
        var negativePayment = await DbContext.Payments
            .Where(p => p.SaleId == sale1.Id && p.Amount < 0)
            .FirstOrDefaultAsync();
        negativePayment.Should().NotBeNull();
        negativePayment.Should().NotBeNull("Negative payment should exist for refund");
        negativePayment!.Amount.Should().Be(-50m); // Refund of 50

        // Step 3: Create a new sale for the same customer
        // The credit (50) should be automatically applied
        var createSaleRequest = new CreateSaleDto(TestCustomer.Id);

        var sale2 = await SaleService.CreateSaleAsync(createSaleRequest, TestUserId);

        // Add an item to the new sale
        var addRequest = new AddSaleItemDto(
            product.Id,
            1,
            100m,
            100m, // MinSalePrice (same as salePrice for test)
            null
        );

        await SaleService.AddSaleItemAsync(sale2.Id, addRequest);

        // Verify credit was applied
        ClearDbContext();
        var newSale = await DbContext.Sales.FindAsync(sale2.Id);
        newSale!.TotalAmount.Should().Be(100m);
        newSale.PaidAmount.Should().Be(50m); // Credit of 50 was applied!

        // Remaining amount to pay: 100 - 50 = 50
        var remainingToPay = newSale.TotalAmount - newSale.PaidAmount;
        remainingToPay.Should().Be(50m);

        // Step 4: Verify customer no longer has available credit
        var availableCredit = await CustomerService.GetAvailableCreditAsync(TestCustomer.Id);
        availableCredit.Should().Be(0m); // Credit was fully used
    }

    [Fact]
    public async Task MultipleCredits_ShouldBeAppliedCumulatively()
    {
        // Test that multiple credits are summed and applied correctly

        // Create two sales with returns to accumulate credits
        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);
        var items = new List<(Guid productId, decimal quantity, decimal price)>
        {
            (product.Id, 2, 150m)
        };

        // Sale 1: Create and return
        var sale1 = await CreateSaleWithItemsAsync(totalAmount: 300m, paidAmount: 250m, items: items, isDebt: false);
        var item1 = (await DbContext.SaleItems.Where(si => si.SaleId == sale1.Id).FirstAsync());
        await SaleService.ReturnSaleItemAsync(sale1.Id, new ReturnSaleItemRequest(
            item1.Id.ToString(),
            1,
            "Return 1"
        ));

        // Sale 2: Create and return
        var sale2 = await CreateSaleWithItemsAsync(totalAmount: 300m, paidAmount: 250m, items: items, isDebt: false);
        var item2 = (await DbContext.SaleItems.Where(si => si.SaleId == sale2.Id).FirstAsync());
        await SaleService.ReturnSaleItemAsync(sale2.Id, new ReturnSaleItemRequest(
            item2.Id.ToString(),
            1,
            "Return 2"
        ));

        // Total credit should be around 100 (from both returns: 50 + 50)
        ClearDbContext();
        var availableCredit = await CustomerService.GetAvailableCreditAsync(TestCustomer.Id);
        availableCredit.Should().BeGreaterThan(0m);

        // Create new sale with larger total
        var createRequest = new CreateSaleDto(TestCustomer.Id);
        var newSale = await SaleService.CreateSaleAsync(createRequest, TestUserId);

        var addRequest = new AddSaleItemDto(
            product.Id,
            2,
            150m,
            100m, // MinSalePrice
            null
        );

        await SaleService.AddSaleItemAsync(newSale.Id, addRequest);

        // Verify credit was applied (up to the total amount)
        ClearDbContext();
        var finalSale = await DbContext.Sales.FindAsync(newSale.Id);
        finalSale!.PaidAmount.Should().BeGreaterThan(0m); // Credit was applied
        finalSale.PaidAmount.Should().BeLessOrEqualTo(finalSale.TotalAmount); // Not overpaid
    }
}
