namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Per-user access-token "epoch" (<c>User.TokensInvalidBeforeUtc</c>): every access
/// token issued to that user BEFORE this instant is dead, whatever its <c>exp</c> says.
///
/// Revoking refresh tokens alone is not enough — the already-issued access token keeps
/// working for the remainder of its TTL (up to 30 minutes), so a fired employee still
/// sells and a stolen token still reads. Stamping the epoch on password change /
/// deactivation / delete / role change / permission removal closes that window: the
/// JwtBearer <c>OnTokenValidated</c> handler compares the token's <c>iat</c> against the
/// epoch and fails the request immediately.
///
/// ── Kim yozadi ──────────────────────────────────────────────────────────────
/// DURABLE yozuv EGASI — <c>UserService</c>: u <c>User.TokensInvalidBeforeUtc</c>
/// ustunini foydalanuvchi qatori bilan BITTA tranzaksiyada commit qiladi. Shu sababli
/// bu store DB'ga umuman yozmaydi — u faqat KESH: commit muvaffaqiyatli bo'lgach
/// <see cref="Publish"/> chaqiriladi va hot-path lookup shu keshdan o'qiydi.
///
/// (Ilgari store ham DB'ga yozardi. Bu "idempotent no-op" deb hisoblanardi, lekin
/// timestamptz mikrosoniyagacha yaxlitlanadi, DateTime esa 100ns — ya'ni DB'dan
/// qaytgan qiymat doim biroz kichik bo'lib, HAR SAFAR ortiqcha ikkinchi UPDATE
/// ketardi, foydalanuvchi tranzaksiyasidan TASHQARIDA. Yagona yozuvchi — UserService.)
/// </summary>
public interface IUserTokenEpochStore
{
    /// <summary>
    /// The instant before which the user's access tokens are invalid, or <c>null</c>
    /// when the user has never been stamped (the overwhelming majority). O(1), in-memory,
    /// called on EVERY authenticated request — must never touch the DB.
    /// </summary>
    DateTime? GetEpoch(Guid userId);

    /// <summary>
    /// Keshni yangilaydi (DB'ga YOZMAYDI — buni chaqiruvchi o'z tranzaksiyasida qiladi).
    /// Faqat commit MUVAFFAQIYATLI bo'lgandan keyin chaqirilishi shart, aks holda
    /// rollback bo'lgan o'zgarish keshda qolib ketardi.
    /// Epoxani hech qachon ORQAGA surmaydi.
    /// </summary>
    void Publish(Guid userId, DateTime utcNow);

    /// <summary>
    /// Startupda keshni DB'dan tiklaydi. Muvaffaqiyatsiz bo'lsa ISTISNO tashlashi shart —
    /// bo'sh kesh bilan davom etish epoch tekshiruvini jimgina o'chirib qo'yardi
    /// (bo'shatilgan xodimning tokeni qayta tirilardi).
    /// </summary>
    Task LoadFromDbAsync(CancellationToken ct = default);
}
