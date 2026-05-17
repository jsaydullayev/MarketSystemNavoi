using System.Threading.RateLimiting;

namespace MarketSystem.API.Extensions;

public static class RateLimiterExtensions
{
    public static IServiceCollection AddApiRateLimiter(this IServiceCollection services)
    {
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.OnRejected = async (ctx, ct) =>
            {
                var retryAfter = ctx.Lease.TryGetMetadata(MetadataName.RetryAfter, out var ts)
                    ? Math.Max(1, (int)ts.TotalSeconds).ToString()
                    : "60";
                ctx.HttpContext.Response.Headers["Retry-After"] = retryAfter;

                await ctx.HttpContext.Response.WriteAsJsonAsync(new
                {
                    statusCode = 429,
                    message = "Juda ko'p urinish. Iltimos, biroz kutib qayta urinib ko'ring.",
                    retryAfterSeconds = int.TryParse(retryAfter, out var s) ? s : 60
                }, ct);
            };

            static string PartitionKey(HttpContext ctx) =>
                ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown";

            // /api/Auth/Login — 30/min, sliding window to prevent burst-on-boundary attacks.
            options.AddPolicy("auth-login", ctx => RateLimitPartition.GetSlidingWindowLimiter(
                PartitionKey(ctx),
                _ => new SlidingWindowRateLimiterOptions
                {
                    PermitLimit = 30, Window = TimeSpan.FromMinutes(1),
                    SegmentsPerWindow = 6, QueueLimit = 0, AutoReplenishment = true
                }));

            // /api/Auth/Register — tight to discourage account spam.
            options.AddPolicy("auth-register", ctx => RateLimitPartition.GetSlidingWindowLimiter(
                PartitionKey(ctx),
                _ => new SlidingWindowRateLimiterOptions
                {
                    PermitLimit = 5, Window = TimeSpan.FromMinutes(1),
                    SegmentsPerWindow = 6, QueueLimit = 0, AutoReplenishment = true
                }));

            // /api/Auth/RefreshToken — 60/min for NAT-shared offices.
            options.AddPolicy("auth-refresh", ctx => RateLimitPartition.GetSlidingWindowLimiter(
                PartitionKey(ctx),
                _ => new SlidingWindowRateLimiterOptions
                {
                    PermitLimit = 60, Window = TimeSpan.FromMinutes(1),
                    SegmentsPerWindow = 6, QueueLimit = 0, AutoReplenishment = true
                }));

            // /api/Auth/Logout — cap so a stolen token can't churn the refresh-token table.
            options.AddPolicy("auth-logout", ctx => RateLimitPartition.GetSlidingWindowLimiter(
                PartitionKey(ctx),
                _ => new SlidingWindowRateLimiterOptions
                {
                    PermitLimit = 30, Window = TimeSpan.FromMinutes(1),
                    SegmentsPerWindow = 6, QueueLimit = 0, AutoReplenishment = true
                }));

            // /api/RegistrationRequests/Submit — separate bucket from auth-register to avoid cross-controller interference.
            options.AddPolicy("registration-submit", ctx => RateLimitPartition.GetSlidingWindowLimiter(
                PartitionKey(ctx),
                _ => new SlidingWindowRateLimiterOptions
                {
                    PermitLimit = 5, Window = TimeSpan.FromMinutes(1),
                    SegmentsPerWindow = 6, QueueLimit = 0, AutoReplenishment = true
                }));

            // SuperAdmin endpoints — slow enumeration if the obscure URL is leaked.
            options.AddPolicy("super-admin", ctx => RateLimitPartition.GetSlidingWindowLimiter(
                PartitionKey(ctx),
                _ => new SlidingWindowRateLimiterOptions
                {
                    PermitLimit = 60, Window = TimeSpan.FromMinutes(1),
                    SegmentsPerWindow = 6, QueueLimit = 0, AutoReplenishment = true
                }));
        });

        return services;
    }
}
