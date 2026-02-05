using System.IO;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Logging;

namespace MarketSystem.API.Middleware;

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
        // Only log POST requests to Auth endpoints
        if (context.Request.Path.StartsWithSegments("/api/Auth") && context.Request.Method == "POST")
        {
            context.Request.EnableBuffering();

            var body = await new StreamReader(context.Request.Body).ReadToEndAsync();
            _logger.LogInformation("=== INCOMING REQUEST ===");
            _logger.LogInformation("Path: {Path}", context.Request.Path);
            _logger.LogInformation("Method: {Method}", context.Request.Method);
            _logger.LogInformation("Content-Type: {ContentType}", context.Request.ContentType);
            _logger.LogInformation("Body: {Body}", body);
            _logger.LogInformation("========================");

            // Reset position so the request can be read again
            context.Request.Body.Position = 0;
        }

        await _next(context);
    }
}
