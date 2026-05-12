using System.Text.RegularExpressions;

namespace MarketSystem.API.Middleware;

/// <summary>
/// Lightweight request audit logger.
/// Does NOT log request bodies — credentials and PII must never reach the log sink.
/// </summary>
public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (context.Request.Path.StartsWithSegments("/api/Auth") && context.Request.Method == "POST")
        {
            _logger.LogInformation(
                "Auth request {Method} {Path} from {Remote}",
                context.Request.Method,
                context.Request.Path,
                context.Connection.RemoteIpAddress);
        }

        await _next(context);
    }
}
