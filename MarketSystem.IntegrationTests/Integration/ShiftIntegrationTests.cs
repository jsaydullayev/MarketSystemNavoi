using MarketSystem.Application.Services;
using MarketSystem.Infrastructure.Repositories;
using Microsoft.Extensions.Logging.Abstractions;
using FluentAssertions;
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
        return new ShiftService(unitOfWork, CurrentMarketServiceMock.Object);
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
}
