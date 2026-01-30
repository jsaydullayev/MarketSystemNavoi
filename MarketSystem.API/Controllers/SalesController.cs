using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using MarketSystem.Application.Commands;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Queries;
using MarketSystem.API.Hubs;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SalesController : ControllerBase
{
    private readonly IMediator _mediator;
    private readonly IHubContext<SalesHub> _hubContext;

    public SalesController(IMediator mediator, IHubContext<SalesHub> hubContext)
    {
        _mediator = mediator;
        _hubContext = hubContext;
    }

    [HttpPost]
    public async Task<ActionResult<SaleResponse>> CreateSale([FromBody] CreateSaleRequest request)
    {
        var result = await _mediator.Send(new CreateSaleCommand(request));
        return Ok(result);
    }

    [HttpPost("{saleId}/items")]
    public async Task<ActionResult<SaleItemResponse>> AddSaleItem(Guid saleId, [FromBody] AddSaleItemRequest request)
    {
        var result = await _mediator.Send(new AddSaleItemCommand(request with { SaleId = saleId }));

        // Notify via SignalR
        var sale = await _mediator.Send(new GetSaleByIdQuery(saleId));
        if (sale != null && sale.Status == Domain.Enums.SaleStatus.Draft)
        {
            await _hubContext.Clients.Group($"branch_{sale.BranchId}")
                .SendAsync("DraftSaleUpdated", sale.SellerId, saleId);
        }

        return Ok(result);
    }

    [HttpPost("{saleId}/payments")]
    public async Task<ActionResult<PaymentResponse>> AddPayment(Guid saleId, [FromBody] AddPaymentRequest request)
    {
        var result = await _mediator.Send(new AddPaymentCommand(request with { SaleId = saleId }));
        return Ok(result);
    }

    [HttpPost("{saleId}/cancel")]
    public async Task<IActionResult> CancelSale(Guid saleId, [FromQuery] Guid adminId)
    {
        await _mediator.Send(new CancelSaleCommand(saleId, adminId));
        return Ok();
    }

    [HttpGet("{saleId}")]
    public async Task<ActionResult<SaleResponse>> GetSale(Guid saleId)
    {
        var result = await _mediator.Send(new GetSaleByIdQuery(saleId));
        if (result == null)
            return NotFound();
        return Ok(result);
    }

    [HttpGet("branch/{branchId}/drafts")]
    public async Task<ActionResult<IEnumerable<SaleResponse>>> GetDraftSales(Guid branchId)
    {
        var result = await _mediator.Send(new GetDraftSalesByBranchQuery(branchId));
        return Ok(result);
    }
}
