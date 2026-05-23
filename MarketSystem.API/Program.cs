using MarketSystem.API;
using MarketSystem.API.Middleware;
using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Services;
using MarketSystem.Application.Settings;
using MarketSystem.Domain.Common;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using MarketSystem.Infrastructure.Repositories;
using MarketSystem.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using System.Security.Claims;
using Serilog.Events;
using System.Text;

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
    .CreateLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    Log.Information("Starting Market System API");
    Log.Information("Environment: {Environment}", builder.Environment.IsDevelopment() ? "Development" : "Production");
    Log.Information("Logging to: PostgreSQL + Console");
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

    builder.Services.AddDbContext<AppDbContext>(options =>
    {
        options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"),
            npgsqlOptions =>
            {
                npgsqlOptions.CommandTimeout(30);
                npgsqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 5,
                    maxRetryDelay: TimeSpan.FromSeconds(10),
                    errorCodesToAdd: null);
                npgsqlOptions.MigrationsAssembly("MarketSystem.Infrastructure");
            });
        options.EnableSensitiveDataLogging(builder.Environment.IsDevelopment());

        options.ConfigureWarnings(warnings =>
            warnings.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
    });

    // Application-layer services depend on IAppDbContext (Domain abstraction)
    // rather than the concrete AppDbContext. Both resolutions share the same
    // scoped instance — without this binding, DI throws "Unable to resolve
    // service for type 'IAppDbContext'" on every service that wants the abstraction.
    builder.Services.AddScoped<MarketSystem.Domain.Interfaces.IAppDbContext>(
        sp => sp.GetRequiredService<AppDbContext>());

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
    // HttpsPort MUST be set (443 = the public-facing port nginx terminates
    // TLS on) — otherwise UseHttpsRedirection silently no-ops, which would
    // make the "defence in depth" claim a lie.
    builder.Services.AddHttpsRedirection(options =>
    {
        options.RedirectStatusCode = StatusCodes.Status308PermanentRedirect;
        options.HttpsPort = 443;
    });


    // Add JWT Authentication
    builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
        .AddJwtBearer(options =>
        {
            var jwtParam = builder.Configuration.GetSection("Jwt").Get<JwtSetting>()!;
            var key = Encoding.UTF8.GetBytes(jwtParam.Key);
            options.TokenValidationParameters = new TokenValidationParameters()
            {
                ValidIssuer = jwtParam.Issuer,
                ValidateIssuer = true,
                ValidAudience = jwtParam.Audience,
                ValidateAudience = true,
                IssuerSigningKey = new SymmetricSecurityKey(key),
                ValidateIssuerSigningKey = true,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero,
                RoleClaimType = ClaimTypes.Role,
                NameClaimType = ClaimTypes.Name
            };

            options.RequireHttpsMetadata = !builder.Environment.IsDevelopment();
            options.Events = new JwtBearerEvents()
            {
                OnMessageReceived = context =>
                {
                    // Browser WebSocket clients can't set Authorization headers,
                    // so accept the token via ?token= ONLY on SignalR hub paths.
                    var path = context.HttpContext.Request.Path;
                    if (string.IsNullOrEmpty(context.Token) &&
                        path.StartsWithSegments("/hubs"))
                    {
                        var queryToken = context.Request.Query["token"].ToString();
                        if (!string.IsNullOrEmpty(queryToken))
                        {
                            context.Token = queryToken;
                        }
                    }
                    return Task.CompletedTask;
                },
                OnTokenValidated = context =>
                {
                    // Reject access tokens whose jti has been revoked (logout,
                    // refresh rotation, suspicious-refresh defensive revoke).
                    // Without this, an attacker who steals a token can use it
                    // for the full 30-minute TTL even after the user logs out.
                    var jti = context.Principal?.FindFirst(
                        System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Jti)?.Value;
                    if (!string.IsNullOrEmpty(jti))
                    {
                        var store = context.HttpContext.RequestServices
                            .GetRequiredService<IRevokedTokenStore>();
                        if (store.IsRevoked(jti))
                        {
                            context.Fail("Token has been revoked.");
                        }
                    }
                    return Task.CompletedTask;
                }
            };
        });

    builder.Services.AddAuthorization(options =>
    {
        options.AddPolicy("OwnerOnly", policy =>
            policy.RequireRole("Owner"));

        options.AddPolicy("AdminOrOwner", policy =>
            policy.RequireRole("Owner", "Admin"));

        options.AddPolicy("OwnerOrSuperAdmin", policy =>
            policy.RequireRole("Owner", "SuperAdmin"));

        options.AddPolicy("AllRoles", policy =>
            policy.RequireRole("Owner", "Admin", "Seller"));
    });

    // Owner RBAC — dynamic "perm:<key>" policies behind [RequirePermission(...)].
    // The custom provider synthesises a PermissionRequirement for those names
    // and delegates every other policy name to the default provider.
    builder.Services.AddSingleton<IAuthorizationPolicyProvider, MarketSystem.API.Authorization.PermissionPolicyProvider>();
    builder.Services.AddScoped<IAuthorizationHandler, MarketSystem.API.Authorization.PermissionAuthorizationHandler>();

    // Rate limiting on authentication endpoints. We use a SLIDING window (6 segments
    // per minute) instead of fixed-window so a client cannot burst 2x the limit by
    // straddling the window boundary. Per-IP partitioning is NAT-tolerant because the
    // limits are calibrated for shared-IP offices: 30 logins/min lets a NAT'd office
    // of 20-30 users work normally but still cuts off automated brute-force.
    //
    // X-Forwarded-For is only honoured because UseForwardedHeaders trusts our internal
    // proxy network (see fwdOptions above). Spoofing it from outside Docker is blocked
    // by the trust list.
    builder.Services.AddRateLimiter(options =>
    {
        options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
        options.OnRejected = async (ctx, ct) =>
        {
            // Surface the real "try again in" hint if the limiter exposes it; otherwise
            // fall back to the window length so the client always has a usable value.
            var retryAfter = ctx.Lease.TryGetMetadata(
                System.Threading.RateLimiting.MetadataName.RetryAfter, out var ts)
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

        static string PartitionKey(HttpContext ctx)
        {
            // RemoteIpAddress is already rewritten by UseForwardedHeaders when the
            // request came in through our trusted proxy chain; for direct (non-proxied)
            // requests it stays as the real socket peer. Either way, this is the
            // authoritative client IP from ASP.NET's perspective.
            return ctx.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        }

        // /api/Auth/Login — sliding window protects against burst-on-boundary attacks.
        // 30/min is NAT-friendly while still rate-limiting automated brute-force.
        options.AddPolicy("auth-login", ctx => System.Threading.RateLimiting.RateLimitPartition.GetSlidingWindowLimiter(
            PartitionKey(ctx),
            _ => new System.Threading.RateLimiting.SlidingWindowRateLimiterOptions
            {
                PermitLimit = 30,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueLimit = 0,
                AutoReplenishment = true
            }));

        // /api/Auth/Register — keep tight to discourage account spam.
        options.AddPolicy("auth-register", ctx => System.Threading.RateLimiting.RateLimitPartition.GetSlidingWindowLimiter(
            PartitionKey(ctx),
            _ => new System.Threading.RateLimiting.SlidingWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueLimit = 0,
                AutoReplenishment = true
            }));

        // /api/Auth/RefreshToken — normal clients refresh once per token lifetime.
        // 60/min lets several users on the same NAT IP refresh without colliding.
        options.AddPolicy("auth-refresh", ctx => System.Threading.RateLimiting.RateLimitPartition.GetSlidingWindowLimiter(
            PartitionKey(ctx),
            _ => new System.Threading.RateLimiting.SlidingWindowRateLimiterOptions
            {
                PermitLimit = 60,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueLimit = 0,
                AutoReplenishment = true
            }));

        // /api/Auth/Logout — cheap operation but reachable with a valid token; cap
        // the rate so a stolen token can't churn the refresh-token table.
        options.AddPolicy("auth-logout", ctx => System.Threading.RateLimiting.RateLimitPartition.GetSlidingWindowLimiter(
            PartitionKey(ctx),
            _ => new System.Threading.RateLimiting.SlidingWindowRateLimiterOptions
            {
                PermitLimit = 30,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueLimit = 0,
                AutoReplenishment = true
            }));

        // SuperAdmin endpoints — slow enumeration if the obscure URL is leaked.
        // Per-IP because the JWT role check is the primary gate; this just stops
        // a sustained scanner from churning the audit log.
        options.AddPolicy("super-admin", ctx => System.Threading.RateLimiting.RateLimitPartition.GetSlidingWindowLimiter(
            PartitionKey(ctx),
            _ => new System.Threading.RateLimiting.SlidingWindowRateLimiterOptions
            {
                PermitLimit = 60,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueLimit = 0,
                AutoReplenishment = true
            }));

        // /api/RegistrationRequests — public, anonymous sign-up submissions.
        // Tighter than auth-register because there's no captcha gate; a bot
        // farm could otherwise flood the SuperAdmin's pending-request queue.
        // The application layer also enforces a partial unique index on
        // (Phone) WHERE Status=Pending, so duplicate spam from one number
        // gets dropped at the DB; this policy stops the burst before it
        // reaches that index.
        options.AddPolicy("registration-submit", ctx => System.Threading.RateLimiting.RateLimitPartition.GetSlidingWindowLimiter(
            PartitionKey(ctx),
            _ => new System.Threading.RateLimiting.SlidingWindowRateLimiterOptions
            {
                PermitLimit = 3,
                Window = TimeSpan.FromMinutes(1),
                SegmentsPerWindow = 6,
                QueueLimit = 0,
                AutoReplenishment = true
            }));
    });
    // CORS origins — accepts:
    //   appsettings.json: "Cors:AllowedOrigins": ["https://a", "https://b"]
    //   env (single):     Cors__AllowedOrigins=https://a,https://b
    //   env (indexed):    Cors__AllowedOrigins__0=https://a, Cors__AllowedOrigins__1=https://b
    // Both forms collapse into one deduped list of non-empty trimmed strings.
    string[] configuredOrigins;
    {
        var section = builder.Configuration.GetSection("Cors:AllowedOrigins");
        var asArray = section.Get<string[]>();
        var asString = section.Value; // populated when the env is a single comma-separated value
        var raw = asArray ?? (string.IsNullOrWhiteSpace(asString)
            ? Array.Empty<string>()
            : new[] { asString });
        configuredOrigins = raw
            .SelectMany(o => (o ?? string.Empty).Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
            .Where(o => !string.IsNullOrWhiteSpace(o))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    builder.Services.AddCors(options =>
    {
        options.AddPolicy("DevelopmentCors", policy =>
        {
            // Local dev: allow ANY localhost / 127.0.0.1 origin regardless of port.
            // `flutter run -d chrome` picks a random web port on every launch, so a
            // fixed allow-list keeps breaking the moment the dev re-runs. This is
            // dev-only — ProductionCors below stays strict.
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
                  .AllowAnyHeader()
                  .AllowCredentials();
        });

        options.AddPolicy("ProductionCors", policy =>
        {
            if (configuredOrigins.Length == 0)
            {
                Log.Warning("Cors:AllowedOrigins is empty in production. All cross-origin requests will be rejected.");
            }
            policy.WithOrigins(configuredOrigins)
                  .AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials();
        });
    });

    builder.Services.AddControllers()
        .AddJsonOptions(options =>
        {
            options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;

            options.JsonSerializerOptions.Converters.Add(new MarketSystem.Domain.Extensions.TashkentTimeJsonConverter());
            options.JsonSerializerOptions.Converters.Add(new MarketSystem.Domain.Extensions.TashkentTimeJsonConverterNullable());
        });

    builder.WebHost.ConfigureKestrel(options =>
    {
        options.Limits.MaxRequestBodySize = 50 * 1024 * 1024; // 50 MB
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

        options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme()
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
        {
            options.IncludeXmlComments(xmlPath);
        }
    });

    builder.Services.AddSignalR();

    builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

    builder.Services.AddHttpContextAccessor();

    builder.Services.AddScoped<IJwtService, JwtService>();
    builder.Services.AddScoped<IAuthService, AuthService>();
    builder.Services.AddScoped<IUserService, UserService>();
    builder.Services.AddScoped<IProductService, ProductService>();
    builder.Services.AddScoped<IProductCategoryService, ProductCategoryService>();
    builder.Services.AddScoped<ICustomerService, CustomerService>();
    builder.Services.AddScoped<ISaleService, SaleService>();
    builder.Services.AddScoped<IZakupService, ZakupService>();
    builder.Services.AddScoped<IReportService, ReportService>();
    // One AuditLogService instance per scope satisfies both the write
    // (Domain) and read (Application) interfaces — forward them so the
    // container doesn't materialise two copies per request.
    builder.Services.AddScoped<AuditLogService>();
    builder.Services.AddScoped<IAuditLogService>(sp => sp.GetRequiredService<AuditLogService>());
    builder.Services.AddScoped<IAuditLogQueryService>(sp => sp.GetRequiredService<AuditLogService>());
    builder.Services.AddScoped<ICashRegisterService, CashRegisterService>();
    builder.Services.AddScoped<IMarketService, MarketService>();
    builder.Services.AddScoped<ICurrentMarketService, CurrentMarketService>();
    builder.Services.AddScoped<IExcelService, ExcelService>();
    builder.Services.AddSingleton<ITashkentClock, TashkentClock>();
    builder.Services.AddScoped<IRegistrationRequestService, RegistrationRequestService>();
    builder.Services.AddScoped<IDebtService, DebtService>();
    builder.Services.AddScoped<IShiftService, ShiftService>();
    // Singleton — the revocation map must outlive any single request.
    // DbRevokedTokenStore caches entries in memory for O(1) IsRevoked() on
    // the auth hot path, but persists each RevokeAsync write to PostgreSQL
    // so revocations survive restarts and propagate across replicas. The
    // cache is rehydrated from the DB once during startup (below).
    builder.Services.AddSingleton<DbRevokedTokenStore>();
    builder.Services.AddSingleton<IRevokedTokenStore>(
        sp => sp.GetRequiredService<DbRevokedTokenStore>());

    var app = builder.Build();

    // Apply pending migrations BEFORE the host starts accepting requests.
    // Running migrations in the background races app.Run() and lets HTTP traffic
    // hit a partially-migrated schema. We block startup until they finish.
    // Migration failure on the final attempt is a fatal startup error — we'd rather
    // fail fast than serve requests against an inconsistent database.
    {
        const int maxAttempts = 5;
        for (var attempt = 1; ; attempt++)
        {
            // Fresh DI scope per attempt — EF Core does NOT guarantee the DbContext
            // can be safely reused after a failed SaveChanges/Migrate. A new scope
            // gives us a clean DbContext, change tracker, and connection.
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

    // Bootstrap the SuperAdmin user from env vars on first launch (idempotent).
    // See SuperAdminSeeder for details. Must run AFTER migrations.
    await MarketSystem.API.Bootstrap.SuperAdminSeeder.SeedFromConfigAsync(
        app.Services,
        app.Services.GetRequiredService<ILogger<Program>>());

    // Hydrate the in-memory revocation cache from the RevokedTokens table.
    // Without this, every restart would forget which JWTs were revoked and
    // every still-valid leaked token would work again until its natural
    // 30-minute expiry. The store also prunes expired DB rows here so the
    // table stays bounded.
    {
        using var scope = app.Services.CreateScope();
        var store = scope.ServiceProvider.GetRequiredService<DbRevokedTokenStore>();
        await store.LoadFromDbAsync();
    }

    // Trust X-Forwarded-* headers from the reverse proxy (nginx) so HttpContext.Request.Scheme
    // reflects the real HTTPS scheme, RemoteIpAddress is the original client, and
    // RequireHttpsMetadata works correctly behind TLS termination.
    // Without this, ASP.NET sees scheme=http and would reject otherwise-valid HTTPS traffic.
    // Trust X-Forwarded-For / -Proto from the reverse proxy only. We do NOT enable
    // XForwardedHost — nginx doesn't override the Host header for us and accepting
    // it from a spoof source opens host-header injection in any URL we generate.
    var fwdOptions = new ForwardedHeadersOptions
    {
        ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto,
        // Allow longer chains: nginx -> any internal hop -> Kestrel.
        ForwardedForHeaderName = "X-Forwarded-For",
        ForwardedProtoHeaderName = "X-Forwarded-Proto",
        ForwardLimit = 2
    };
    // Defaults trust only loopback. Inside Docker compose the proxy lives on the
    // bridge network, so we explicitly trust private RFC1918 ranges. We do NOT
    // Clear() the lists — clearing trusts every source, which would let any client
    // (e.g. a directly-reachable Kestrel) spoof X-Forwarded-For and bypass the
    // rate limiter's IP partitioning.
    fwdOptions.KnownNetworks.Add(new Microsoft.AspNetCore.HttpOverrides.IPNetwork(
        System.Net.IPAddress.Parse("10.0.0.0"), 8));
    fwdOptions.KnownNetworks.Add(new Microsoft.AspNetCore.HttpOverrides.IPNetwork(
        System.Net.IPAddress.Parse("172.16.0.0"), 12));
    fwdOptions.KnownNetworks.Add(new Microsoft.AspNetCore.HttpOverrides.IPNetwork(
        System.Net.IPAddress.Parse("192.168.0.0"), 16));
    app.UseForwardedHeaders(fwdOptions);

    // GlobalExceptionHandler runs as early as possible so it catches errors
    // from every downstream middleware (CORS, auth, routing, controllers).
    // Only UseForwardedHeaders runs before it — that one can't throw and we
    // want the exception handler to see the corrected Scheme/RemoteIp.
    app.UseMiddleware<GlobalExceptionHandlerMiddleware>();

    // In production, ASP.NET sits behind nginx which terminates TLS. Kestrel
    // itself listens on plain HTTP (port 8080) and is NOT reachable from the
    // public internet (docker-compose binds to 127.0.0.1; see compose file).
    // We add HSTS so browsers refuse to downgrade once they've seen the site
    // over HTTPS, and we redirect HTTP -> HTTPS at the .NET layer as belt-and-
    // braces in case nginx is ever bypassed. ForwardedHeaders (above) ensures
    // Request.IsHttps reflects the real client scheme.
    if (!app.Environment.IsDevelopment())
    {
        // 180-day HSTS with includeSubdomains. Preload is intentionally NOT
        // set — only opt in once the operator has confirmed every subdomain
        // can serve HTTPS.
        app.UseHsts();
        // /health is excluded because the Docker HEALTHCHECK calls
        // http://localhost:8080/health from inside the container with no
        // X-Forwarded-Proto. Redirecting it to https://...:443/health would
        // either fail (no local TLS endpoint) or break the healthcheck loop.
        app.UseWhen(
            ctx => !ctx.Request.Path.StartsWithSegments("/health"),
            branch => branch.UseHttpsRedirection());
    }
    app.UseSerilogRequestLogging();
    app.UseMiddleware<RequestLoggingMiddleware>();
    app.UseCors(app.Environment.IsDevelopment() ? "DevelopmentCors" : "ProductionCors");

    // Standard hardening headers for every response.
    app.Use(async (ctx, next) =>
    {
        ctx.Response.Headers["X-Content-Type-Options"] = "nosniff";
        ctx.Response.Headers["X-Frame-Options"] = "DENY";
        ctx.Response.Headers["Referrer-Policy"] = "strict-origin-when-cross-origin";
        // Content-Security-Policy — this is a JSON API plus a couple of static
        // HTML pages (privacy.html). 'unsafe-inline' is kept for script/style
        // so those pages aren't broken; the real wins here are frame-ancestors
        // (clickjacking), object-src and base-uri lockdown. The Flutter client
        // runs on its own origin and is unaffected.
        ctx.Response.Headers["Content-Security-Policy"] =
            "default-src 'self'; " +
            "script-src 'self' 'unsafe-inline'; " +
            "style-src 'self' 'unsafe-inline'; " +
            "img-src 'self' data:; " +
            "object-src 'none'; " +
            "base-uri 'self'; " +
            "frame-ancestors 'none'";
        await next();
    });

    app.UseStaticFiles();
    // SuperAdmin URL gate — MUST run before UseAuthentication so an
    // unauthenticated probe to the wrong path returns 404 (not 401),
    // keeping the existence of the console hidden.
    app.UseMiddleware<SuperAdminPathGateMiddleware>();
    app.UseRateLimiter();
    app.UseAuthentication();
    app.UseAuthorization();

    app.UseMiddleware<TenantResolutionMiddleware>();

    if (app.Environment.IsDevelopment())
    {
        app.UseSwagger();
        app.UseSwaggerUI(options =>
        {
            options.SwaggerEndpoint("/swagger/v1/swagger.json", "MarketSystem API v1");
            options.DocumentTitle = "MarketSystem API Documentation";
            options.DefaultModelsExpandDepth(1);
            options.RoutePrefix = "swagger";
        });
    }

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
        {
            webRootPath = Path.Combine(env.ContentRootPath, "wwwroot");
        }
        var filePath = Path.Combine(webRootPath, "privacy.html");
        if (!File.Exists(filePath))
        {
            return Results.NotFound(new { error = "Privacy policy file not found" });
        }
        return Results.File(filePath, "text/html");
    })
    .ExcludeFromDescription()
    .WithName("Privacy Policy");

    app.MapControllers();

    app.MapHub<MarketSystem.API.Hubs.SalesHub>("/hubs/sales");

    // Seed endpoint: requires both IsDevelopment() AND SEED_ENABLED=true so it
    // can never fire in production even if the environment var is misconfigured.
    if (app.Environment.IsDevelopment() &&
        Environment.GetEnvironmentVariable("SEED_ENABLED") == "true")
    {
        // Dev-only seeder. Reads credentials from env vars; refuses to run otherwise.
        // Required env:
        //   SEED_ENABLED=true, SEED_SUPERADMIN_PASSWORD, SEED_OWNER_PASSWORD
        // Optional: SEED_ADMIN_PASSWORD, SEED_SELLER_PASSWORD
        app.MapGet("/seed", async (IConfiguration config, IServiceProvider services) =>
        {
            using var scope = services.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            if (await context.Markets.AnyAsync() || await context.Users.AnyAsync())
            {
                return Results.Ok(new { message = "Database already seeded" });
            }

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
