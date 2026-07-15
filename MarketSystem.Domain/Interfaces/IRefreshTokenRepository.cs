using MarketSystem.Domain.Entities;

namespace MarketSystem.Domain.Interfaces;

public interface IRefreshTokenRepository : IRepository<RefreshToken>
{
    Task<RefreshToken?> GetByTokenAsync(string token, CancellationToken cancellationToken = default);
    Task<RefreshToken?> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    Task RevokeAllForUserAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Tokenni ATOMIK "claim" qiladi: bitta shartli UPDATE (IsUsed=false AND
    /// IsRevoked=false bo'lsagina yozadi). Parallel ikki refresh'dan faqat BITTASI
    /// true oladi — "o'qi → tekshir → yoz" (TOCTOU) oynasi yopiladi, ya'ni ikkita
    /// oila birdaniga chiqmaydi va yutqazgan so'rov reuse-detection'ni bejiz
    /// qo'zg'atmaydi.
    /// </summary>
    /// <returns>true — shu chaqiruv tokenni sarfladi; false — kimdir undan oldin ulgurdi (yoki token bekor qilingan).</returns>
    Task<bool> TryClaimAsync(Guid id, DateTime usedAtUtc, CancellationToken cancellationToken = default);

    /// <summary>
    /// Tokenning DB'dagi HOZIRGI holatini change-tracker'ni chetlab o'qiydi.
    /// TryClaimAsync (ExecuteUpdate) tracker'ni yangilamaydi, shuning uchun
    /// claim'ni yutqazgandan keyin xotiradagi nusxa eskirgan bo'ladi — poyga/
    /// o'g'irlik qarori esa faqat yangi UsedAt/IsRevoked qiymatlariga tayanishi kerak.
    /// </summary>
    Task<RefreshToken?> GetByIdNoTrackingAsync(Guid id, CancellationToken cancellationToken = default);
}
