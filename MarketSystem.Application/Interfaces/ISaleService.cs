using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Interfaces;

public interface ISaleService
{
    Task<SaleDto?> GetSaleByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<SaleDto>> GetAllSalesAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<SaleDto>> GetSalesByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default);
    Task<IEnumerable<SaleDto>> GetDraftSalesBySellerAsync(Guid sellerId, CancellationToken cancellationToken = default);
    Task<IEnumerable<SaleDto>> GetUnfinishedSalesBySellerAsync(Guid sellerId, CancellationToken cancellationToken = default);
    Task<SaleDto> CreateSaleAsync(CreateSaleDto request, Guid sellerId, CancellationToken cancellationToken = default);
    Task<SaleDto?> UpdateSaleCustomerAsync(Guid saleId, UpdateSaleCustomerDto request, CancellationToken cancellationToken = default);
    Task<SaleItemDto?> AddSaleItemAsync(Guid saleId, AddSaleItemDto request, CancellationToken cancellationToken = default);
    Task<SaleItemDto?> RemoveSaleItemAsync(Guid saleId, RemoveSaleItemDto request, CancellationToken cancellationToken = default);
    Task<PaymentDto?> AddPaymentAsync(Guid saleId, AddPaymentDto request, CancellationToken cancellationToken = default);
    Task<SaleDto?> DeleteSaleAsync(Guid saleId, CancellationToken cancellationToken = default);
    Task<SaleDto?> CancelSaleAsync(Guid saleId, string adminId, CancellationToken cancellationToken = default);
    Task<bool> ValidateSalePriceAsync(Guid saleItemId, CancellationToken cancellationToken = default);

    // Qarzdorlar uchun
    Task<IEnumerable<DebtorDto>> GetDebtorsAsync(CancellationToken cancellationToken = default);
    Task<SaleItemDto?> UpdateSaleItemPriceAsync(UpdateSaleItemPriceDto request, Guid userId, string userRole, CancellationToken cancellationToken = default);
    Task<SaleDto?> MarkSaleAsDebtAsync(Guid saleId, CancellationToken cancellationToken = default);

    // Tovar vozvrat uchun
    Task<SaleItemDto?> ReturnSaleItemAsync(Guid saleId, ReturnSaleItemRequest request, CancellationToken cancellationToken = default);
}
