using System.Security.Cryptography;
using System.Text;

namespace MarketSystem.Application.Services;

/// <summary>
/// K1 — refresh tokens are stored in the database as a SHA-256 hash of the
/// random plaintext we hand to the client, not the plaintext itself. The
/// plaintext lives only in the client's secure storage and in transit over
/// HTTPS; a DB compromise no longer hands the attacker a working session.
///
/// Choice of hash:
///   • The refresh-token plaintext is already a 64-byte (512-bit) crypto-
///     strong random string (see <c>AuthService.GenerateRefreshToken</c>),
///     so brute-force preimage is computationally infeasible regardless
///     of the hash function. We don't need bcrypt's slow work-factor —
///     SHA-256 is appropriate and orders of magnitude cheaper to verify
///     on every refresh call.
///   • Hash output is hex-encoded (64 chars) so it fits the existing
///     <c>Token</c> column (max length 500, well over what we need) and
///     stays comparable via plain `==` for the DB index.
///
/// Migration note: existing plaintext rows in the table will fail to match
/// any hashed lookup after this lands. Every active refresh token is
/// effectively invalidated and users must re-login once. There is no DDL
/// change — the column stays as is.
/// </summary>
public static class RefreshTokenHasher
{
    public static string Hash(string plaintext)
    {
        if (string.IsNullOrEmpty(plaintext))
            throw new ArgumentException("Refresh token plaintext cannot be null or empty.", nameof(plaintext));

        var bytes = Encoding.UTF8.GetBytes(plaintext);
        var hash = SHA256.HashData(bytes);
        return Convert.ToHexString(hash); // upper-case hex, deterministic, 64 chars
    }
}
