using System.Net;
using System.Text.Json;
using MarketSystem.Domain.Exceptions;
using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace MarketSystem.API.Middleware;

/// <summary>
/// Global exception handler to catch and format all unhandled exceptions.
/// In production only safe, generic messages are returned to the client.
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
            _logger.LogError(ex, "Unhandled exception. TraceId={TraceId}", context.TraceIdentifier);
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";
        var isDev = _env.IsDevelopment();
        var response = new ErrorResponse { TraceId = context.TraceIdentifier };

        switch (exception)
        {
            case UnauthorizedAccessException:
                context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
                response.Message = "Sizga bu amalni bajarishga ruxsat yo'q.";
                break;

            case MarketBlockedException blockedEx:
                // 423 Locked — the resource exists but the SuperAdmin has
                // administratively blocked it. The Flutter client looks at
                // `code` to know whether to surface the "contact admin" UI
                // versus a generic error.
                context.Response.StatusCode = 423;
                response.Message = "Do'kon administrator tomonidan bloklangan. Iltimos, administrator bilan bog'laning.";
                response.Code = "MARKET_BLOCKED";
                response.Reason = blockedEx.Reason;
                response.BlockedAt = blockedEx.BlockedAt;
                break;

            case InvalidOperationException:
                context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                response.Message = isDev ? exception.Message : "So'rov noto'g'ri. Iltimos, ma'lumotlarni tekshiring.";
                break;

            case ArgumentException:
                context.Response.StatusCode = (int)HttpStatusCode.BadRequest;
                response.Message = isDev ? exception.Message : "Noto'g'ri parametr yuborildi.";
                break;

            case KeyNotFoundException:
                context.Response.StatusCode = (int)HttpStatusCode.NotFound;
                response.Message = "Ma'lumot topilmadi.";
                break;

            case DbUpdateConcurrencyException:
                // Surface optimistic-concurrency conflicts (e.g. stock updated by another sale).
                context.Response.StatusCode = (int)HttpStatusCode.Conflict;
                response.Message = "Ma'lumot boshqa foydalanuvchi tomonidan o'zgartirildi. Iltimos, qaytadan urinib ko'ring.";
                break;

            case NotImplementedException:
                // Feature intentionally unimplemented. In dev, surface the raw message so
                // the developer can tell which stub fired. In prod, return a generic
                // string — a future contributor might toss connection strings or file
                // paths into a NotImplementedException message and we don't want them
                // leaking to clients.
                context.Response.StatusCode = (int)HttpStatusCode.NotImplemented; // 501
                response.Message = isDev
                    ? exception.Message
                    : "Bu funksiya hozircha mavjud emas. Iltimos, Excel eksportidan foydalaning.";
                break;

            case PostgresException postgresEx:
                context.Response.StatusCode = postgresEx.SqlState switch
                {
                    "23505" => (int)HttpStatusCode.Conflict,
                    "23503" => (int)HttpStatusCode.BadRequest,
                    "23502" => (int)HttpStatusCode.BadRequest,
                    "23514" => (int)HttpStatusCode.BadRequest,
                    _ => (int)HttpStatusCode.ServiceUnavailable
                };
                _logger.LogError(postgresEx, "PostgreSQL error: SqlState={SqlState}", postgresEx.SqlState);
                response.Message = postgresEx.SqlState switch
                {
                    "23505" => "Bu ma'lumot allaqachon mavjud.",
                    "23503" => "Bog'liq ma'lumot topilmadi.",
                    "23502" => "Majburiy maydon to'ldirilmagan.",
                    "23514" => "Ma'lumot tekshiruv shartiga mos kelmaydi.",
                    _ => "Ma'lumotlar bazasi bilan bog'lanishda xatolik yuz berdi. Iltimos, keyinroq urinib ko'ring."
                };
                break;

            case TimeoutException:
                context.Response.StatusCode = (int)HttpStatusCode.ServiceUnavailable;
                _logger.LogError(exception, "Request timeout");
                response.Message = "So'rov vaqti tugadi. Iltimos, keyinroq urinib ko'ring.";
                break;

            default:
                context.Response.StatusCode = (int)HttpStatusCode.InternalServerError;
                response.Message = "Serverda kutilmagan xatolik yuz berdi.";
                if (isDev)
                {
                    response.DevDetails = $"{exception.GetType().Name}: {exception.Message}";
                    response.StackTrace = exception.StackTrace;
                    response.InnerExceptionMessage = exception.InnerException?.Message;
                }
                break;
        }

        response.StatusCode = context.Response.StatusCode;

        var json = JsonSerializer.Serialize(response, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
            DefaultIgnoreCondition = System.Text.Json.Serialization.JsonIgnoreCondition.WhenWritingNull
        });

        await context.Response.WriteAsync(json);
    }

    private class ErrorResponse
    {
        public int StatusCode { get; set; }
        public string Message { get; set; } = string.Empty;
        public string? TraceId { get; set; }
        public string? DevDetails { get; set; }
        public string? StackTrace { get; set; }
        public string? InnerExceptionMessage { get; set; }

        // Filled by domain-specific exceptions (e.g. MARKET_BLOCKED) so the
        // client can branch on error type without parsing the message string.
        public string? Code { get; set; }
        public string? Reason { get; set; }
        public DateTime? BlockedAt { get; set; }
    }
}
