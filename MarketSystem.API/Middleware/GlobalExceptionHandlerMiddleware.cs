using System.Net;
using System.Text.Json;
using Npgsql;

namespace MarketSystem.API.Middleware;

/// <summary>
/// Global exception handler to catch and format all unhandled exceptions
/// </summary>
public class GlobalExceptionHandlerMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionHandlerMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public GlobalExceptionHandlerMiddleware(
        RequestDelegate next,
        ILogger<GlobalExceptionHandlerMiddleware> logger,
        IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "An unhandled exception occurred: {Message}", ex.Message);
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";

        var response = new ErrorResponse();

        switch (exception)
        {
            case UnauthorizedAccessException:
                context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                response.Message = "Sizga bu amalni bajarishga ruxsat yo'q.";
                break;

            case InvalidOperationException:
                context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                response.Message = exception.Message;
                break;

            case ArgumentException:
                context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                response.Message = exception.Message;
                break;

            case KeyNotFoundException:
                context.Response.StatusCode = (int)HttpStatusCode.NotFound;
                response.Message = "Ma'lumot topilmadi.";
                break;

            case PostgresException postgresEx:
                context.Response.StatusCode = (int)HttpStatusCode.ServiceUnavailable;
                _logger.LogError(postgresEx, "PostgreSQL error: {SqlState} - {Message}", postgresEx.SqlState, postgresEx.MessageText);
                response.Message = "Ma'lumotlar bazasi bilan bog'lanishda xatolik yuz berdi. Iltimos, keyinroq urinib ko'ring.";
                break;

            case TimeoutException:
                context.Response.StatusCode = (int)HttpStatusCode.ServiceUnavailable;
                _logger.LogError(exception, "Request timeout: {Message}", exception.Message);
                response.Message = "So'rov vaqti tugadi. Iltimos, keyinroq urinib ko'ring.";
                break;

            default:
                context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                response.Message = $"Serverda xatolik yuz berdi: {exception.Message} (Ichki: {exception.InnerException?.Message})";
                response.StackTrace = exception.StackTrace;
                break;
        }

        response.StatusCode = context.Response.StatusCode;

        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        await context.Response.WriteAsync(json);
    }

    private class ErrorResponse
    {
        public int StatusCode { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? StackTrace { get; set; }
        public string? InnerExceptionMessage { get; set; }
    }
}
