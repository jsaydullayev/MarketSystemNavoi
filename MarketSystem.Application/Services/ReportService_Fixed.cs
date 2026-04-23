using OfficeOpenXml;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Application.Interfaces;
using System.Linq.Expressions;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class ReportService : IReportService
{
	private readonly IUnitOfWork _unitOfWork;
	private readonly ICurrentMarketService _currentMarketService;
	private readonly ILogger<ReportService> _logger;

	public ReportService(IUnitOfWork unitOfWork, ICurrentMarketService currentMarketService, ILogger<ReportService> logger)
	{
		_unitOfWork = unitOfWork;
		_currentMarketService = currentMarketService;
		_logger = logger;
		ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
		QuestPDF.Settings.License = LicenseType.Community;
	}

public class ReportService_Fixed : IReportService
{
	private readonly IUnitOfWork _unitOfWork;
	private readonly ICurrentMarketService _currentMarketService;
	private readonly ILogger<ReportService> _logger;

	public ReportService_Fixed(IUnitOfWork unitOfWork, ICurrentMarketService currentMarketService, ILogger<ReportService> logger)
	{
		_unitOfWork = unitOfWork;
		_currentMarketService = currentMarketService;
		_logger = logger;
		ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
		QuestPDF.Settings.License = LicenseType.Community;
	}

// Helper method for safe string access
public static class StringHelper
{
	public static string? SafeToString(string? value, string defaultValue = "Unknown")
	{
		return string.IsNullOrEmpty(value?.Trim()) ? defaultValue : value.Trim();
	}

// Helper class for PDF generation with better error handling
public static class PdfHelper
{
	public static async Task<byte[]> GenerateInvoicePdfAsync(
		ILogger logger,
		IUnitOfWork unitOfWork,
		Guid saleId,
		string? userRole,
		CancellationToken cancellationToken = default)
	{
		try
		{
			logger.LogInformation($"[GenerateInvoicePdf] Starting PDF generation for sale {saleId}");

			// Fetch sale data
			var sales = await unitOfWork.Sales.FindAsync(
				s => s.Id == saleId && s.MarketId != null,
				cancellationToken,
				includeProperties: "SaleItems,Payments,Seller,Customer,Market");

			var sale = sales.FirstOrDefault();
			if (sale == null)
			{
				logger.LogError($"[GenerateInvoicePdf] Sale with ID {saleId} not found");
				throw new KeyNotFoundException($"Sale with ID {saleId} not found.");
			}

			if (sale.Market == null)
			{
				logger.LogError($"[GenerateInvoicePdf] Market data is missing for sale {saleId}");
				throw new InvalidOperationException($"Market data is missing for sale {saleId}.");
			}

			var market = sale.Market;
			var seller = sale.Seller;
			var customer = sale.Customer;

			// Get seller name safely
			string sellerName = StringHelper.SafeToString(seller?.FullName, "Noma'lum sotuvchi");

			// Get customer name safely
			string customerName = "Mijoz ko'rsatilmagan";
			if (customer != null)
			{
				customerName = StringHelper.SafeToString(customer.FullName, customerName);
			}
			else if (sale.CustomerId.HasValue)
			{
				// Try to get customer name from database even if deleted
				var deletedCustomer = await unitOfWork.Customers.GetByIdIncludingDeletedAsync(sale.CustomerId.Value, cancellationToken);
				if (deletedCustomer != null)
				{
					customerName = StringHelper.SafeToString(deletedCustomer.FullName, "Mijoz ko'rsatilmagan");
				}
			}

			// Get all products for sale items
			var productIds = sale.SaleItems.Select(si => si.ProductId).Distinct().ToList();
			Dictionary<Guid, string> products = new Dictionary<Guid, string>();

			if (productIds.Any())
			{
				var productList = await unitOfWork.Products.FindAsync(
					p => productIds.Contains(p.Id) && p.MarketId == marketId,
					cancellationToken);
				foreach (var p in productList)
				{
					products[p.Id] = StringHelper.SafeToString(p.Name, "Noma'lum mahsulot");
				}
			}

			// Determine payment type
			var primaryPayment = sale.Payments.FirstOrDefault(p => p.Amount > 0);
			string paymentType = primaryPayment?.PaymentType.ToString() ?? "Cash";
			string paymentTypeUz = paymentType switch
			{
				"Cash" => "Naqd",
				"Terminal" => "Terminal",
				"BankTransfer" => "Bank o'tkazmasi",
				"Credit" => "Kredit",
				_ => paymentType
			};

			// Create invoice data
			var invoiceItems = new List<InvoiceItemData>();
			foreach (var item in sale.SaleItems)
			{
				var product = products.GetValueOrDefault(item.ProductId);
				string productName = StringHelper.SafeToString(product?.Name, "Noma'lum mahsulot");

				decimal total = item.SalePrice * item.Quantity;
				decimal cost = item.CostPrice * item.Quantity;

				invoiceItems.Add(new InvoiceItemData(
					productName,
					item.Quantity,
					item.SalePrice,
					total,
					item.Comment
				));
			}

			var invoiceData = new InvoiceData(
				StringHelper.SafeToString(market.Name, ""),
				market.Description ?? "",
				sellerName,
				customerName,
				sale.Id,
				sale.CreatedAt,
				paymentTypeUz,
				invoiceItems,
				sale.TotalAmount,
				sale.PaidAmount,
				sale.TotalAmount - sale.PaidAmount
			);

			logger.LogInformation($"[GenerateInvoicePdf] Invoice data prepared - Items: {invoiceItems.Count}");

			// Generate PDF using QuestPDF
			var pdfBytes = GeneratePdfDocument(invoiceData, logger);

			logger.LogInformation($"[GenerateInvoicePdf] PDF generated successfully - Size: {pdfBytes.Length} bytes");

			return pdfBytes;
		}
		catch (QuestPDFException qpex)
		{
			logger.LogError(qpex, $"[GenerateInvoicePdf] QuestPDF error for sale {saleId}: {qpex.Message}");
			throw new InvalidOperationException($"PDF generation failed due to QuestPDF library error: {qpex.Message}", qpex);
		}
		catch (Exception ex)
		{
			logger.LogError(ex, $"[GenerateInvoicePdf] Unexpected error for sale {saleId}: {ex.Message}");
			throw new InvalidOperationException($"PDF generation failed for sale {saleId}: {ex.Message}", ex);
		}
	}

// Simplified PDF generation method
private static byte[] GeneratePdfDocument(InvoiceData invoiceData, ILogger logger)
{
	try
	{
		logger.LogInformation("[GeneratePdfDocument] Starting PDF document creation");

		byte[] pdfBytes;

		using (var document = Document.Create(container =>
		{
			container.Page(page =>
			{
				page.Size(PageSizes.A4);
				page.Margin(2, Unit.Centimetre);
				page.DefaultTextStyle(x => x.FontSize(10));

				// Simple header
				page.Header().Element(header =>
				{
					header.Column(column =>
					{
						column.Item().Row(row =>
						{
							row.RelativeItem().Text("FAKTURA").FontSize(16).Bold();
							row.ConstantItem(100).AlignRight().Text("№:").FontSize(12).Bold();
							row.RelativeItem().Text("DATA:").FontSize(10);
						});
					});
				});

				// Content with invoice details
				page.Content().Element(content =>
				{
					content.Column(column =>
					{
						// Invoice info
						column.Spacing(10);
						column.Item().Text($"Sana: {invoiceData.MarketName}").FontSize(14).Bold();
						column.Item().Text($"{invoiceData.Date:dd.MM.yyyy}").FontSize(12);
						column.Item().Text($"Sotuvchi: {invoiceData.SellerName}").FontSize(12);
						column.Item().Text($"Mijoz: {invoiceData.CustomerName}").FontSize(12);

						// Items table
						column.Spacing(10);
						column.Item().Element(e =>
						{
							e.Table(table =>
							{
								table.ColumnsDefinition(columns =>
								{
									columns.ConstantColumn(10);  // #
									columns.RelativeColumn(3); // Product
									columns.ConstantColumn(40); // Qty
									columns.ConstantColumn(50); // Cost
									columns.ConstantColumn(50); // Price
									columns.ConstantColumn(50); // Total
								});

								table.Header(header =>
								{
									header.Cell().Element(CellStyle).Text("#");
									header.Cell().Element(CellStyle).Text("Mahsulot");
									header.Cell().Element(CellStyle).AlignRight().Text("Miqdor");
									header.Cell().Element(CellStyle).AlignRight().Text("Narx");
									header.Cell().Element(CellStyle).AlignRight().Text("Jami");
								});

								int index = 1;
								foreach (var item in invoiceData.Items)
								{
									table.Cell().Element(CellStyle).Text($"{index++}");
									table.Cell().Element(CellStyle).Text(item.ProductName);
									table.Cell().Element(CellStyle).AlignRight().Text($"{item.Quantity:N0}");
									table.Cell().Element(CellStyle).AlignRight().Text($"{item.Price:N2} so'm");
									table.Cell().Element(CellStyle).AlignRight().Text($"{item.Total:N2} so'm");
								}

								// Total row
								table.Cell().Element(CellStyle).Text("").FontSize(10).Bold();
								table.Cell().Element(CellStyle).Text("Jami summa:").Bold().AlignCenter();
								table.Cell().Element(CellStyle).AlignRight().Text($"{invoiceData.TotalAmount:N2} so'm").Bold();
							});
						});
					});
				});

				// Footer with totals
				page.Footer().AlignCenter().Text(x =>
				{
					x.Span("Sahifa ");
					x.CurrentPageNumber();
				});
			})
		.GeneratePdf();

		logger.LogInformation($"[GeneratePdfDocument] PDF generated successfully");

		return pdfBytes;
	}
	catch (Exception ex)
	{
		logger.LogError(ex, "[GeneratePdfDocument] PDF generation error");
		throw new InvalidOperationException($"PDF generation failed: {ex.Message}", ex);
	}
}

// Invoice data classes
public record InvoiceData(
	string MarketName,
	string MarketDescription,
	string SellerName,
	string CustomerName,
	Guid InvoiceNumber,
	DateTime Date,
	string PaymentType,
	List<InvoiceItemData> Items,
	decimal TotalAmount,
	decimal PaidAmount,
	decimal RemainingAmount
);

public record InvoiceItemData(
	string ProductName,
	int Quantity,
	decimal Price,
	decimal Total,
	string? Comment
);
