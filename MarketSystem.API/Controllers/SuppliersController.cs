using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Authorization;
using MarketSystem.Domain.Constants;
using System.Security.Claims;
using MarketSystem.Domain.Enums;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize]
public class SuppliersController : ControllerBase
{
    private readonly ISupplierService _supplierService;
    private readonly IExcelService _excelService;
    private readonly ITashkentClock _clock;

    public SuppliersController(ISupplierService supplierService, IExcelService excelService, ITashkentClock clock)
    {
        _supplierService = supplierService;
        _excelService = excelService;
        _clock = clock;
    }

    private bool IsSeller() => User.FindFirst(ClaimTypes.Role)?.Value == Role.Seller.ToString();

    // The outstanding balance is "how much the shop owes the supplier" — a
    // confidential figure. Mirror the cost-price redaction: zero it for Sellers.
    private SupplierDto Redact(SupplierDto s) =>
        IsSeller() ? s with { OutstandingDebt = 0m } : s;

    [HttpGet("{id}")]
    [RequirePermission(PermissionKeys.SuppliersAccess)]
    public async Task<ActionResult<SupplierDto>> GetSupplier(Guid id, CancellationToken ct)
    {
        var supplier = await _supplierService.GetSupplierByIdAsync(id, ct);
        if (supplier is null)
            return NotFound();
        return Ok(Redact(supplier));
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.SuppliersAccess)]
    public async Task<ActionResult<IEnumerable<SupplierDto>>> GetAllSuppliers(CancellationToken ct)
    {
        var suppliers = await _supplierService.GetAllSuppliersAsync(ct);
        return Ok(suppliers.Select(Redact));
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.SuppliersAccess)]
    public async Task<ActionResult<PagedResult<SupplierDto>>> GetSuppliersPaged(
        [FromQuery] int page = 1,
        [FromQuery] int size = 50,
        [FromQuery] string? search = null,
        CancellationToken ct = default)
    {
        var result = await _supplierService.GetAllSuppliersPagedAsync(page, size, search, ct);
        if (IsSeller())
        {
            var items = result.Items.Select(Redact).ToList();
            return Ok(new { items, result.Page, result.Size, result.Total, result.TotalPages });
        }
        return Ok(result);
    }

    [HttpPost]
    [RequirePermission(PermissionKeys.SuppliersManage)]
    public async Task<ActionResult<SupplierDto>> CreateSupplier([FromBody] CreateSupplierDto request, CancellationToken ct)
    {
        try
        {
            var supplier = await _supplierService.CreateSupplierAsync(request, ct);
            return CreatedAtAction(nameof(GetSupplier), new { id = supplier.Id }, supplier);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut]
    [RequirePermission(PermissionKeys.SuppliersManage)]
    public async Task<ActionResult<SupplierDto>> UpdateSupplier([FromBody] UpdateSupplierDto request, CancellationToken ct)
    {
        try
        {
            var supplier = await _supplierService.UpdateSupplierAsync(request, ct);
            if (supplier is null)
                return NotFound();
            return Ok(Redact(supplier));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpDelete("{id}")]
    [RequirePermission(PermissionKeys.SuppliersDelete)]
    public async Task<IActionResult> DeleteSupplier(Guid id, CancellationToken ct)
    {
        var ok = await _supplierService.SoftDeleteSupplierAsync(id, ct);
        if (!ok)
            return NotFound();
        return NoContent();
    }

    [HttpGet("{id}/delete-info")]
    [RequirePermission(PermissionKeys.SuppliersAccess)]
    public async Task<ActionResult<SupplierDeleteInfoDto>> GetSupplierDeleteInfo(Guid id, CancellationToken ct)
    {
        var info = await _supplierService.GetSupplierDeleteInfoAsync(id, ct);
        // The outstanding balance is confidential — redact for Sellers, exactly
        // like Redact() does on every other supplier read.
        if (IsSeller())
            info = info with { OutstandingDebt = 0m };
        return Ok(info);
    }

    [HttpGet("export")]
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.SuppliersAccess)]
    public async Task<IActionResult> ExportSuppliersToExcel(
        [FromQuery] string lang = "uz",
        CancellationToken ct = default)
    {
        var suppliers = (await _supplierService.GetAllSuppliersAsync(ct)).Select(Redact);
        var isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);

        object exportData = isRu
            ? suppliers.Select(s => new
            {
                ID = s.Id.ToString(),
                Название = s.Name,
                Телефон = s.Phone ?? "",
                Адрес = s.Address ?? "",
                Долг = s.OutstandingDebt,
                Примечание = s.Comment ?? ""
            }).Cast<object>()
            : suppliers.Select(s => new
            {
                ID = s.Id.ToString(),
                Nomi = s.Name,
                Telefon = s.Phone ?? "",
                Manzil = s.Address ?? "",
                Qarz = s.OutstandingDebt,
                Izoh = s.Comment ?? ""
            }).Cast<object>();

        var sheetName = isRu ? "Поставщики" : "Yetkazib beruvchilar";
        var fileContent = _excelService.GenerateExcel((dynamic)exportData, sheetName);

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"{sheetName}_{_clock.NowLocal:yyyyMMdd_HHmmss}.xlsx"
        );
    }
}
