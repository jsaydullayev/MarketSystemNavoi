namespace MarketSystem.Domain.Enums;

/// <summary>
/// O'lchov birliklari turi
/// </summary>
public enum UnitType
{
    /// <summary>
    /// Dona (piece) - butun sonlar uchun
    /// Masalan: 5 dona telefon, 10 dona stul
    /// </summary>
    Piece = 1,

    /// <summary>
    /// Kilogram - og'irlik o'lchovi
    /// Masalan: 1.5 kg olma, 0.5 kg shakar
    /// </summary>
    Kilogram = 2,

    /// <summary>
    /// Metr - uzunlik o'lchovi
    /// Masalan: 2.5 metr mato, 10.5 metr sim
    /// </summary>
    Meter = 3
}
