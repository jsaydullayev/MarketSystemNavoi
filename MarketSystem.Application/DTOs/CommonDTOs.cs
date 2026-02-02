namespace MarketSystem.Application.DTOs;

// User DTOs
public record UserDto(Guid Id, string FullName, string Username, string Role, bool IsActive);
public record CreateUserDto(string FullName, string Username, string Password, string Role);
public record UpdateUserDto(Guid Id, string FullName, string? Password, string Role, bool IsActive);

// Product DTOs
public record ProductDto(Guid Id, string Name, bool IsTemporary, decimal CostPrice, decimal SalePrice, decimal MinSalePrice, int Quantity, int MinThreshold);
public record CreateProductDto(string Name, bool IsTemporary, decimal CostPrice, decimal SalePrice, decimal MinSalePrice, int Quantity, int MinThreshold);
public record UpdateProductDto(Guid Id, string Name, decimal CostPrice, decimal SalePrice, decimal MinSalePrice, int MinThreshold);

// Customer DTOs
public record CustomerDto(Guid Id, string Phone, string? FullName, decimal TotalDebt);
public record CreateCustomerDto(string Phone, string? FullName);
public record UpdateCustomerDto(Guid Id, string Phone, string? FullName);

// Sale DTOs
public record SaleItemDto(Guid ProductId, string ProductName, int Quantity, decimal CostPrice, decimal SalePrice, decimal Profit, string? Comment);
public record PaymentDto(Guid PaymentId, string PaymentType, decimal Amount, DateTime CreatedAt);
public record SaleDto(Guid Id, Guid SellerId, string SellerName, Guid? CustomerId, string? CustomerName, string? CustomerPhone, string Status, decimal TotalAmount, decimal PaidAmount, decimal RemainingAmount, DateTime CreatedAt, List<SaleItemDto> Items, List<PaymentDto> Payments);
public record CreateSaleDto(Guid? CustomerId);
public record AddSaleItemDto(Guid ProductId, int Quantity, decimal SalePrice, string? Comment);
public record AddPaymentDto(string PaymentType, decimal Amount);
public record CancelSaleDto(Guid AdminId);

// Zakup DTOs
public record ZakupDto(Guid Id, Guid ProductId, string ProductName, decimal Quantity, decimal CostPrice, DateTime CreatedAt, string CreatedBy);
public record CreateZakupDto(Guid ProductId, int Quantity, decimal CostPrice);

// Report DTOs
public record DailyReportDto(DateTime Date, decimal TotalSales, decimal TotalZakup, decimal Profit, decimal NetIncome, int TotalTransactions);
public record PeriodReportRequest(DateTime StartDate, DateTime EndDate);
public record PeriodReportDto(DateTime StartDate, DateTime EndDate, decimal TotalSales, decimal TotalZakup, decimal Profit, decimal NetIncome, int TotalTransactions);

// Pagination
public record PagedResponse<T>(List<T> Items, int TotalCount, int Page, int PageSize);
