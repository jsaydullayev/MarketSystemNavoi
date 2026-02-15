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
    [property: JsonPropertyName("isActive")] bool IsActive
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

// Product DTOs
public record ProductDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("minThreshold")] int MinThreshold
);
public record CreateProductDto(
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("isTemporary")] bool IsTemporary,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("minThreshold")] int MinThreshold
);
public record UpdateProductDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("name")] string Name,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("minThreshold")] int MinThreshold
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
    [property: JsonPropertyName("comment")] string? Comment
);
public record UpdateCustomerDto(
    [property: JsonPropertyName("phone")] string Phone,
    [property: JsonPropertyName("fullName")] string? FullName
);

// Sale DTOs
public record SaleItemDto(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("saleId")] string SaleId,
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("totalPrice")] decimal TotalPrice,
    [property: JsonPropertyName("comment")] string? Comment
);
public record PaymentDto(
    [property: JsonPropertyName("paymentId")] Guid PaymentId,
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
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
public record AddSaleItemDto(
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("comment")] string? Comment
);
public record AddPaymentDto(
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("amount")] decimal Amount
);
public record CancelSaleDto(
    [property: JsonPropertyName("adminId")] string AdminId
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
public record CreateZakupDto(
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("quantity")] int Quantity,
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
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("totalCost")] decimal TotalCost,
    [property: JsonPropertyName("totalRevenue")] decimal TotalRevenue,
    [property: JsonPropertyName("profit")] decimal Profit
);

public record DailySaleItemsResponseDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("saleItems")] List<DailySaleItemDto> SaleItems
);

public record DailyReportDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalZakup")] decimal TotalZakup,
    [property: JsonPropertyName("profit")] decimal Profit,
    [property: JsonPropertyName("netIncome")] decimal NetIncome,
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
    [property: JsonPropertyName("totalZakup")] decimal TotalZakup,
    [property: JsonPropertyName("profit")] decimal Profit,
    [property: JsonPropertyName("netIncome")] decimal NetIncome,
    [property: JsonPropertyName("totalTransactions")] int TotalTransactions,
    [property: JsonPropertyName("averageSale")] decimal AverageSale,
    [property: JsonPropertyName("paymentBreakdown")] List<PaymentBreakdownDto> PaymentBreakdown
);

// Seller Report
public record SellerReportDto(
    [property: JsonPropertyName("sellerId")] Guid SellerId,
    [property: JsonPropertyName("sellerName")] string SellerName,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalProfit")] decimal TotalProfit,
    [property: JsonPropertyName("transactionCount")] int TransactionCount
);

// Inventory Report
public record InventoryReportDto(
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("totalCostValue")] decimal TotalCostValue,
    [property: JsonPropertyName("totalSaleValue")] decimal TotalSaleValue,
    [property: JsonPropertyName("potentialProfit")] decimal PotentialProfit
);

// Comprehensive Report
public record ComprehensiveReportDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("dailyReport")] DailyReportDto DailyReport,
    [property: JsonPropertyName("sellerReports")] List<SellerReportDto> SellerReports,
    [property: JsonPropertyName("inventoryReport")] List<InventoryReportDto> InventoryReport,
    [property: JsonPropertyName("totalInventoryCost")] decimal TotalInventoryCost,
    [property: JsonPropertyName("totalInventorySaleValue")] decimal TotalInventorySaleValue
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
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt
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
