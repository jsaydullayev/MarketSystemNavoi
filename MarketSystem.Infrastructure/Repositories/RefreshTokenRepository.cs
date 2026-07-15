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

    public async Task<bool> TryClaimAsync(Guid id, DateTime usedAtUtc, CancellationToken cancellationToken = default)
    {
        // ExecuteUpdateAsync — FAQAT relational provider'da. Integration testlar
        // EF InMemory'da ishlaydi, u esa bu API'ni qo'llamaydi va
        // InvalidOperationException tashlaydi (oddiy refresh ham sinardi).
        if (_context.Database.IsRelational())
        {
            // Bitta shartli UPDATE ... WHERE Id=@id AND NOT IsUsed AND NOT IsRevoked.
            // Satr darajasidagi qulf DB'ning o'zida — parallel chaqiruvlardan
            // faqat bittasi 1 qator yangilaydi, qolganlari 0 oladi.
            // DIQQAT: ExecuteUpdate change-tracker'ni CHETLAB o'tadi — chaqiruvchi
            // xotiradagi eski nusxaga tayanmasligi kerak.
            var rowsAffected = await _dbSet
                .Where(r => r.Id == id && !r.IsUsed && !r.IsRevoked)
                .ExecuteUpdateAsync(
                    s => s
                        .SetProperty(r => r.IsUsed, true)
                        .SetProperty(r => r.UsedAt, usedAtUtc),
                    cancellationToken);

            return rowsAffected == 1;
        }

        // InMemory (testlar) — bu yerda haqiqiy parallellik yo'q, shuning uchun
        // tracker orqali bir martalik claim semantikasi yetarli. Atomiklik faqat
        // haqiqiy DB'da (Postgres) ahamiyatli va yuqoridagi shox uni ta'minlaydi.
        var token = await _dbSet
            .FirstOrDefaultAsync(r => r.Id == id && !r.IsUsed && !r.IsRevoked, cancellationToken);
        if (token is null)
            return false;

        token.IsUsed = true;
        token.UsedAt = usedAtUtc;
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<RefreshToken?> GetByIdNoTrackingAsync(Guid id, CancellationToken cancellationToken = default)
    {
        // AsNoTracking — identity-map'ni chetlab, DB'dagi yangi qiymatlarni
        // qaytaradi (FindAsync/GetByIdAsync esa eskirgan tracked nusxani berardi).
        return await _dbSet
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken);
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
            // DIQQAT: _dbSet.Update(token) ATAYLAB chaqirilmaydi. U entity'ni
            // butunlay Modified qilib belgilaydi va SaveChanges HAMMA ustunni
            // qayta yozadi — shu jumladan IsUsed/UsedAt'ni ham. Bu yerdagi nusxa
            // TryClaimAsync (ExecuteUpdate, tracker'ni chetlab o'tadi) yozgan
            // qiymatlardan eskirgan bo'lishi mumkin, ya'ni g'olibning
            // IsUsed=true'si IsUsed=false bilan bosib ketilardi.
            // Tracked entity'ni shunchaki o'zgartirish yetarli — EF faqat
            // haqiqatan o'zgargan ikki ustunni yozadi.
        }
    }
}
