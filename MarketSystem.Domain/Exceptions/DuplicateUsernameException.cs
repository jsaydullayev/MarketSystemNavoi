namespace MarketSystem.Domain.Exceptions;

/// <summary>
/// Thrown when creating a staff account with a username that already exists in
/// the caller's market. Username uniqueness is enforced per-market by the
/// partial unique index "IX_Users_MarketId_Username_Unique".
///
/// Distinct from generic <see cref="InvalidOperationException"/> so the global
/// exception handler maps it to HTTP 409 Conflict with a structured body — the
/// client uses the <c>code</c> USERNAME_TAKEN to warn "this username is taken"
/// inline on the username field instead of falling through to a generic 400.
/// </summary>
public class DuplicateUsernameException : Exception
{
    public string Username { get; }

    public DuplicateUsernameException(string username)
        : base($"Username '{username}' already exists")
    {
        Username = username;
    }
}
