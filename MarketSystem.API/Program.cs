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

TimeZoneInfo tashkentTimeZone = TimeZoneInfo.FindSystemTimeZoneById("Central Asia Standard Time");

AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", false);

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

    builder.Host.UseSerilog();

    builder.Services.AddSingleton(TimeZoneInfo.FindSystemTimeZoneById("Central Asia Standard Time"));

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

            options.Events = new JwtBearerEvents()
            {
                OnMessageReceived = context =>
                {
                    var token = context.Token;
                    if (string.IsNullOrEmpty(token))
                    {
                        token = context.Request.Query["token"];
                        if (!string.IsNullOrEmpty(token))
                        {
                            context.Token = token;
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
    builder.Services.AddCors(options =>
    {
        options.AddPolicy("DevelopmentCors", policy =>
        {
            policy.SetIsOriginAllowed((origin) => true)
                  .AllowAnyMethod()
                  .AllowAnyHeader()
                  .AllowCredentials();
        });

        options.AddPolicy("ProductionCors", policy =>
        {
            policy.SetIsOriginAllowed((origin) =>
                {
                    // Log the origin for debugging
                    Console.WriteLine($"[CORS] Origin request: {origin}");

                    if (string.IsNullOrEmpty(origin)) return false;
                    // Allow localhost, server IP, and internal Docker network
                    return origin.Contains("localhost") ||
                           origin.Contains("127.0.0.1") ||
                           origin.Contains("103.125.217.28") ||
                           origin.Contains("10.0.1.201") ||
                           origin.Contains("114.29.239.156") || // Production server
                           origin.Contains("172.") ||  // Docker internal network
                           origin.Contains("192.168.") || // Local network
                           origin.Contains("market-system-client"); // Docker service name
                })
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

    builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(MarketSystem.Application.Commands.CreateSaleCommand).Assembly));

    var app = builder.Build();
    _ = Task.Run(async () =>
    {
        using var scope = app.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        try
        {
            Log.Information("Starting database migration (background)...");
            var canConnect = await dbContext.Database.CanConnectAsync();
            if (canConnect)
            {
                Log.Information("Applying database migrations...");
                await dbContext.Database.MigrateAsync();
                Log.Information("Database migrations applied successfully");
            }
            else
            {
                Log.Warning("Database not ready yet, will retry on next request");
            }
        }
        catch (Exception ex)
        {
            Log.Warning(ex, "Failed to apply migrations - database might not be ready yet");
            Log.Information("Application will continue, migrations will retry on demand");

        }
    });



    app.UseMiddleware<GlobalExceptionHandlerMiddleware>();
    app.UseSerilogRequestLogging();
    app.UseMiddleware<RequestLoggingMiddleware>();
    app.UseCors(app.Environment.IsDevelopment() ? "DevelopmentCors" : "ProductionCors");

    app.UseStaticFiles();
    app.UseAuthentication();
    app.UseAuthorization();

    app.UseMiddleware<TenantResolutionMiddleware>();

    app.MapSwagger();
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
            var response = new
            {
                status = canConnect ? "healthy" : "unhealthy",
                database = canConnect ? "connected" : "disconnected",
                timestamp = DateTime.UtcNow,
                environment = Environment.GetEnvironmentVariable("ASPNETCORE_ENVIRONMENT") ?? "Unknown",
                version = "1.0.0"
            };
            return canConnect ? Results.Ok(response) : Results.Json(new { status = "unhealthy", database = "disconnected" }, statusCode: 503);
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "Health check failed");
            return Results.Json(new { status = "unhealthy", database = "error", error = ex.Message }, statusCode: 503);
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
        app.MapGet("/seed", async (IConfiguration config, IServiceProvider services) =>
        {
            var scope = services.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            if (await context.Markets.AnyAsync() || await context.Users.AnyAsync())
            {
                return Results.Ok(new { message = "Database already seeded" });
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

            var superAdmin = new User
            {
                Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                FullName = "Super Administrator",
                Username = "superadmin",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("superadmin123"),
                Role = Role.SuperAdmin,
                IsActive = true,
                Language = Language.Uzbek,
                MarketId = defaultMarket.Id
            };
            context.Users.Add(superAdmin);

            var owner = new User
            {
                Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                FullName = "Market Owner",
                Username = "marketadminsystem",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("marketsystem1234567890"),
                Role = Role.Owner,
                IsActive = true,
                Language = Language.Uzbek,
                MarketId = defaultMarket.Id
            };
            context.Users.Add(owner);

            var admin = new User
            {
                Id = Guid.Parse("33333333-3333-3333-3333-333333333333"),
                FullName = "System Admin",
                Username = "admin",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"),
                Role = Role.Admin,
                IsActive = true,
                Language = Language.Uzbek,
                MarketId = defaultMarket.Id
            };
            context.Users.Add(admin);

            var seller = new User
            {
                Id = Guid.Parse("44444444-4444-4444-4444-444444444444"),
                FullName = "Seller User",
                Username = "seller",
                PasswordHash = BCrypt.Net.BCrypt.HashPassword("seller123"),
                Role = Role.Seller,
                IsActive = true,
                Language = Language.Uzbek,
                MarketId = defaultMarket.Id
            };
            context.Users.Add(seller);

            await context.SaveChangesAsync();

            return Results.Ok(new
            {
                message = "Database seeded successfully with multi-tenant support",
                market = new { name = "Demo Market", id = defaultMarket.Id },
                users = new[]
                {
                new { username = "superadmin", password = "superadmin123", role = "SuperAdmin", note = "Can create/manage all markets" },
                new { username = "marketadminsystem", password = "marketsystem1234567890", role = "Owner", note = "Owner of Demo Market (Default)" },
                new { username = "admin", password = "admin123", role = "Admin", note = "Administrator of Demo Market" },
                new { username = "seller", password = "seller123", role = "Seller", note = "Seller in Demo Market" }
                }
            });
        }).WithName("Seed Database").AllowAnonymous();
    }

    await TestRunner.RunTestAsync(app.Services);
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
