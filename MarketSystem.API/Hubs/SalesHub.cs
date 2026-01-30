using Microsoft.AspNetCore.SignalR;

namespace MarketSystem.API.Hubs;

public class SalesHub : Hub
{
    public async Task JoinBranchGroup(Guid branchId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"branch_{branchId}");
    }

    public async Task LeaveBranchGroup(Guid branchId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"branch_{branchId}");
    }

    public async Task NotifyDraftSaleUpdated(Guid branchId, Guid sellerId, Guid saleId)
    {
        await Clients.Group($"branch_{branchId}").SendAsync("DraftSaleUpdated", sellerId, saleId);
    }
}
