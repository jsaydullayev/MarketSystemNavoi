using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Application.Interfaces;

public interface ISaleService
{
    Task<SaleDto?> GetSaleByIdAsync(Guid id, CancellationToken cancellationToken = default);
    /// <summary>
    /// Returns all sales for the current market — used by Excel export only.
    /// Capped internally at 10 000 rows; for paged API consumption use <see cref="GetSalesPagedAsync"/>.
    /// </summary>
    Task<IEnumerable<SaleDto>> GetAllSalesAsync(CancellationToken cancellationToken = default);
    Task<PagedResult<SaleDto>> GetSalesPagedAsync(int page, int size, CancellationToken cancellationToken = default);
    Task<IEnumerable<SaleDto>> GetSalesByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default);
    // sellerId null bo'lsa — butun do'kondagi (barcha sellerlarning) sotuvlari
    // qaytariladi (sellerlar hamkorligi, data.allSalesView ruxsati bilan).
    Task<IEnumerable<SaleDto>> GetDraftSalesBySellerAsync(Guid? sellerId, CancellationToken cancellationToken = default);
    Task<IEnumerable<SaleDto>> GetUnfinishedSalesBySellerAsync(Guid? sellerId, CancellationToken cancellationToken = default);
    Task<SaleDto> CreateSaleAsync(CreateSaleDto request, Guid sellerId, CancellationToken cancellationToken = default);
    Task<SaleDto?> UpdateSaleCustomerAsync(Guid saleId, UpdateSaleCustomerDto request, CancellationToken cancellationToken = default);
    Task<SaleItemDto?> AddSaleItemAsync(Guid saleId, AddSaleItemDto request, CancellationToken cancellationToken = default);
    Task<SaleItemDto?> RemoveSaleItemAsync(Guid saleId, RemoveSaleItemDto request, CancellationToken cancellationToken = default);
    Task<PaymentDto?> AddPaymentAsync(Guid saleId, AddPaymentDto request, CancellationToken cancellationToken = default);
    /// <summary>
    /// Owner data-cleanup: soft-deletes a wrongly-entered sale and reverses its
    /// side effects (restores stock, backs cash out of the till, closes any open
    /// debt). <paramref name="actorId"/> MUST be the authenticated caller's id
    /// from the JWT claim — never a client-supplied value — so the audit row
    /// can't be forged to blame someone else.
    /// </summary>
    Task<SaleDto?> DeleteSaleAsync(Guid saleId, Guid actorId, CancellationToken cancellationToken = default);
    /// <summary>
    /// Cancel a paid sale. <paramref name="adminId"/> MUST be the
    /// authenticated caller's id taken from the JWT claim — NEVER trust a
    /// client-supplied value here, otherwise the resulting audit row can
    /// be forged to blame another admin.
    /// </summary>
    Task<SaleDto?> CancelSaleAsync(Guid saleId, Guid adminId, CancellationToken cancellationToken = default);
    Task<bool> ValidateSalePriceAsync(Guid saleItemId, CancellationToken cancellationToken = default);

    // Customer credit application
    /// <summary>
    /// Applies customer's available credit (from negative payments/refunds) to a sale.
    /// </summary>
    Task<SaleDto?> ApplyCustomerCreditAsync(Guid saleId, CancellationToken cancellationToken = default);

    // Additional methods for sale management
    /// <summary>
    /// Marks a sale as debt status
    /// </summary>
    // dueDate — "Qarzga olish"da tanlangan to'lov muddati (ixtiyoriy).
    Task<SaleDto?> MarkSaleAsDebtAsync(Guid saleId, DateTime? dueDate = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// Updates sale item price with role-based permissions
    /// </summary>
    Task<SaleItemDto?> UpdateSaleItemPriceAsync(Guid saleItemId, UpdateSaleItemPriceDto request, CancellationToken cancellationToken = default);

    /// <summary>
    /// Returns a sale item (partial or full return)
    /// </summary>
    Task<SaleItemDto?> ReturnSaleItemAsync(Guid saleId, ReturnSaleItemRequest request, CancellationToken cancellationToken = default);

    /// <summary>
    /// Gets list of debtors
    /// </summary>
    Task<IEnumerable<CustomerDto>> GetDebtorsAsync(CancellationToken cancellationToken = default);
}
