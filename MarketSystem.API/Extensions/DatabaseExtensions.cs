using MarketSystem.Application.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Serilog;

namespace MarketSystem.API.Extensions;

public static class DatabaseExtensions
{
    public static IServiceCollection AddDatabase(this IServiceCollection services, IConfiguration configuration, IWebHostEnvironment env)
    {
        services.AddDbContext<AppDbContext>(options =>
        {
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection"),
                npgsqlOptions =>
                {
                    npgsqlOptions.CommandTimeout(30);
                    npgsqlOptions.EnableRetryOnFailure(
                        maxRetryCount: 5,
                        maxRetryDelay: TimeSpan.FromSeconds(10),
                        errorCodesToAdd: null);
                    npgsqlOptions.MigrationsAssembly("MarketSystem.Infrastructure");
                });
            options.EnableSensitiveDataLogging(env.IsDevelopment());

            options.ConfigureWarnings(warnings =>
                warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
        });

        // Application layer depends on IAppDbContext abstraction (DIP).
        services.AddScoped<IAppDbContext>(sp => sp.GetRequiredService<AppDbContext>());

        return services;
    }

    public static async Task ApplyMigrationsAsync(this WebApplication app)
    {
        const int maxAttempts = 5;
        for (var attempt = 1; ; attempt++)
        {
            using var scope = app.Services.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            try
            {
                Log.Information("Applying database migrations (attempt {Attempt}/{Max})...", attempt, maxAttempts);
                await dbContext.Database.MigrateAsync();
                Log.Information("Database migrations applied successfully.");
                break;
            }
            catch (Exception ex) when (attempt < maxAttempts)
            {
                Log.Warning(ex, "Migration attempt {Attempt} failed; retrying in 3s.", attempt);
                await Task.Delay(TimeSpan.FromSeconds(3));
            }
        }
    }
}
