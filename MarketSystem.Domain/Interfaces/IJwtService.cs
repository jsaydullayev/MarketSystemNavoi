namespace MarketSystem.Domain.Interfaces;

public interface IJwtService
{
    TokenDto GenerateToken(Entities.User user, bool populateExp);
    Tuple<bool, string?> ValidateAndGetUser(string token);
}