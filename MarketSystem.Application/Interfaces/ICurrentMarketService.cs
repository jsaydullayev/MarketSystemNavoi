namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Hozirgi request uchun market IDni beradi (JWT token yoki subdomain orqali)
/// </summary>
public interface ICurrentMarketService
{
    /// <summary>
    /// Hozirgi userning market IDsini qaytaradi
    /// </summary>
    /// <exception cref="UnauthorizedAccessException">Agar market topilmasa</exception>
    int GetCurrentMarketId();

    /// <summary>
    /// Hozirgi userning market IDsini qaytaradi (null bo'lishi mumkin)
    /// </summary>
    int? TryGetCurrentMarketId();
}
