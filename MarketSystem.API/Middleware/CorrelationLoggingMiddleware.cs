using System.Diagnostics;

namespace MarketSystem.API.Middleware;

public class CorrelationLoggingMiddleware
{
    private readonly RequestDelegate _next;

    public CorrelationLoggingMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var correlationId = context.Request.Headers["X-Correlation-ID"].FirstOrDefault();

        if (string.IsNullOrEmpty(correlationId))
        {
            correlationId = Activity.Current?.Id ?? Guid.NewGuid().ToString("N")[..8];
        }

        context.Items["CorrelationId"] = correlationId;

        await _next(context);
    }
}
