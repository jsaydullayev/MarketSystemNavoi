using Microsoft.EntityFrameworkCore;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.Infrastructure.Repositories;

public class RefreshTokenRepository : BaseRepository<RefreshToken>, IRefreshTokenRepository
{
    public RefreshTokenRepository(AppDbContext context) : base(context)
    {
    }

    public async Task<RefreshToken?> GetByTokenAsync(string token, CancellationToken cancellationToken = default)
    {
        // K1 — caller passes the plaintext token from the request body; the DB
        // stores only the SHA-256 hash of it. Hash before comparing so the
        // index lookup still works without ever materialising the plaintext.
        if (string.IsNullOrWhiteSpace(token))
            return null;

        var hash = RefreshTokenHasher.Hash(token);
        return await _dbSet
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Token == hash, cancellationToken);
    }

    public async Task<RefreshToken?> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _dbSet
            .Where(r => r.UserId == userId && !r.IsUsed && !r.IsRevoked && r.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(r => r.ExpiresAt)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public async Task RevokeAllForUserAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var tokens = await _dbSet
            .Where(r => r.UserId == userId && !r.IsRevoked)
            .ToListAsync(cancellationToken);

        foreach (var token in tokens)
        {
            token.IsRevoked = true;
            token.RevokedAt = DateTime.UtcNow;
            _dbSet.Update(token);
        }
    }
}
