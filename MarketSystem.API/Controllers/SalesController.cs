using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.Commands;
using MarketSystem.Application.DTOs;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SalesController : ControllerBase
{
    private readonly IMediator _mediator;

    public SalesController(IMediator mediator)
    {
        _mediator = mediator;
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
}
