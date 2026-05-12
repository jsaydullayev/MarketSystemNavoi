using MarketSystem.API;
using MarketSystem.API.Middleware;
using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Common;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using MarketSystem.Infrastructure.Repositories;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using OfficeOpenXml;
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

ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

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

    var port = Environment.GetEnvironmentVariable("PORT") ??
               Environment.GetEnvironmentVariable("ASPNETCORE_HTTP_PORTS") ??
               Environment.GetEnvironmentVariable("ASPNETCORE_URLS")?.Split(':').Last() ??
               "8080";
    // Use 0.0.0.0 for Docker compatibility (allows external access)
    builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
    Log.Information("Configuring to listen on: http://0.0.0.0:{0}", port);

    builder.Services.AddHealthChecks();


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
    // Load allowed CORS origins from config (Cors:AllowedOrigins) or env (Cors__AllowedOrigins__0,…).
    var configuredOrigins = builder.Configuration
        .GetSection("Cors:AllowedOrigins")
        .Get<string[]>() ?? Array.Empty<string>();

    builder.Services.AddCors(options =>
    {
        options.AddPolicy("DevelopmentCors", policy =>
        {
            // Local dev defaults — no credentials, exact origins only.
            var devOrigins = configuredOrigins.Length > 0
                ? configuredOrigins
                : new[]
                {
                    "http://localhost:8080",
                    "http://localhost:8081",
                    "http://localhost:3000",
                    "http://127.0.0.1:8080",
                    "http://127.0.0.1:8081"
                };
            policy.WithOrigins(devOrigins)
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
    builder.Services.AddScoped<IAuditLogService, AuditLogService>();
    builder.Services.AddScoped<ICashRegisterService, CashRegisterService>();
    builder.Services.AddScoped<IMarketService, MarketService>();
    builder.Services.AddScoped<ICurrentMarketService, CurrentMarketService>();
    builder.Services.AddScoped<IExcelService, ExcelService>();
    builder.Services.AddSingleton<ITashkentClock, TashkentClock>();

    builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(MarketSystem.Application.Commands.CreateSaleCommand).Assembly));

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



    app.UseMiddleware<GlobalExceptionHandlerMiddleware>();
    app.UseSerilogRequestLogging();
    app.UseMiddleware<RequestLoggingMiddleware>();
    app.UseCors(app.Environment.IsDevelopment() ? "DevelopmentCors" : "ProductionCors");

    app.UseStaticFiles();
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

    if (app.Environment.IsDevelopment())
    {
        // Dev-only seeder. Reads credentials from env vars; refuses to run otherwise.
        // Required env:
        //   SEED_SUPERADMIN_PASSWORD, SEED_OWNER_PASSWORD
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
