using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;
using Microsoft.IdentityModel.Tokens;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using MarketSystem.Infrastructure.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Add DbContext with optimizations
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"),
        npgsqlOptions =>
        {
            npgsqlOptions.EnableRetryOnFailure(
                maxRetryCount: 3,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                null);
            npgsqlOptions.CommandTimeout(30);
        });
    options.EnableSensitiveDataLogging(builder.Environment.IsDevelopment());
});

// Add JWT Authentication
var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key not configured");
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? throw new InvalidOperationException("JWT Issuer not configured");
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? throw new InvalidOperationException("JWT Audience not configured");

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwtIssuer,
            ValidAudience = jwtAudience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            // Important: Map ClaimTypes.Role to the Role claim in JWT
            RoleClaimType = System.Security.Claims.ClaimTypes.Role,
            NameClaimType = System.Security.Claims.ClaimTypes.NameIdentifier
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

// Add Controllers with API Explorer
builder.Services.AddControllers();
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

    // Define JWT Authentication for Swagger
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Bearer",
        Description = "Enter JWT token (format: 'Bearer {token}')",
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
            new string[] { }
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

builder.Services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(MarketSystem.Application.Commands.CreateSaleCommand).Assembly));

// Add CORS - Development only configuration
builder.Services.AddCors(options =>
{
    options.AddPolicy("DevelopmentCors", policy =>
    {
        policy.WithOrigins("http://localhost:4200", "http://localhost:3000", "http://localhost:5173")
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

var app = builder.Build();

// Configure the HTTP request pipeline
// Use CORS based on environment
app.UseCors(app.Environment.IsDevelopment() ? "DevelopmentCors" : "ProductionCors");

// Only use HTTPS redirection in production
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

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
        if (await context.Users.AnyAsync())
        {
            return Results.Ok(new { message = "Database already seeded" });
        }

        // Create Owner user
        var owner = new User
        {
            Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
            FullName = "System Owner",
            Username = "owner",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("owner123"),
            Role = Role.Owner,
            IsActive = true
        };
        context.Users.Add(owner);

        // Create Admin user
        var admin = new User
        {
            Id = Guid.Parse("33333333-3333-3333-3333-333333333333"),
            FullName = "System Admin",
            Username = "admin",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"),
            Role = Role.Admin,
            IsActive = true
        };
        context.Users.Add(admin);

        // Create Seller user
        var seller = new User
        {
            Id = Guid.Parse("44444444-4444-4444-4444-444444444444"),
            FullName = "Seller User",
            Username = "seller",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("seller123"),
            Role = Role.Seller,
            IsActive = true
        };
        context.Users.Add(seller);

        await context.SaveChangesAsync();

        return Results.Ok(new { message = "Database seeded successfully",
            users = new[]
            {
                new { username = "owner", password = "owner123", role = "Owner" },
                new { username = "admin", password = "admin123", role = "Admin" },
                new { username = "seller", password = "seller123", role = "Seller" }
            }});
    }).WithName("Seed Database").AllowAnonymous(); // Allow for initial setup
}
app.Run();