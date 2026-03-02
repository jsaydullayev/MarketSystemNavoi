using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using FluentAssertions;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Integration tests for cash register scenarios
/// These tests cover:
/// - Cash withdrawals
/// - Cash deposits
/// - Concurrent operations (simulated)
/// - Insufficient funds scenarios
/// - Balance updates
/// </summary>
public class CashRegisterIntegrationTests : TestBase
{
    [Fact]
    public async Task GetCashRegister_ShouldCreateIfNotExists()
    {
        // Act
        var result = await CashRegisterService.GetCashRegisterAsync();

        // Assert
        result.Should().NotBeNull();
        result!.CurrentBalance.Should().Be(0m);
        result.Withdrawals.Should().BeEmpty();
    }

    [Fact]
    public async Task AddCash_ShouldIncreaseBalance()
    {
        // Arrange
        var cashRegister = await DbContext.CashRegisters.FirstAsync();
        var initialBalance = cashRegister.CurrentBalance;

        // Act
        var result = await CashRegisterService.AddCashAsync(100m);

        // Assert
        result.Should().BeTrue();

        ClearDbContext();
        var updatedCashRegister = await DbContext.CashRegisters.FirstAsync();
        updatedCashRegister.CurrentBalance.Should().Be(initialBalance + 100m);
    }

    [Fact]
    public async Task AddCash_MultipleTimes_ShouldAccumulate()
    {
        // Arrange
        var initialBalance = (await DbContext.CashRegisters.FirstAsync()).CurrentBalance;

        // Act
        await CashRegisterService.AddCashAsync(50m);
        await CashRegisterService.AddCashAsync(100m);
        await CashRegisterService.AddCashAsync(25m);

        // Assert
        ClearDbContext();
        var cashRegister = await DbContext.CashRegisters.FirstAsync();
        cashRegister.CurrentBalance.Should().Be(initialBalance + 175m);
    }

    [Fact]
    public async Task WithdrawCash_WithSufficientFunds_ShouldDecreaseBalance()
    {
        // Arrange
        await CashRegisterService.AddCashAsync(500m);
        ClearDbContext();

        var request = new WithdrawCashRequest
        {
            Amount = 100m,
            Comment = "Test withdrawal",
            WithdrawType = "cash"
        };

        // Act
        var result = await CashRegisterService.WithdrawCashAsync(request, TestUserId);

        // Assert
        result.Should().BeTrue();

        ClearDbContext();
        var cashRegister = await DbContext.CashRegisters.FirstAsync();
        cashRegister.CurrentBalance.Should().Be(400m); // 500 - 100 = 400

        ClearDbContext();
        var withdrawal = await DbContext.CashWithdrawals
            .FirstOrDefaultAsync(w => w.UserId == TestUserId);
        withdrawal.Should().NotBeNull();
        withdrawal!.Amount.Should().Be(100m);
        withdrawal.WithdrawType.Should().Be("cash");
    }

    [Fact]
    public async Task WithdrawCash_WithInsufficientFunds_ShouldFail()
    {
        // Arrange
        await CashRegisterService.AddCashAsync(50m);
        ClearDbContext();

        var request = new WithdrawCashRequest
        {
            Amount = 100m, // More than balance
            Comment = "Test withdrawal",
            WithdrawType = "cash"
        };

        // Act
        var result = await CashRegisterService.WithdrawCashAsync(request, TestUserId);

        // Assert
        result.Should().BeFalse();

        ClearDbContext();
        var cashRegister = await DbContext.CashRegisters.FirstAsync();
        cashRegister.CurrentBalance.Should().Be(50m); // Should remain unchanged
    }

    [Fact]
    public async Task WithdrawCash_WithInvalidAmount_ShouldFail()
    {
        // Arrange
        await CashRegisterService.AddCashAsync(500m);
        ClearDbContext();

        var request = new WithdrawCashRequest
        {
            Amount = -50m, // Invalid negative amount
            Comment = "Test withdrawal",
            WithdrawType = "cash"
        };

        // Act
        var result = await CashRegisterService.WithdrawCashAsync(request, TestUserId);

        // Assert
        result.Should().BeFalse();
    }

    [Fact]
    public async Task WithdrawCash_WithZeroAmount_ShouldFail()
    {
        // Arrange
        var request = new WithdrawCashRequest
        {
            Amount = 0m,
            Comment = "Test withdrawal",
            WithdrawType = "cash"
        };

        // Act
        var result = await CashRegisterService.WithdrawCashAsync(request, TestUserId);

        // Assert
        result.Should().BeFalse();
    }

    [Fact]
    public async Task WithdrawCash_ClickType_ShouldNotDecreaseBalance()
    {
        // Arrange - Click withdrawals are for record keeping only, don't affect balance
        await CashRegisterService.AddCashAsync(500m);
        ClearDbContext();

        var request = new WithdrawCashRequest
        {
            Amount = 100m,
            Comment = "Click withdrawal",
            WithdrawType = "click"
        };

        // Act
        var result = await CashRegisterService.WithdrawCashAsync(request, TestUserId);

        // Assert
        result.Should().BeTrue();

        ClearDbContext();
        var cashRegister = await DbContext.CashRegisters.FirstAsync();
        cashRegister.CurrentBalance.Should().Be(500m); // Should remain unchanged

        ClearDbContext();
        var withdrawal = await DbContext.CashWithdrawals
            .FirstOrDefaultAsync(w => w.UserId == TestUserId);
        withdrawal.Should().NotBeNull();
        withdrawal!.WithdrawType.Should().Be("click");
    }

    [Fact]
    public async Task WithdrawCash_InvalidType_ShouldFail()
    {
        // Arrange
        var request = new WithdrawCashRequest
        {
            Amount = 100m,
            Comment = "Test withdrawal",
            WithdrawType = "invalid" // Invalid type
        };

        // Act
        var result = await CashRegisterService.WithdrawCashAsync(request, TestUserId);

        // Assert
        result.Should().BeFalse();
    }

    [Fact]
    public async Task SequentialWithdrawals_ShouldTrackCorrectly()
    {
        // Arrange
        await CashRegisterService.AddCashAsync(1000m);
        ClearDbContext();

        // Act - Multiple withdrawals
        var request1 = new WithdrawCashRequest { Amount = 100m, Comment = "First withdrawal", WithdrawType = "cash" };
        var request2 = new WithdrawCashRequest { Amount = 200m, Comment = "Second withdrawal", WithdrawType = "cash" };
        var request3 = new WithdrawCashRequest { Amount = 150m, Comment = "Third withdrawal", WithdrawType = "cash" };

        await CashRegisterService.WithdrawCashAsync(request1, TestUserId);
        await CashRegisterService.WithdrawCashAsync(request2, TestUserId);
        await CashRegisterService.WithdrawCashAsync(request3, TestUserId);

        // Assert
        ClearDbContext();
        var cashRegister = await DbContext.CashRegisters.FirstAsync();
        cashRegister.CurrentBalance.Should().Be(550m); // 1000 - 100 - 200 - 150 = 550

        ClearDbContext();
        var withdrawals = await DbContext.CashWithdrawals
            .Where(w => w.UserId == TestUserId)
            .ToListAsync();

        withdrawals.Should().HaveCount(3);
        withdrawals.Sum(w => w.Amount).Should().Be(450m);
    }

    [Fact]
    public async Task ConcurrencyScenario_Simulated_ShouldNotCauseRaceCondition()
    {
        // Note: This is a simulated test. True concurrency testing would require
        // actual parallel execution which is complex in unit tests.
        // The purpose is to document the potential race condition issue.

        // Arrange
        await CashRegisterService.AddCashAsync(1000m);
        ClearDbContext();

        // Act - Simulate multiple operations sequentially
        // In a real scenario, these could happen concurrently
        var tasks = new List<Task<bool>>();

        for (int i = 0; i < 5; i++)
        {
            var request = new WithdrawCashRequest
            {
                Amount = 100m,
                Comment = $"Withdrawal {i}",
                WithdrawType = "cash"
            };
            tasks.Add(CashRegisterService.WithdrawCashAsync(request, TestUserId));
        }

        await Task.WhenAll(tasks);

        // Assert
        ClearDbContext();
        var cashRegister = await DbContext.CashRegisters.FirstAsync();
        cashRegister.CurrentBalance.Should().Be(500m); // 1000 - 5 * 100 = 500

        // All withdrawals should be recorded
        ClearDbContext();
        var withdrawals = await DbContext.CashWithdrawals
            .Where(w => w.UserId == TestUserId && w.WithdrawType == "cash")
            .ToListAsync();

        withdrawals.Should().HaveCount(5);
    }

    [Fact]
    public async Task GetTodaySalesSummary_ShouldIncludeDebtAmount()
    {
        // This test verifies the feature from commit cdc19a0:
        // "Include exact Debt Amount in Daily Sales Summary DTOs"

        // Arrange - Create today's sales
        var today = DateTime.UtcNow.Date;

        var product = CreateTestProduct(costPrice: 100m, salePrice: 150m);

        // Sale 1: Fully paid
        var sale1 = await CreateTestSaleAsync(totalAmount: 200m, paidAmount: 200m, isDebt: false);

        // Sale 2: Partially paid (debt)
        var sale2 = await CreateTestSaleAsync(totalAmount: 300m, paidAmount: 100m, isDebt: true);

        // Sale 3: Fully on debt
        var sale3 = await CreateTestSaleAsync(totalAmount: 150m, paidAmount: 0m, isDebt: true);

        ClearDbContext();

        // Act
        var summary = await CashRegisterService.GetTodaySalesSummaryAsync();

        // Assert
        summary.Should().NotBeNull();
        summary!.TotalSales.Should().Be(3);
        summary.TotalAmount.Should().Be(650m); // 200 + 300 + 150
        summary.TotalPaid.Should().Be(300m); // 200 + 100 + 0

        // Debt amount = sum of (TotalAmount - PaidAmount) for unpaid portions
        // Sale 1: 200 - 200 = 0
        // Sale 2: 300 - 100 = 200
        // Sale 3: 150 - 0 = 150
        // Total debt = 200 + 150 = 350
        summary.DebtAmount.Should().Be(350m);
    }

    [Fact]
    public async Task CashRegisterLastUpdated_ShouldUpdateOnEachOperation()
    {
        // Arrange
        var initialLastUpdated = (await DbContext.CashRegisters.FirstAsync()).LastUpdated;
        await Task.Delay(100); // Ensure time difference

        // Act
        await CashRegisterService.AddCashAsync(100m);
        ClearDbContext();

        var cashRegister = await DbContext.CashRegisters.FirstAsync();

        // Assert
        cashRegister.LastUpdated.Should().BeAfter(initialLastUpdated);
    }

    [Fact]
    public async Task WithdrawCash_ShouldUpdateLastWithdrawalId()
    {
        // Arrange
        await CashRegisterService.AddCashAsync(500m);
        ClearDbContext();

        var request = new WithdrawCashRequest
        {
            Amount = 100m,
            Comment = "Test withdrawal",
            WithdrawType = "cash"
        };

        // Act
        await CashRegisterService.WithdrawCashAsync(request, TestUserId);

        // Assert
        ClearDbContext();
        var cashRegister = await DbContext.CashRegisters.FirstAsync();
        cashRegister.LastWithdrawalId.Should().NotBeNull();

        ClearDbContext();
        var lastWithdrawal = await DbContext.CashWithdrawals.FindAsync(cashRegister.LastWithdrawalId);
        lastWithdrawal.Should().NotBeNull();
        lastWithdrawal!.Amount.Should().Be(100m);
    }
}
