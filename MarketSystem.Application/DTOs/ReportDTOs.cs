using System.Text.Json.Serialization;

namespace MarketSystem.Application.DTOs;

public record PaymentBreakdownDto(
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("amount")] decimal Amount,
    [property: JsonPropertyName("count")] int Count
);

public record DailySaleItemDto(
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("costPrice")] decimal CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("totalCost")] decimal TotalCost,
    [property: JsonPropertyName("totalRevenue")] decimal TotalRevenue,
    [property: JsonPropertyName("profit")] decimal? Profit
);

public record DailySaleItemsResponseDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("saleItems")] List<DailySaleItemDto> SaleItems
);

public record DailyReportDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalPaidSales")] decimal TotalPaidSales,
    [property: JsonPropertyName("totalDebtSales")] decimal TotalDebtSales,
    [property: JsonPropertyName("totalZakup")] decimal TotalZakup,
    [property: JsonPropertyName("profit")] decimal? Profit,
    [property: JsonPropertyName("netIncome")] decimal? NetIncome,
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
    [property: JsonPropertyName("profit")] decimal? Profit,
    [property: JsonPropertyName("netIncome")] decimal? NetIncome,
    [property: JsonPropertyName("totalTransactions")] int TotalTransactions,
    [property: JsonPropertyName("averageSale")] decimal AverageSale,
    [property: JsonPropertyName("paymentBreakdown")] List<PaymentBreakdownDto> PaymentBreakdown
);

public record SellerReportDto(
    [property: JsonPropertyName("sellerId")] Guid SellerId,
    [property: JsonPropertyName("sellerName")] string SellerName,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalProfit")] decimal? TotalProfit,
    [property: JsonPropertyName("transactionCount")] int TransactionCount
);

public record InventoryReportDto(
    [property: JsonPropertyName("productId")] Guid ProductId,
    [property: JsonPropertyName("productName")] string ProductName,
    [property: JsonPropertyName("quantity")] decimal Quantity,
    [property: JsonPropertyName("costPrice")] decimal? CostPrice,
    [property: JsonPropertyName("salePrice")] decimal SalePrice,
    [property: JsonPropertyName("minSalePrice")] decimal MinSalePrice,
    [property: JsonPropertyName("totalCostValue")] decimal TotalCostValue,
    [property: JsonPropertyName("totalSaleValue")] decimal TotalSaleValue,
    [property: JsonPropertyName("potentialProfit")] decimal? PotentialProfit,
    [property: JsonPropertyName("category")] string? Category,
    [property: JsonPropertyName("unit")] string? Unit
);

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

public record DailySalesListItemDto(
    [property: JsonPropertyName("id")] Guid Id,
    [property: JsonPropertyName("createdAt")] DateTime CreatedAt,
    [property: JsonPropertyName("sellerName")] string SellerName,
    [property: JsonPropertyName("totalAmount")] decimal TotalAmount,
    [property: JsonPropertyName("paymentType")] string PaymentType,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("profit")] decimal? Profit,
    [property: JsonPropertyName("customerName")] string? CustomerName
);

public record DailySalesListDto(
    [property: JsonPropertyName("date")] DateTime Date,
    [property: JsonPropertyName("sales")] List<DailySalesListItemDto> Sales,
    [property: JsonPropertyName("totalSales")] decimal TotalSales,
    [property: JsonPropertyName("totalPaidSales")] decimal TotalPaidSales,
    [property: JsonPropertyName("totalDebtSales")] decimal TotalDebtSales,
    [property: JsonPropertyName("totalTransactions")] int TotalTransactions,
    [property: JsonPropertyName("summaryProfit")] decimal? SummaryProfit
);

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
