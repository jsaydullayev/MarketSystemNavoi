namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Mahsulot rasmlarini fizik saqlash qatlami. Servis bu interfeys orqali
/// ishlaydi — implementatsiya lokal disk (hozir) yoki S3/MinIO (kelajak)
/// bo'lishi mumkin, servis/controller o'zgarmaydi.
///
/// Baytlar bu yerga yetib kelganda allaqachon format/hajm validatsiyasidan
/// o'tgan bo'ladi (controller magic-byte tekshiruvini bajaradi).
/// </summary>
public interface IProductImageStorage
{
    /// <summary>
    /// Rasmni saqlaydi va server-nisbiy URL qaytaradi
    /// (masalan "/uploads/products/12/abc.webp"). Fayl nomi server tomonda
    /// generatsiya qilinadi — foydalanuvchi yuborgan nom ishlatilmaydi
    /// (path-traversal'dan himoya).
    /// </summary>
    /// <param name="extension">Nuqtasiz kengaytma: "jpg", "png", "gif", "webp".</param>
    Task<string> SaveAsync(int marketId, Guid productId, byte[] bytes, string extension, CancellationToken ct = default);

    /// <summary>
    /// Berilgan URL'ga mos faylni o'chiradi. Rasm almashtirilganda yoki
    /// mahsulot o'chirilganda yetim fayl qolmasligi uchun. URL null/bo'sh
    /// yoki fayl mavjud bo'lmasa — jim o'tadi (xato tashlamaydi).
    /// </summary>
    Task DeleteAsync(string? imageUrl, CancellationToken ct = default);
}
