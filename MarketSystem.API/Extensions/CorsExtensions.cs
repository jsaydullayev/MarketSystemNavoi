using Serilog;

namespace MarketSystem.API.Extensions;

public static class CorsExtensions
{
    public static IServiceCollection AddApiCors(this IServiceCollection services, IConfiguration configuration, IWebHostEnvironment env)
    {
        // Accepts:
        //   appsettings.json: "Cors:AllowedOrigins": ["https://a", "https://b"]
        //   env (single):     Cors__AllowedOrigins=https://a,https://b
        //   env (indexed):    Cors__AllowedOrigins__0=https://a, Cors__AllowedOrigins__1=https://b
        var section = configuration.GetSection("Cors:AllowedOrigins");
        var asArray = section.Get<string[]>();
        var asString = section.Value;
        var raw = asArray ?? (string.IsNullOrWhiteSpace(asString)
            ? Array.Empty<string>()
            : new[] { asString });
        var configuredOrigins = raw
            .SelectMany(o => (o ?? string.Empty).Split(',',
                StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            .Where(o => !string.IsNullOrWhiteSpace(o))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        services.AddCors(options =>
        {
            options.AddPolicy("DevelopmentCors", policy =>
            {
                // Local dev: allow ANY localhost / 127.0.0.1 origin regardless of port.
                // `flutter run -d chrome` picks a random web port on every launch, so a
                // fixed allow-list keeps breaking the moment the dev re-runs. Dev-only —
                // ProductionCors below stays strict.
                policy.SetIsOriginAllowed(origin =>
                      {
                          if (string.IsNullOrWhiteSpace(origin)) return false;
                          try
                          {
                              var uri = new Uri(origin);
                              return uri.Host is "localhost" or "127.0.0.1";
                          }
                          catch
                          {
                              return false;
                          }
                      })
                      .AllowAnyMethod()
                      .WithHeaders("Content-Type", "Authorization", "X-Correlation-ID", "X-Requested-With")
                      .AllowCredentials();
            });

            options.AddPolicy("ProductionCors", policy =>
            {
                if (configuredOrigins.Length == 0)
                {
                    if (!env.IsDevelopment())
                        throw new InvalidOperationException(
                            "Cors:AllowedOrigins is not configured. " +
                            "Set it via Cors__AllowedOrigins env var (comma-separated) before starting in production.");

                    Log.Warning("Cors:AllowedOrigins is empty — all cross-origin requests will be rejected.");
                }
                policy.WithOrigins(configuredOrigins)
                      .AllowAnyMethod()
                      .WithHeaders("Content-Type", "Authorization", "X-Correlation-ID", "X-Requested-With")
                      .AllowCredentials();
            });
        });

        return services;
    }
}
