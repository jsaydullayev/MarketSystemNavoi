using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.Commands;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Queries;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProductsController : ControllerBase
{
    private readonly IMediator _mediator;

    public ProductsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost]
    public async Task<IActionResult> CreateProduct([FromBody] CreateProductRequest request)
    {
        await _mediator.Send(new CreateProductCommand(request));
        return Ok();
    }

    [HttpPost("branch-product")]
    public async Task<IActionResult> CreateBranchProduct([FromBody] CreateBranchProductRequest request)
    {
        await _mediator.Send(new CreateBranchProductCommand(request));
        return Ok();
    }

    [HttpPost("zakup")]
    [Authorize(Roles = "Admin,Owner")]
    public async Task<IActionResult> CreateZakup([FromBody] CreateZakupRequest request, [FromHeader] Guid adminId)
    {
        await _mediator.Send(new CreateZakupCommand(request, adminId));
        return Ok();
    }

    [HttpGet("branch/{branchId}")]
    public async Task<ActionResult<IEnumerable<BranchProductResponse>>> GetBranchProducts(Guid branchId)
    {
        var result = await _mediator.Send(new GetBranchProductsQuery(branchId));
        return Ok(result);
    }
}
