using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Repositories;
using MarketSystem.Infrastructure.Services;

namespace MarketSystem.API.Extensions;

public static class ServicesExtensions
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        services.AddScoped<IUnitOfWork, UnitOfWork>();

        services.AddScoped<IJwtService, JwtService>();
        services.AddScoped<IAuthService, AuthService>();
        services.AddScoped<IUserService, UserService>();
        services.AddScoped<IProductService, ProductService>();
        services.AddScoped<IProductCategoryService, ProductCategoryService>();
        services.AddScoped<ICustomerService, CustomerService>();
        services.AddScoped<ISaleService, SaleService>();
        services.AddScoped<IZakupService, ZakupService>();
        services.AddScoped<IReportService, ReportService>();
        services.AddScoped<IAuditLogService, AuditLogService>();
        services.AddScoped<ICashRegisterService, CashRegisterService>();
        services.AddScoped<IMarketService, MarketService>();
        services.AddScoped<ICurrentMarketService, CurrentMarketService>();
        services.AddScoped<IExcelService, ExcelService>();
        services.AddScoped<IRegistrationRequestService, RegistrationRequestService>();
        services.AddScoped<IDebtService, DebtService>();

        // Singleton — the revocation map must outlive any single request.
        // DbRevokedTokenStore persists to PostgreSQL and reloads on startup,
        // so revocations survive restarts and are shared across replicas.
        services.AddSingleton<DbRevokedTokenStore>();
        services.AddSingleton<IRevokedTokenStore>(sp => sp.GetRequiredService<DbRevokedTokenStore>());
        services.AddSingleton<ITashkentClock, TashkentClock>();

        return services;
    }
}
