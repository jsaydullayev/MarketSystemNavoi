using MarketSystem.Domain.Common;

namespace MarketSystem.Domain.Entities;

public class RefreshToken : BaseEntity
{
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; } = false;
    public bool IsRevoked { get; set; } = false;
    public DateTime? RevokedAt { get; set; }

    /// <summary>
    /// Bu token qachon ishlatilgani (rotatsiya qilingani). Reuse-detection uchun
    /// SHART: ikki tab/qurilma bir vaqtda refresh qilsa, yutqazgan so'rov ham
    /// "IsUsed=true" ko'radi — bu O'G'IRLIK EMAS, oddiy poyga. UsedAt yordamida
    /// yaqinda (grace oynasi ichida) ishlatilgan tokenni haqiqiy qayta
    /// ishlatishdan ajratamiz va butun oilani bekor qilmaymiz.
    /// </summary>
    public DateTime? UsedAt { get; set; }

    /// <summary>
    /// Sessiya (rotatsiya zanjiri) qachon BOSHLANGANI. Rotatsiyada ota-tokendan
    /// KO'CHIRILADI, hech qachon yangilanmaydi — shuning uchun ExpiresAt har
    /// refresh'da uzaysa ham, sessiyaning mutlaq umri cheklangan bo'lib qoladi.
    /// Busiz o'g'irlangan tokenni cheksiz aylantirib, hisobni abadiy ushlab
    /// turish mumkin edi.
    /// </summary>
    public DateTime SessionStartedAt { get; set; }

    // Navigation properties
    public User User { get; set; } = null!;
}
