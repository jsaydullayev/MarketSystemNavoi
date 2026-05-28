using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface IProductImportService
{
    /// <summary>
    /// Dry-run: qatorlarni tahlil qiladi, bazaga hech narsa yozmaydi.
    /// Flutter bu natijani foydalanuvchiga ko'rsatadi.
    /// </summary>
    Task<ImportPreviewResultDto> PreviewAsync(
        List<ImportProductRowDto> rows,
        CancellationToken ct = default);

    /// <summary>
    /// Haqiqiy import: faqat Valid va Warning qatorlarni saqlaydi.
    /// CategoryOverrides orqali foydalanuvchi kategoriya moslamalarini yuboradi.
    /// </summary>
    Task<ImportResultDto> ConfirmAsync(
        ImportConfirmDto request,
        CancellationToken ct = default);
}
