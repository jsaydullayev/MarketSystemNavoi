namespace MarketSystem.Domain.Common;
public class JwtSetting
{
    public string Issuer { get; set; }
    public string Audience { get; set; }
    public string Key { get; set; }
    public int AccessTokenExpireHours { get; set; } = 14;
    public int RefreshTokenExpireDays { get; set; } = 5;
}
