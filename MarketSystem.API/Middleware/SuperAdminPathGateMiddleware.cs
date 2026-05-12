using System.Security.Cryptography;
using System.Text;

namespace MarketSystem.API.Middleware;

/// <summary>
/// Gates the SuperAdmin controller's URL prefix by requiring an opaque
/// segment from configuration. Requests to any other URL under the same
/// prefix get a flat 404 BEFORE authentication runs, so an unauthenticated
/// probe can't tell that the SuperAdmin console exists.
///
/// The segment is compared with a constant-time check to avoid timing-side
/// channel enumeration of the secret.
/// </summary>
public sealed class SuperAdminPathGateMiddleware
{
    /// <summary>
    /// Public prefix under which the SuperAdmin console lives.
    /// The segment immediately after this prefix must equal the configured
    /// <c>SuperAdmin:ConsoleSegment</c> value or the request 404s.
    /// </summary>
    private const string Prefix = "/api/_sa/";

    private readonly RequestDelegate _next;
    private readonly byte[] _expectedSegmentUtf8;

    public SuperAdminPathGateMiddleware(
        RequestDelegate next,
        IConfiguration config,
        ILogger<SuperAdminPathGateMiddleware> logger)
    {
        _next = next;
        var segment = config["SuperAdmin:ConsoleSegment"];
        if (string.IsNullOrWhiteSpace(segment))
        {
            // Fail-closed: if nobody configured a segment, fall back to a
            // long random per-process value so nobody can hit the console
            // accidentally. The operator MUST configure the segment for the
            // console to be reachable — surface a warning so the absence
            // isn't silent.
            segment = Convert.ToHexString(RandomNumberGenerator.GetBytes(16));
            logger.LogWarning(
                "SuperAdmin:ConsoleSegment is not configured. The SuperAdmin console " +
                "is UNREACHABLE for this process — set the env var SuperAdmin__ConsoleSegment " +
                "to a long random string (e.g. `openssl rand -hex 16`) and restart.");
        }
        _expectedSegmentUtf8 = Encoding.UTF8.GetBytes(segment);
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var path = context.Request.Path.Value;
        // ASP.NET routing is case-insensitive (so `/API/_SA/...` reaches the
        // same controller as `/api/_sa/...`). The gate MUST therefore match
        // case-insensitively too — case-sensitive matching would let a
        // capitalised URL bypass the segment check entirely.
        if (path != null && path.StartsWith(Prefix, StringComparison.OrdinalIgnoreCase))
        {
            var rest = path.AsSpan(Prefix.Length);
            var slash = rest.IndexOf('/');
            var seg = slash >= 0 ? rest[..slash] : rest;

            // Empty segment (`/api/_sa//requests`) — fall through to the
            // standard mismatch path so it 404s.
            var segUtf8 = seg.IsEmpty ? Array.Empty<byte>() : Encoding.UTF8.GetBytes(seg.ToString());
            if (segUtf8.Length != _expectedSegmentUtf8.Length
                || !CryptographicOperations.FixedTimeEquals(segUtf8, _expectedSegmentUtf8))
            {
                // Indistinguishable from a non-existent route.
                context.Response.StatusCode = StatusCodes.Status404NotFound;
                return;
            }
        }
        await _next(context);
    }
}
