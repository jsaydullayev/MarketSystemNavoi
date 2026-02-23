namespace MarketSystem.Application.Constants;

/// <summary>
/// O'lchov birliklari konstantlari
/// Flutter va Web frontend uchun
/// </summary>
public static class UnitConstants
{
    /// <summary>
    /// Barcha o'lchov birliklari ro'yxati
    /// </summary>
    public static readonly List<UnitInfo> AllUnits = new()
    {
        new UnitInfo(1, "dona", "Piece", "Дона"),
        new UnitInfo(2, "kg", "Kilogram", "Килограмм"),
        new UnitInfo(3, "m", "Meter", "Метр")
    };
}

/// <summary>
/// O'lchov birligi ma'lumotlari
/// </summary>
public record UnitInfo(
    int Value,
    string NameUz,      // O'zbekcha: dona, kg, m
    string NameEn,      // Inglizcha: Piece, Kilogram, Meter
    string NameRu       // Ruscha: Дона, Килограмм, Метр
);
