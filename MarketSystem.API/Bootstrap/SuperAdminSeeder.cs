using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.API.Bootstrap;

/// <summary>
/// Idempotent one-shot SuperAdmin provisioning. Reads <c>SUPERADMIN_USERNAME</c>
/// and <c>SUPERADMIN_PASSWORD</c> from configuration / environment; if both are
/// present and no SuperAdmin user with that username already exists, creates one.
///
/// Designed to run on every startup — if the user is already there, it does
/// nothing. Operators are encouraged to remove the two env vars after the first
/// successful boot to avoid leaving credentials in their deployment config.
///
/// The password is BCrypt-hashed before storage; the plaintext never leaves
/// this method.
/// </summary>
public static class SuperAdminSeeder
{
    public static async Task SeedFromConfigAsync(IServiceProvider services, ILogger logger, CancellationToken ct = default)
    {
        using var scope = services.CreateScope();
        var config = scope.ServiceProvider.GetRequiredService<IConfiguration>();

        var username = config["SuperAdmin:Username"]
            ?? Environment.GetEnvironmentVariable("SUPERADMIN_USERNAME");
        var password = config["SuperAdmin:Password"]
            ?? Environment.GetEnvironmentVariable("SUPERADMIN_PASSWORD");

        if (string.IsNullOrWhiteSpace(username) || string.IsNullOrWhiteSpace(password))
        {
            logger.LogDebug("SuperAdmin bootstrap skipped — SUPERADMIN_USERNAME / SUPERADMIN_PASSWORD not set.");
            return;
        }

        // Trim username (case-insensitive identifiers shouldn't carry whitespace),
        // but NEVER trim the password — leading/trailing whitespace can be
        // intentional. Passwords are matched verbatim by BCrypt.Verify, so
        // trimming would silently break login.
        username = username.Trim();

        if (password.Length < 12)
        {
            // Refuse to seed weak SuperAdmin passwords — this account has full
            // access to every tenant. The check is generous (no upper-case /
            // symbol enforcement) because the operator may use a passphrase.
            logger.LogError("SuperAdmin bootstrap aborted: password is shorter than 12 characters.");
            return;
        }

        var db = scope.ServiceProvider.GetRequiredService<IAppDbContext>();

        // Soft-deleted SuperAdmins are filtered out by the User entity's query
        // filter; we bypass it so we can also detect (and not re-create) ones
        // that were deactivated.
        var existing = await db.Users
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(u => u.Role == Role.SuperAdmin && u.Username == username, ct);
        if (existing != null)
        {
            logger.LogInformation("SuperAdmin '{Username}' already present — bootstrap is a no-op.", username);
            return;
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Username = username,
            FullName = "Super Administrator",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
            Role = Role.SuperAdmin,
            IsActive = true,
            Language = Language.Uzbek,
            // SuperAdmin is cross-tenant by design — MarketId stays null.
            MarketId = null
        };
        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        logger.LogWarning(
            "Bootstrapped SuperAdmin user '{Username}' (id={UserId}). " +
            "REMOVE SUPERADMIN_USERNAME and SUPERADMIN_PASSWORD from the deployment " +
            "environment now that the user exists.",
            username, user.Id);
    }
}
