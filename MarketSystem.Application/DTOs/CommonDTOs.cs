using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

// User DTOs
public record UserDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("profileImage")] string? ProfileImage,
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("language")] string Language,
    [property: JsonPropertyName("isActive")] bool IsActive,
    [property: JsonPropertyName("marketId")] int? MarketId
);
public record CreateUserDto(
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("password")] string Password,
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("language")] string? Language = "uz"
);
public record UpdateUserDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("password")] string? Password,
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("isActive")] bool IsActive
);
public record UpdateProfileDto(
    [property: JsonPropertyName("fullName")] string? FullName,
    [property: JsonPropertyName("currentPassword")] string? CurrentPassword,
    [property: JsonPropertyName("newPassword")] string? NewPassword
);
public record UpdateProfileImageDto(
    [property: JsonPropertyName("profileImage")] string ProfileImage
);

// Product DTOs - OLD VERSION (deprecated, use ProductDTOs.cs instead)
// These are kept for backward compatibility with existing code
public record CreateProductDto(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("minThreshold")] decimal MinThreshold,
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("unit")] int Unit = 1  // Default: Piece
);
public record UpdateProductDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("minThreshold")] decimal MinThreshold,
    [property: JsonPropertyName("categoryId")] int? CategoryId,
    [property: JsonPropertyName("unit")] int Unit = 1,  // Default: Piece
    [property: JsonPropertyName("isTemporary")] bool IsTemporary = false
);

// Customer DTOs
public record CustomerDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("phone")] string Phone,
    [property: JsonPropertyName("fullName")] string? FullName,
    [property: JsonPropertyName("comment")] string? Comment,
    [property: JsonPropertyName("totalDebt")] decimal TotalDebt
);
public record CreateCustomerDto(
    [property: JsonPropertyName("phone")] string Phone,
    [property: JsonPropertyName("fullName")] string? FullName,
    [property: JsonPropertyName("comment")] string? Comment,
    [property: JsonPropertyName("initialDebt")] decimal? InitialDebt
);
public record UpdateCustomerDto(
    [property: JsonPropertyName("phone")] string Phone,
    [property: JsonPropertyName("fullName")] string? FullName
);

// Customer Delete Info DTO
public record CustomerDeleteInfoDto(
    [property: JsonPropertyName("canDelete")] bool CanDelete,
    [property: JsonPropertyName("salesCount")] int SalesCount,
    [property: JsonPropertyName("draftSalesCount")] int DraftSalesCount,
    [property: JsonPropertyName("debtsCount")] int DebtsCount,
    [property: JsonPropertyName("totalDebt")] decimal TotalDebt,
    [property: JsonPropertyName("warningMessage")] string? WarningMessage
);

// Sale DTOs
public record SaleItemDto(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("saleId")] string SaleId,
    [property: JsonPropertyName("productId")] Guid? ProductId,  // ✅ Nullable
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,  // ✅ DECIMAL
    [property: JsonPropertyName("costPrice")] decimal CostPrice,  // EffectiveCostPrice bo'ladi
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("totalPrice")] decimal TotalPrice,
    [property: JsonPropertyName("profit")] decimal Profit,
    [property: JsonPropertyName("unit")] string Unit,  // "dona", "kg", "m"
    [property: JsonPropertyName("comment")] string? Comment,
    [property: JsonPropertyName("isExternal")] bool IsExternal  // ✅ New flag
);
public record PaymentDto(
    [property: JsonPropertyName("paymentId")] Guid PaymentId,
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("saleStatus")] string? SaleStatus,
    [property: JsonPropertyName("salePaidAmount")] decimal? SalePaidAmount,
    [property: JsonPropertyName("saleTotalAmount")] decimal? SaleTotalAmount
);
public record SaleDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("sellerId")] Guid SellerId,
    [property: JsonPropertyName("sellerName")] string SellerName,
    [property: JsonPropertyName("customerId")] Guid? CustomerId,
    [property: JsonPropertyName("customerName")] string? CustomerName,
    [property: JsonPropertyName("customerPhone")] string? CustomerPhone,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("totalAmount")] decimal TotalAmount,
    [property: JsonPropertyName("paidAmount")] decimal PaidAmount,
    [property: JsonPropertyName("remainingAmount")] decimal RemainingAmount,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("items")] List<SaleItemDto> Items,
    [property: JsonPropertyName("payments")] List<PaymentDto> Payments
);
public record CreateSaleDto(
    [property: JsonPropertyName("customerId")] Guid? CustomerId
);
public record UpdateSaleCustomerDto(
    [property: JsonPropertyName("customerId")] Guid? CustomerId
);
public record AddSaleItemDto(
    [property: JsonPropertyName("isExternal")] bool IsExternal,  // ✅ New flag
    [property: JsonPropertyName("productId")] Guid? ProductId,  // ✅ Nullable
    [property: JsonPropertyName("externalProductName")] string? ExternalProductName,  // ✅ New
    [property: JsonPropertyName("externalCostPrice")] decimal? ExternalCostPrice,  // ✅ New
    [property: JsonPropertyName("quantity")] decimal Quantity,  // ✅ DECIMAL - 22.5 m, 15.5 kg bo'lishi mumkin
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,  // For validation, not stored in SaleItem
    [property: JsonPropertyName("comment")] string? Comment
);
public record RemoveSaleItemDto(
    [property: JsonPropertyName("saleItemId")] string SaleItemId,
    [property: JsonPropertyName("quantity")] decimal Quantity  // ✅ DECIMAL - Quantity to remove (0 = remove completely)
);
public record AddPaymentDto(
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("amount")] decimal Amount
);
public record CancelSaleDto(
    [property: JsonPropertyName("adminId")] string AdminId
);
public record UpdateSaleItemPriceDto(
    [property: JsonPropertyName("saleItemId")] string SaleItemId,
    [property: JsonPropertyName("newPrice")] decimal NewPrice,
    [property: JsonPropertyName("comment")] string? Comment  // Optional - not needed for price update
);

// Zakup DTOs
public record ZakupDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("createdBy")] string CreatedBy
);
// Zakup DTO for Sellers - excludes cost price
public record ZakupSellerDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("createdBy")] string CreatedBy
);
public record CreateZakupDto(
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice
);

// Report DTOs
public record PaymentBreakdownDto(
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("count")] int Count
);

public record DailySaleItemDto(
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,  // ✅ DECIMAL
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("totalCost")] decimal TotalCost,
    [property: JsonPropertyName("totalRevenue")] decimal TotalRevenue,
    [property: JsonPropertyName("profit")] decimal? Profit  // null for Admin/Seller
);

public record DailySaleItemsResponseDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("saleItems")] List<DailySaleItemDto> SaleItems
);

public record DailyReportDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalPaidSales")] decimal TotalPaidSales,  // To'langan savdolar
    [property: JsonPropertyName("totalDebtSales")] decimal TotalDebtSales,  // Qarzga sotilgan
    [property: JsonPropertyName("totalZakup")] decimal TotalZakup,
    [property: JsonPropertyName("profit")] decimal? Profit,  // null for Admin/Seller
    [property: JsonPropertyName("netIncome")] decimal? NetIncome,  // null for Admin/Seller
    [property: JsonPropertyName("totalTransactions")] int TotalTransactions,
    [property: JsonPropertyName("paymentBreakdown")] List<PaymentBreakdownDto> PaymentBreakdown
);
public record PeriodReportRequest(
    [property: JsonPropertyName("startDate")] DateTime StartDate,
    [property: JsonPropertyName("endDate")] DateTime EndDate
);
public record PeriodReportDto(
    [property: JsonPropertyName("startDate")] DateTime StartDate,
    [property: JsonPropertyName("endDate")] DateTime EndDate,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalPaidSales")] decimal TotalPaidSales,
    [property: JsonPropertyName("totalDebtSales")] decimal TotalDebtSales,
    [property: JsonPropertyName("totalZakup")] decimal TotalZakup,
    [property: JsonPropertyName("profit")] decimal? Profit,  // null for Admin/Seller
    [property: JsonPropertyName("netIncome")] decimal? NetIncome,  // null for Admin/Seller
    [property: JsonPropertyName("totalTransactions")] int TotalTransactions,
    [property: JsonPropertyName("averageSale")] decimal AverageSale,
    [property: JsonPropertyName("paymentBreakdown")] List<PaymentBreakdownDto> PaymentBreakdown
);

// Seller Report
public record SellerReportDto(
    [property: JsonPropertyName("sellerId")] Guid SellerId,
    [property: JsonPropertyName("sellerName")] string SellerName,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalProfit")] decimal? TotalProfit,  // null for Admin/Seller
    [property: JsonPropertyName("transactionCount")] int TransactionCount
);

// Inventory Report
public record InventoryReportDto(
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,  // ✅ DECIMAL
    [property: JsonPropertyName("costPrice")] decimal? CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("totalCostValue")] decimal TotalCostValue,
    [property: JsonPropertyName("totalSaleValue")] decimal TotalSaleValue,
    [property: JsonPropertyName("potentialProfit")] decimal? PotentialProfit,  // null for Admin/Seller
    [property: JsonPropertyName("category")] string? Category,
    [property: JsonPropertyName("unit")] string? Unit
);

// Comprehensive Report
public record ComprehensiveReportDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("dailyReport")] DailyReportDto DailyReport,
    [property: JsonPropertyName("sellerReports")] List<SellerReportDto> SellerReports,
    [property: JsonPropertyName("inventoryReport")] List<InventoryReportDto> InventoryReport,
    [property: JsonPropertyName("totalInventoryCost")] decimal TotalInventoryCost,
    [property: JsonPropertyName("totalInventorySaleValue")] decimal TotalInventorySaleValue,
    [property: JsonPropertyName("productCount")] int ProductCount,
    [property: JsonPropertyName("totalInventoryValue")] decimal TotalInventoryValue,
    [property: JsonPropertyName("lowStockCount")] int LowStockCount,
    [property: JsonPropertyName("outOfStockCount")] int OutOfStockCount
);

// Debt DTOs
public record DebtDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("saleId")] Guid SaleId,
    [property: JsonPropertyName("customerId")] Guid CustomerId,
    [property: JsonPropertyName("customerName")] string? CustomerName,
    [property: JsonPropertyName("totalDebt")] decimal TotalDebt,
    [property: JsonPropertyName("remainingDebt")] decimal RemainingDebt,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("saleItems")] List<SaleItemDto>? SaleItems
);

// Qarzdorlar uchun DTO
public record DebtorDto(
    [property: JsonPropertyName("customerId")] Guid CustomerId,
    [property: JsonPropertyName("customerName")] string? CustomerName,
    [property: JsonPropertyName("customerPhone")] string? CustomerPhone,
    [property: JsonPropertyName("totalDebt")] decimal TotalDebt,
    [property: JsonPropertyName("paidAmount")] decimal PaidAmount,
    [property: JsonPropertyName("remainingDebt")] decimal RemainingDebt,
    [property: JsonPropertyName("debtCount")] int DebtCount,
    [property: JsonPropertyName("oldestDebtDate")] DateTime? OldestDebtDate,
    [property: JsonPropertyName("sales")] List<SaleDto> Sales
);

public record PayDebtDto(
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("paymentType")] string PaymentType
);

// Pagination
public record PagedResponse<T>(
    [property: JsonPropertyName("items")] List<T> Items,
    [property: JsonPropertyName("totalCount")] int TotalCount,
    [property: JsonPropertyName("page")] int Page,
    [property: JsonPropertyName("pageSize")] int PageSize
);

// Profit and Cash Balance DTOs - Owner Only
public record ProfitSummaryDto(
    [property: JsonPropertyName("todayProfit")] decimal TodayProfit,
    [property: JsonPropertyName("weekProfit")] decimal WeekProfit,
    [property: JsonPropertyName("monthProfit")] decimal MonthProfit,
    [property: JsonPropertyName("totalProfit")] decimal TotalProfit
);

public record CashBalanceDto(
    [property: JsonPropertyName("cashInRegister")] decimal CashInRegister,
    [property: JsonPropertyName("cardPayments")] decimal CardPayments,
    [property: JsonPropertyName("totalBalance")] decimal TotalBalance
);

// Daily Sales List - Role-based visibility
public record DailySalesListItemDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("sellerName")] string SellerName,
    [property: JsonPropertyName("totalAmount")] decimal TotalAmount,
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("profit")] decimal? Profit,  // null for Admin/Seller
    [property: JsonPropertyName("customerName")] string? CustomerName
);

public record DailySalesListDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("sales")] List<DailySalesListItemDto> Sales,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalPaidSales")] decimal TotalPaidSales,    // To'langan savdolar ✅ NEW
    [property: JsonPropertyName("totalDebtSales")] decimal TotalDebtSales,    // Qarzga sotilgan ✅ NEW
    [property: JsonPropertyName("totalTransactions")] int TotalTransactions,
    [property: JsonPropertyName("summaryProfit")] decimal? SummaryProfit  // null for Admin/Seller
);

// Category Sales Report
public record CategorySalesDto(
    [property: JsonPropertyName("categoryId")] int CategoryId,
    [property: JsonPropertyName("categoryName")] string CategoryName,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalQuantity")] decimal TotalQuantity,
    [property: JsonPropertyName("totalProfit")] decimal? TotalProfit
);

public record MonthlyCategorySalesResponseDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("categories")] List<CategorySalesDto> Categories,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalProfit")] decimal? TotalProfit
);

// Sale Item for detailed export
public record SaleItemExportDto(
    [property: JsonPropertyName("productId")] string ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("totalAmount")] decimal TotalAmount,
    [property: JsonPropertyName("profit")] decimal? Profit,
    [property: JsonPropertyName("comment")] string? Comment
);

// Sale with items for detailed export
public record SaleWithItemsDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("sellerName")] string? SellerName,
    [property: JsonPropertyName("customerName")] string? CustomerName,
    [property: JsonPropertyName("totalAmount")] decimal TotalAmount,
    [property: JsonPropertyName("paidAmount")] decimal PaidAmount,
    [property: JsonPropertyName("paymentType")] string? PaymentType,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("profit")] decimal? Profit,
    [property: JsonPropertyName("items")] List<SaleItemExportDto> Items
);
