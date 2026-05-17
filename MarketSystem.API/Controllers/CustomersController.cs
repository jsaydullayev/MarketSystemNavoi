using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AllRoles")]
public class CustomersController : ControllerBase
{
    private readonly ICustomerService _customerService;

    public CustomersController(ICustomerService customerService)
    {
        _customerService = customerService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<CustomerDto>> GetCustomer(Guid id, CancellationToken ct)
    {
        var customer = await _customerService.GetCustomerByIdAsync(id);
        if (customer is null)
            return NotFound();

        return Ok(customer);
    }

    [HttpGet("phone/{phone}")]
    public async Task<ActionResult<CustomerDto>> GetCustomerByPhone(string phone, CancellationToken ct)
    {
        var customer = await _customerService.GetCustomerByPhoneAsync(phone);
        if (customer is null)
            return NotFound();

        return Ok(customer);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<CustomerDto>>> GetAllCustomers(CancellationToken ct)
    {
        var customers = await _customerService.GetAllCustomersAsync(ct);
        return Ok(customers);
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<CustomerDto>>> GetCustomersPaged(
        [FromQuery] int page = 1,
        [FromQuery] int size = 50,
        [FromQuery] string? search = null,
        CancellationToken ct = default)
    {
        var result = await _customerService.GetAllCustomersPagedAsync(page, size, search, ct);
        return Ok(result);
    }

    [HttpPost]
    public async Task<ActionResult<CustomerDto>> CreateCustomer([FromBody] CreateCustomerDto request, CancellationToken ct)
    {
        try
        {
            var customer = await _customerService.CreateCustomerAsync(request);
            return CreatedAtAction(nameof(GetCustomerByPhone), new { phone = customer.Phone }, customer);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut]
    public async Task<ActionResult<CustomerDto>> UpdateCustomer([FromBody] UpdateCustomerDto request, CancellationToken ct)
    {
        try
        {
            var customer = await _customerService.UpdateCustomerAsync(request);
            if (customer is null)
                return NotFound();

            return Ok(customer);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<IActionResult> DeleteCustomer(Guid id, CancellationToken ct)
    {
        var result = await _customerService.DeleteCustomerAsync(id);
        if (!result)
            return NotFound();

        return NoContent();
    }

    [HttpGet("{id}/delete-info")]
    public async Task<ActionResult<CustomerDeleteInfoDto>> GetCustomerDeleteInfo(Guid id, CancellationToken ct)
    {
        var deleteInfo = await _customerService.GetCustomerDeleteInfoAsync(id);
        return Ok(deleteInfo);
    }

    [HttpPost("{id}/soft-delete")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<IActionResult> SoftDeleteCustomer(Guid id)
    {
        var result = await _customerService.SoftDeleteCustomerAsync(id);
        if (!result)
            return NotFound();

        return Ok(new { message = "Customer soft deleted" });
    }
}
