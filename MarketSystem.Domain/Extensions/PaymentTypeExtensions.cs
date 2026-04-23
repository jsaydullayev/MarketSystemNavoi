using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Extensions;

public static class PaymentTypeExtensions
{
    public static string ToUzbek(this PaymentType paymentType) => paymentType switch
    {
        PaymentType.Cash => "Naqd",
        PaymentType.Terminal => "Terminal",
        PaymentType.Transfer => "Bank o'tkazmasi",
        PaymentType.Click => "Click",
        _ => paymentType.ToString()
    };
}
