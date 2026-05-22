using MarketSystem.Application.Services;
using MarketSystem.Domain.Constants;
using MarketSystem.Infrastructure.Repositories;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
using Moq;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Verifies seller work-shift sessions (the Shift entity / ShiftService) —
/// open / close / current, including the idempotent-open and
/// no-open-shift-to-close edge cases.
/// </summary>
public class ShiftIntegrationTests : TestBase
{
    private ShiftService CreateService()
    {
        var unitOfWork = new UnitOfWork(DbContext, NullLogger<UnitOfWork>.Instance);
        return new ShiftService(unitOfWork, CurrentMarketServiceMock.Object, AuditLogServiceMock.Object);
    }

    [Fact]
    public async Task OpenShift_CreatesAnOpenSession()
    {
        var shift = await CreateService().OpenShiftAsync(TestUserId);

        shift.UserId.Should().Be(TestUserId);
        shift.IsOpen.Should().BeTrue();
        shift.ClosedAt.Should().BeNull();
    }

    [Fact]
    public async Task OpenShift_WhenAlreadyOpen_ReturnsTheSameShift()
    {
        var service = CreateService();

        var first = await service.OpenShiftAsync(TestUserId);
        var second = await service.OpenShiftAsync(TestUserId);

        second.Id.Should().Be(first.Id, "re-opening must not create a second session");
    }

    [Fact]
    public async Task CloseShift_ClosesTheOpenSession()
    {
        var service = CreateService();
        await service.OpenShiftAsync(TestUserId);

        var closed = await service.CloseShiftAsync(TestUserId);

        closed.IsOpen.Should().BeFalse();
        closed.ClosedAt.Should().NotBeNull();
    }

    [Fact]
    public async Task CloseShift_WhenNoOpenSession_Throws()
    {
        var act = () => CreateService().CloseShiftAsync(TestUserId);

        await act.Should().ThrowAsync<InvalidOperationException>();
    }

    [Fact]
    public async Task GetCurrentShift_TracksOpenThenClosedState()
    {
        var service = CreateService();

        (await service.GetCurrentShiftAsync(TestUserId))
            .Should().BeNull("no shift opened yet");

        await service.OpenShiftAsync(TestUserId);
        (await service.GetCurrentShiftAsync(TestUserId))
            .Should().NotBeNull("a shift is open");

        await service.CloseShiftAsync(TestUserId);
        (await service.GetCurrentShiftAsync(TestUserId))
            .Should().BeNull("the shift was closed");
    }

    // --- Audit log coverage (Plan 07, Bosqich 1) ------------------------

    [Fact]
    public async Task OpenShift_WritesOpenAuditLog()
    {
        await CreateService().OpenShiftAsync(TestUserId);

        AuditLogServiceMock.Verify(x => x.LogActionAsync(
            AuditEntityTypes.Shift, It.IsAny<Guid>(), AuditActions.Open, TestUserId,
            It.IsAny<object?>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task CloseShift_WritesCloseAuditLog()
    {
        var service = CreateService();
        await service.OpenShiftAsync(TestUserId);
        await service.CloseShiftAsync(TestUserId);

        AuditLogServiceMock.Verify(x => x.LogActionAsync(
            AuditEntityTypes.Shift, It.IsAny<Guid>(), AuditActions.Close, TestUserId,
            It.IsAny<object?>(), It.IsAny<CancellationToken>()), Times.Once);
    }

    [Fact]
    public async Task OpenShift_WhenAlreadyOpen_WritesNoSecondAuditLog()
    {
        var service = CreateService();
        await service.OpenShiftAsync(TestUserId);
        await service.OpenShiftAsync(TestUserId); // idempotent re-open — no state change

        AuditLogServiceMock.Verify(x => x.LogActionAsync(
            AuditEntityTypes.Shift, It.IsAny<Guid>(), AuditActions.Open, It.IsAny<Guid>(),
            It.IsAny<object?>(), It.IsAny<CancellationToken>()), Times.Once);
    }
}
