using MarketSystem.Domain.Entities;

namespace MarketSystem.Application.Interfaces;

public interface IJwtService
{
    string GenerateToken(User user);
    Guid? ValidateToken(string token);
}
