using MarketSystem.API;
using MarketSystem.API.Extensions;
using MarketSystem.API.Middleware;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Data;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using OfficeOpenXml;
using Serilog;
using Serilog.Events;

// Resolve Tashkent (GMT+5). .NET 6+ maps Windows IDs to IANA on Linux out of the box,
// but a hostile env var (DOTNET_SYSTEM_GLOBALIZATION_INVARIANT) can break it. We try
// IANA first (works on Linux/macOS), fall back to the Windows ID, and finally to a fixed
// offset so the process never fails to start over timezone resolution.
TimeZoneInfo tashkentTimeZone = ResolveTashkentTimeZone();

AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", false);

static TimeZoneInfo ResolveTashkentTimeZone()
{
    foreach (var id in new[] { "Asia/Tashkent", "Central Asia Standard Time" })
    {
        try { return TimeZoneInfo.FindSystemTimeZoneById(id); }
        catch (TimeZoneNotFoundException) { }
        catch (InvalidTimeZoneException) { }
    }
    return TimeZoneInfo.CreateCustomTimeZone("Asia/Tashkent", TimeSpan.FromHours(5), "Tashkent", "Tashkent");
}

ExcelPackage.LicenseContext = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") == "Development"
    ? LicenseContext.NonCommercial
    : LicenseContext.Commercial;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Debug()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Information)
    .MinimumLevel.Override("Microsoft.AspNetCore", LogEventLevel.Information)
    .MinimumLevel.Override("Microsoft.EntityFrameworkCore", LogEventLevel.Warning)
    .MinimumLevel.Override("System", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "MarketSystem")
    .WriteTo.Console(
        outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}",
        restrictedToMinimumLevel: LogEventLevel.Information
    )
    .WriteTo.File(
        path: "logs/marketsystem-.log",
        rollingInterval: RollingInterval.Day,
        retainedFileCountLimit: 30,
        outputTemplate: "[{Timestamp:yyyy-MM-dd HH:mm:ss} {Level:u3}] {Message:lj}{NewLine}{Exception}",
        restrictedToMinimumLevel: LogEventLevel.Warning
    )
    .CreateLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    Log.Information("Starting Market System API");
    Log.Information("Environment: {Environment}", builder.Environment.IsDevelopment() ? "Development" : "Production");
    Log.Information("Logging to: Console");
    Log.Information("Time Zone: GMT+5 (Tashkent Time)");

    // Fail fast if required secrets are missing — no defaults baked in.
    var jwtKey = builder.Configuration["Jwt:Key"];
    if (string.IsNullOrWhiteSpace(jwtKey) || jwtKey.Length < 32)
    {
        throw new InvalidOperationException(
            "Jwt:Key is missing or shorter than 32 characters. " +
            "Set it via environment variable (Jwt__Key) or appsettings.Development.json. " +
            "Generate with: openssl rand -base64 48");
    }
    var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
    if (string.IsNullOrWhiteSpace(connectionString))
    {
        throw new InvalidOperationException(
            "ConnectionStrings:DefaultConnection is missing. " +
            "Set it via environment variable (ConnectionStrings__DefaultConnection) or appsettings.Development.json.");
    }

    builder.Host.UseSerilog();

    // Re-use the already-resolved Tashkent zone (handles Windows-ID vs IANA + fallback).
    builder.Services.AddSingleton(tashkentTimeZone);

    builder.Services.AddDatabase(builder.Configuration, builder.Environment);

    var port = Environment.GetEnvironmentVariable("PORT") ??
               Environment.GetEnvironmentVariable("ASPNETCORE_HTTP_PORTS") ??
               Environment.GetEnvironmentVariable("ASPNETCORE_URLS")?.Split(':').Last() ??
               "8080";
    // Use 0.0.0.0 for Docker compatibility (allows external access)
    builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
    Log.Information("Configuring to listen on: http://0.0.0.0:{0}", port);

    builder.Services.AddHealthChecks();

    // HSTS config — 180 days, includes subdomains. Preload is NOT enabled
    // because that's a domain-level commitment that the operator owns.
    builder.Services.AddHsts(options =>
    {
        options.MaxAge = TimeSpan.FromDays(180);
        options.IncludeSubDomains = true;
        options.Preload = false;
    });

    // Redirect HTTP -> HTTPS. nginx already does 301 at the edge; this is
    // a defence-in-depth net so Kestrel never serves a sensitive response
    // over plain HTTP if nginx is misconfigured or bypassed.
    builder.Services.AddHttpsRedirection(options =>
    {
        options.RedirectStatusCode = StatusCodes.Status308PermanentRedirect;
        options.HttpsPort = 443;
    });

    builder.Services.AddJwtAuthentication(builder.Configuration, builder.Environment);
    builder.Services.AddAuthorizationPolicies();
    builder.Services.AddApiRateLimiter();
    builder.Services.AddApiCors(builder.Configuration, builder.Environment);

    builder.Services.AddControllers()
        .AddJsonOptions(options =>
        {
            options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
            options.JsonSerializerOptions.Converters.Add(new MarketSystem.Domain.Extensions.TashkentTimeJsonConverter());
            options.JsonSerializerOptions.Converters.Add(new MarketSystem.Domain.Extensions.TashkentTimeJsonConverterNullable());
        });

    builder.WebHost.ConfigureKestrel(options =>
    {
        options.Limits.MaxRequestBodySize = 10 * 1024 * 1024; // 10 MB
    });

    builder.Services.AddEndpointsApiExplorer();

    builder.Services.AddSwaggerGen(options =>
    {
        options.SwaggerDoc("v1", new OpenApiInfo
        {
            Title = "MarketSystem API",
            Version = "v1",
            Description = "Market Management System API with Sales, Inventory, and Debt Tracking"
        });

        options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
        {
            Description = "JWT Authorization header using the Bearer scheme. Enter 'Bearer' [space] and then your token in the text input below. Example: 'Bearer 12345abcdef'",
            Name = "Authorization",
            In = ParameterLocation.Header,
            Type = SecuritySchemeType.ApiKey,
            Scheme = "Bearer"
        });

        options.AddSecurityRequirement(new OpenApiSecurityRequirement
        {
            {
                new OpenApiSecurityScheme
                {
                    Reference = new OpenApiReference
                    {
                        Type = ReferenceType.SecurityScheme,
                        Id = "Bearer"
                    }
                },
                Array.Empty<string>()
            }
        });

        var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
        var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
        if (File.Exists(xmlPath))
            options.IncludeXmlComments(xmlPath);
    });

    builder.Services.AddSignalR();
    builder.Services.AddHttpContextAccessor();
    builder.Services.AddApplicationServices();

    var app = builder.Build();

    // Apply pending migrations BEFORE the host starts accepting requests.
    await app.ApplyMigrationsAsync();

    // Bootstrap the SuperAdmin user from env vars on first launch (idempotent).
    // Must run AFTER migrations.
    await MarketSystem.API.Bootstrap.SuperAdminSeeder.SeedFromConfigAsync(
        app.Services,
        app.Services.GetRequiredService<ILogger<Program>>());

    // Load persisted revoked tokens into memory so restart doesn't re-allow them.
    var revokedTokenStore = app.Services.GetRequiredService<MarketSystem.Infrastructure.Services.DbRevokedTokenStore>();
    await revokedTokenStore.LoadFromDbAsync();

    // Trust X-Forwarded-* headers from the reverse proxy (nginx).
    // We do NOT enable XForwardedHost — nginx doesn't override the Host header
    // and accepting it from a spoof source opens host-header injection.
    var fwdOptions = new ForwardedHeadersOptions
    {
        ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto,
        ForwardedForHeaderName = "X-Forwarded-For",
        ForwardedProtoHeaderName = "X-Forwarded-Proto",
        ForwardLimit = 2
    };
    // Defaults trust only loopback. Inside Docker compose the proxy lives on the
    // bridge network, so we explicitly trust private RFC1918 ranges.
    fwdOptions.KnownNetworks.Add(new Microsoft.AspNetCore.HttpOverrides.IPNetwork(
        System.Net.IPAddress.Parse("10.0.0.0"), 8));
    fwdOptions.KnownNetworks.Add(new Microsoft.AspNetCore.HttpOverrides.IPNetwork(
        System.Net.IPAddress.Parse("172.16.0.0"), 12));
    fwdOptions.KnownNetworks.Add(new Microsoft.AspNetCore.HttpOverrides.IPNetwork(
        System.Net.IPAddress.Parse("192.168.0.0"), 16));
    app.UseForwardedHeaders(fwdOptions);

    // GlobalExceptionHandler runs as early as possible so it catches errors
    // from every downstream middleware (CORS, auth, routing, controllers).
    app.UseMiddleware<GlobalExceptionHandlerMiddleware>();

    // HTTPS termination nginx tomonida amalga oshiriladi.
    // Kestrel faqat HTTP qabul qiladi — redirect kerak emas.
    app.UseSerilogRequestLogging();
    app.UseMiddleware<CorrelationLoggingMiddleware>();
    app.UseMiddleware<RequestLoggingMiddleware>();
    app.UseCors(app.Environment.IsDevelopment() ? "DevelopmentCors" : "ProductionCors");

    app.UseStaticFiles();
    // SuperAdmin URL gate — MUST run before UseAuthentication so an
    // unauthenticated probe to the wrong path returns 404 (not 401).
    app.UseMiddleware<SuperAdminPathGateMiddleware>();
    app.UseRateLimiter();
    app.UseAuthentication();
    app.UseAuthorization();
    app.UseMiddleware<TenantResolutionMiddleware>();

    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "MarketSystem API v1");
        options.DocumentTitle = "MarketSystem API Documentation";
        options.DefaultModelsExpandDepth(1);
        options.RoutePrefix = "swagger";
    });

    app.MapGet("/health", async (AppDbContext db, ILogger<Program> logger) =>
    {
        try
        {
            var canConnect = await db.Database.CanConnectAsync();
            return canConnect
                ? Results.Ok(new { status = "healthy" })
                : Results.Json(new { status = "unhealthy" }, statusCode: 503);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Health check failed");
            return Results.Json(new { status = "unhealthy" }, statusCode: 503);
        }
    })
        .ExcludeFromDescription()
        .WithName("Health Check")
        .AllowAnonymous();

    app.MapGet("/privacy", (IWebHostEnvironment env) =>
    {
        var webRootPath = env.WebRootPath;
        if (string.IsNullOrEmpty(webRootPath))
            webRootPath = Path.Combine(env.ContentRootPath, "wwwroot");
        var filePath = Path.Combine(webRootPath, "privacy.html");
        if (!File.Exists(filePath))
            return Results.NotFound(new { error = "Privacy policy file not found" });
        return Results.File(filePath, "text/html");
    })
    .ExcludeFromDescription()
    .WithName("Privacy Policy");

    app.MapControllers();
    app.MapHub<MarketSystem.API.Hubs.SalesHub>("/hubs/sales");

    if (app.Environment.IsDevelopment())
    {
        // Dev-only seeder. Reads credentials from env vars; refuses to run otherwise.
        // Required env: SEED_SUPERADMIN_PASSWORD, SEED_OWNER_PASSWORD
        app.MapGet("/seed", async (IConfiguration config, IServiceProvider services) =>
        {
            using var scope = services.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            if (await context.Markets.AnyAsync() || await context.Users.AnyAsync())
                return Results.Ok(new { message = "Database already seeded" });

            string? Pw(string envName) => Environment.GetEnvironmentVariable(envName);

            var superAdminPw = Pw("SEED_SUPERADMIN_PASSWORD");
            var ownerPw = Pw("SEED_OWNER_PASSWORD");
            if (string.IsNullOrWhiteSpace(superAdminPw) || string.IsNullOrWhiteSpace(ownerPw))
            {
                return Results.BadRequest(new
                {
                    error = "Seed refused: SEED_SUPERADMIN_PASSWORD and SEED_OWNER_PASSWORD must be set."
                });
            }

            var defaultMarket = new Market
            {
                Name = "Demo Market",
                Subdomain = "demo",
                Description = "Default demo market for testing",
                IsActive = true,
                CreatedAt = DateTime.UtcNow
            };
            context.Markets.Add(defaultMarket);
            await context.SaveChangesAsync();

            void AddUser(string username, string fullName, string password, Role role)
            {
                context.Users.Add(new User
                {
                    Id = Guid.NewGuid(),
                    FullName = fullName,
                    Username = username,
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
                    Role = role,
                    IsActive = true,
                    Language = Language.Uzbek,
                    MarketId = defaultMarket.Id
                });
            }

            AddUser("superadmin", "Super Administrator", superAdminPw, Role.SuperAdmin);
            AddUser("owner", "Market Owner", ownerPw, Role.Owner);

            var adminPw = Pw("SEED_ADMIN_PASSWORD");
            if (!string.IsNullOrWhiteSpace(adminPw)) AddUser("admin", "System Admin", adminPw, Role.Admin);
            var sellerPw = Pw("SEED_SELLER_PASSWORD");
            if (!string.IsNullOrWhiteSpace(sellerPw)) AddUser("seller", "Seller User", sellerPw, Role.Seller);

            await context.SaveChangesAsync();

            return Results.Ok(new
            {
                message = "Database seeded. Credentials are NOT returned — use the env values you set."
            });
        }).WithName("Seed Database").AllowAnonymous();
    }

    app.Run();
}
catch (Exception ex)
{
    Log.Fatal(ex, "Application start-up failed");
}
finally
{
    Log.CloseAndFlush();
}
