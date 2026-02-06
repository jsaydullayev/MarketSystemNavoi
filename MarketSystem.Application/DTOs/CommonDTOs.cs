using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

// User DTOs
public record UserDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("isActive")] bool IsActive
);
public record CreateUserDto(
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("username")] string Username,
    [property: JsonPropertyName("password")] string Password,
    [property: JsonPropertyName("role")] string Role
);
public record UpdateUserDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("fullName")] string FullName,
    [property: JsonPropertyName("password")] string? Password,
    [property: JsonPropertyName("role")] string Role,
    [property: JsonPropertyName("isActive")] bool IsActive
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
    [property: JsonPropertyName("totalDebt")] decimal TotalDebt
);
public record CreateCustomerDto(
    [property: JsonPropertyName("phone")] string Phone,
    [property: JsonPropertyName("fullName")] string? FullName
);
public record UpdateCustomerDto(
    [property: JsonPropertyName("phone")] string Phone,
    [property: JsonPropertyName("fullName")] string? FullName
);

// Sale DTOs
public record SaleItemDto(
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] int Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("profit")] decimal Profit,
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
public record DailyReportDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalZakup")] decimal TotalZakup,
    [property: JsonPropertyName("profit")] decimal Profit,
    [property: JsonPropertyName("netIncome")] decimal NetIncome,
    [property: JsonPropertyName("totalTransactions")] int TotalTransactions
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
    [property: JsonPropertyName("totalTransactions")] int TotalTransactions
);

// Debt DTOs
public record DebtDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("saleId")] Guid SaleId,
    [property: JsonPropertyName("customerId")] Guid CustomerId,
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
