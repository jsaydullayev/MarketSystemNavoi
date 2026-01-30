namespace MarketSystem.Domain.Interfaces;

public interface IJwtService
{
    string GenerateToken(Domain.Entities.User user);
    Guid? ValidateToken(string token);
}
