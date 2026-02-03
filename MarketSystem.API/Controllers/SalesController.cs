using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "AllRoles")]
public class SalesController : ControllerBase
{
    private readonly ISaleService _saleService;

    public SalesController(ISaleService saleService)
    {
        _saleService = saleService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SaleDto>> GetSale(Guid id)
    {
        var sale = await _saleService.GetSaleByIdAsync(id);
        if (sale is null)
            return NotFound();

        return Ok(sale);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetAllSales()
    {
        var sales = await _saleService.GetAllSalesAsync();
        return Ok(sales);
    }

    [HttpGet("by-date")]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetSalesByDateRange([FromQuery] DateTime start, [FromQuery] DateTime end)
    {
        var sales = await _saleService.GetSalesByDateRangeAsync(start, end);
        return Ok(sales);
    }

    [HttpGet("my-drafts")]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetMyDraftSales()
    {
        var sellerIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sellerIdStr) || !Guid.TryParse(sellerIdStr, out var sellerId))
            return Unauthorized();

        var sales = await _saleService.GetDraftSalesBySellerAsync(sellerId);
        return Ok(sales);
    }

    [HttpPost]
    public async Task<ActionResult<SaleDto>> CreateSale([FromBody] CreateSaleDto request)
    {
        var sellerIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sellerIdStr) || !Guid.TryParse(sellerIdStr, out var sellerId))
            return Unauthorized();

        try
        {
            var sale = await _saleService.CreateSaleAsync(request, sellerId);
            return CreatedAtAction(nameof(GetSale), new { id = sale.Id }, sale);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{saleId}/items")]
    public async Task<ActionResult<SaleItemDto>> AddSaleItem(Guid saleId, [FromBody] AddSaleItemDto request)
    {
        try
        {
            var item = await _saleService.AddSaleItemAsync(saleId, request);
            if (item is null)
                return NotFound();

            return Ok(item);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{saleId}/payments")]
    public async Task<ActionResult<PaymentDto>> AddPayment(Guid saleId, [FromBody] AddPaymentDto request)
    {
        try
        {
            var payment = await _saleService.AddPaymentAsync(saleId, request);
            if (payment is null)
                return NotFound();

            return Ok(payment);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{saleId}/cancel")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<ActionResult<SaleDto>> CancelSale(Guid saleId, [FromBody] CancelSaleDto request)
    {
        try
        {
            var sale = await _saleService.CancelSaleAsync(saleId, request.AdminId);
            if (sale is null)
                return NotFound();

            return Ok(sale);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }
}
