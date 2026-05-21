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
    private readonly IExcelService _excelService;

    public CustomersController(ICustomerService customerService, IExcelService excelService)
    {
        _customerService = customerService;
        _excelService = excelService;
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

    /// <summary>
    /// Export all customers as an Excel spreadsheet. Mirrors the
    /// /api/Products/.../export pattern so the same DownloadService
    /// helper handles both files on the Flutter side.
    /// </summary>
    [HttpGet("export")]
    public async Task<IActionResult> ExportCustomersToExcel(
        [FromQuery] string lang = "uz",
        CancellationToken ct = default)
    {
        var customers = await _customerService.GetAllCustomersAsync(ct);
        var isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);

        object exportData = isRu
            ? customers.Select(c => new
            {
                ID = c.Id.ToString(),
                ФИО = c.FullName ?? "",
                Телефон = c.Phone,
                Общий_долг = c.TotalDebt,
                Примечание = c.Comment ?? ""
            }).Cast<object>()
            : customers.Select(c => new
            {
                ID = c.Id.ToString(),
                Ism = c.FullName ?? "",
                Telefon = c.Phone,
                Jami_qarz = c.TotalDebt,
                Izoh = c.Comment ?? ""
            }).Cast<object>();

        var sheetName = isRu ? "Клиенты" : "Mijozlar";
        var fileContent = _excelService.GenerateExcel((dynamic)exportData, sheetName);

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"{sheetName}_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx"
        );
    }
}
