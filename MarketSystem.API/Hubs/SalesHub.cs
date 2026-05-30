using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace MarketSystem.API.Hubs;

[Authorize(Policy = "AllRoles")]
public class SalesHub : Hub
{
    public async Task JoinBranchGroup(Guid branchId)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId is null || userId != branchId.ToString())
        {
            Context.Abort();
            return;
        }
        await Groups.AddToGroupAsync(Context.ConnectionId, $"branch_{branchId}");
    }

    public async Task LeaveBranchGroup(Guid branchId)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (userId is null || userId != branchId.ToString())
            return;
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"branch_{branchId}");
    }

    public async Task NotifyDraftSaleUpdated(Guid branchId, Guid sellerId, Guid saleId)
    {
        var callerId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (callerId is null || callerId != sellerId.ToString())
        {
            Context.Abort();
            return;
        }
        await Clients.Group($"branch_{branchId}").SendAsync("DraftSaleUpdated", sellerId, saleId);
    }
}
