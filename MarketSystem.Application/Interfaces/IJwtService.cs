using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;

namespace MarketSystem.Application.Interfaces;

public interface IJwtService
{
    TokenDto GenerateToken(User user, bool populateExp);
    Tuple<bool, string?> ValidateAndGetUser(string token);
}