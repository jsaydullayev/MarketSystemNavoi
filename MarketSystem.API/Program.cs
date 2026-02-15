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
using System.Text;

// Configure Npgsql to handle DateTime correctly with PostgreSQL timestamp with time zone
// This prevents "Cannot write DateTime with Kind=Unspecified" errors
AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", false);

var builder = WebApplication.CreateBuilder(args);

// Add DbContext with optimizations
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions =>
        {
            npgsqlOptions.CommandTimeout(30);
        });
    options.EnableSensitiveDataLogging(builder.Environment.IsDevelopment());
});

// Add JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        var jwtParam = builder.Configuration.GetSection("Jwt").Get<JwtSetting>()!;
        var key = Encoding.UTF32.GetBytes(jwtParam.Key);
        options.TokenValidationParameters = new TokenValidationParameters()
        {
            ValidIssuer = jwtParam.Issuer,
            ValidateIssuer = true,
            ValidAudience = jwtParam.Audience,
            ValidateAudience = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
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
    // Owner only - full access
    options.AddPolicy("OwnerOnly", policy =>
        policy.RequireRole("Owner"));

    // Admin or Owner - can manage purchases, cancel sales, view reports
    options.AddPolicy("AdminOrOwner", policy =>
        policy.RequireRole("Owner", "Admin"));

    // All authenticated users - can create sales, add items
    options.AddPolicy("AllRoles", policy =>
        policy.RequireRole("Owner", "Admin", "Seller"));
});

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevelopmentCors", policy =>
    {
        policy.SetIsOriginAllowed((origin) => origin != null && (origin.StartsWith("http://localhost") || origin.StartsWith("http://10.0.2.2")))
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });

    options.AddPolicy("ProductionCors", policy =>
    {
        policy.WithOrigins("https://your-frontend-domain.com") // TODO: Update with actual domain
              .WithMethods("GET", "POST", "PUT", "DELETE", "PATCH")
              .WithHeaders("Content-Type", "Authorization")
              .AllowCredentials();
    });
});

// Add Controllers with JSON configuration
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    });

// Configure Kestrel server limits for large image uploads
builder.WebHost.ConfigureKestrel(options =>
{
    options.Limits.MaxRequestBodySize = 50 * 1024 * 1024; // 50 MB
});

builder.Services.AddEndpointsApiExplorer();

// Add Swagger with JWT Authentication
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
        Description = "JWT Bearer. : \"Authorization: Bearer { token } \"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey
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

    // Include XML comments (optional, for documentation)
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath);
    }
});

// Add SignalR
builder.Services.AddSignalR();

// Add Unit of Work and Repositories
builder.Services.AddScoped<IUnitOfWork, UnitOfWork>();

// Add HttpContextAccessor for CurrentMarketService
builder.Services.AddHttpContextAccessor();

// Add Application Services
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<ICustomerService, CustomerService>();
builder.Services.AddScoped<ISaleService, SaleService>();
builder.Services.AddScoped<IZakupService, ZakupService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<IAuditLogService, AuditLogService>();
builder.Services.AddScoped<ICashRegisterService, CashRegisterService>();
builder.Services.AddScoped<IMarketService, MarketService>();
builder.Services.AddScoped<ICurrentMarketService, CurrentMarketService>();

builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(MarketSystem.Application.Commands.CreateSaleCommand).Assembly));

var app = builder.Build();

// Auto-apply database migrations (development only)
// NOTE: Temporarily disabled - create migration manually first via Visual Studio
// if (app.Environment.IsDevelopment())
// {
//     using var scope = app.Services.CreateScope();
//     var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
//     await dbContext.Database.MigrateAsync();
// }

// Global Exception Handler - MUST be first middleware
app.UseMiddleware<GlobalExceptionHandlerMiddleware>();

// Tenant resolution middleware - HAR DOIM authenticationdan keyin
app.UseMiddleware<TenantResolutionMiddleware>();

// Request logging middleware
app.UseMiddleware<RequestLoggingMiddleware>();

// Configure the HTTP request pipeline
// Use CORS based on environment
app.UseCors(app.Environment.IsDevelopment() ? "DevelopmentCors" : "ProductionCors");

// Only use HTTPS redirection in production
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

// Enable static files
app.UseStaticFiles();

// Authentication & Authorization
app.UseAuthentication();
app.UseAuthorization();

// Swagger (Development only)
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

app.MapControllers();

// Map SignalR Hub
app.MapHub<MarketSystem.API.Hubs.SalesHub>("/hubs/sales");

// Seed data endpoint (development only)
if (app.Environment.IsDevelopment())
{
    app.MapGet("/seed", async (IConfiguration config, IServiceProvider services) =>
    {
        var scope = services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Check if data exists
        if (await context.Markets.AnyAsync() || await context.Users.AnyAsync())
        {
            return Results.Ok(new { message = "Database already seeded" });
        }

        // 1. Create first Market
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

        // 2. Create SuperAdmin (barcha marketlarni boshqaradi)
        var superAdmin = new User
        {
            Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
            FullName = "Super Administrator",
            Username = "superadmin",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("superadmin123"),
            Role = Role.SuperAdmin,
            IsActive = true,
            Language = Language.Uzbek,
            MarketId = defaultMarket.Id // SuperAdmin ham bir marketga tegishli
        };
        context.Users.Add(superAdmin);

        // 3. Create Owner for default market
        var owner = new User
        {
            Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
            FullName = "Market Owner",
            Username = "owner",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("owner123"),
            Role = Role.Owner,
            IsActive = true,
            Language = Language.Uzbek,
            MarketId = defaultMarket.Id
        };
        context.Users.Add(owner);

        // 4. Create Admin user
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

        // 5. Create Seller user
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
                new { username = "owner", password = "owner123", role = "Owner", note = "Owner of Demo Market" },
                new { username = "admin", password = "admin123", role = "Admin", note = "Administrator of Demo Market" },
                new { username = "seller", password = "seller123", role = "Seller", note = "Seller in Demo Market" }
            }
        });
    }).WithName("Seed Database").AllowAnonymous();
}
app.Run();