using MarketSystem.Application.Services;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Exercises the QuestPDF layout of the branded invoice and sales-list PDFs.
/// QuestPDF throws at GeneratePdf() time on a malformed layout (overflow,
/// multiple children in a single-child slot, …), so a clean byte[] with the
/// %PDF signature proves the Strotech-themed layout actually composes.
///
/// The renderers are pure (no DB) — see InternalsVisibleTo in
/// MarketSystem.Application.csproj.
/// </summary>
public class PdfExportTests
{
    private static void AssertValidPdf(byte[] bytes)
    {
        bytes.Should().NotBeNullOrEmpty();
        bytes.Length.Should().BeGreaterThan(1000, "a real PDF page is never this small");
        System.Text.Encoding.ASCII.GetString(bytes, 0, 5)
            .Should().Be("%PDF-", "the file must carry the PDF signature");
    }

    // ---- Invoice ----

    [Fact]
    public void RenderInvoicePdf_DebtSaleWithExternalItemAndComment_IsValid()
    {
        var data = new ReportService.InvoiceData(
            MarketName: "Strotech Market",
            MarketDescription: "Qurilish mollari",
            SellerName: "Jahongir",
            CustomerName: "Mijoz ko'rsatilmagan",
            InvoiceNumber: Guid.NewGuid(),
            Date: new DateTime(2026, 5, 12, 22, 36, 0),
            PaymentType: "Naqd",
            Items: new List<ReportService.InvoiceItemData>
            {
                new("Taxta", 5m, 18000m, 90000m, null, false),
                new("Mix", 10m, 1000m, 10000m, "Tezkor buyurtma", true),
            },
            TotalAmount: 100000m,
            PaidAmount: 60000m,
            RemainingAmount: 40000m,
            Status: "Debt");

        AssertValidPdf(ReportService.RenderInvoicePdf(data));
    }

    [Fact]
    public void RenderInvoicePdf_PaidSaleNoItems_IsValid()
    {
        var data = new ReportService.InvoiceData(
            "Strotech Market", "", "Jahongir", "Mijoz", Guid.NewGuid(),
            DateTime.Now, "Click", new List<ReportService.InvoiceItemData>(),
            0m, 0m, 0m, "Paid");

        AssertValidPdf(ReportService.RenderInvoicePdf(data));
    }

    // ---- Sales list ----

    private static List<ReportService.SalesReportItem> SampleRows() => new()
    {
        new(1, new DateTime(2026, 5, 13, 16, 30, 0), "Ixtiyor", "Jahongir",
            "Taxta", 5m, 70000m, 80000m, 400000m, 50000m, "Paid"),
        new(2, new DateTime(2026, 5, 13, 16, 29, 0), "Mijoz yo'q", "Jahongir",
            "Mix", 10.5m, 10000m, 11000m, 115500m, 0m, "Debt"),
    };

    [Fact]
    public void RenderSalesListPdf_OwnerView_WithCostAndProfit_IsValid()
        => AssertValidPdf(ReportService.RenderSalesListPdf(
            SampleRows(), new DateTime(2026, 5, 13), new DateTime(2026, 5, 13),
            includeProfit: true, includeCost: true,
            totalSales: 515500m, totalProfit: 50000m));

    [Fact]
    public void RenderSalesListPdf_SellerView_NoCostNoProfitColumns_IsValid()
        => AssertValidPdf(ReportService.RenderSalesListPdf(
            SampleRows(), null, null,
            includeProfit: false, includeCost: false,
            totalSales: 515500m, totalProfit: 0m));

    [Fact]
    public void RenderSalesListPdf_EmptyList_RendersNoDataMessage()
        => AssertValidPdf(ReportService.RenderSalesListPdf(
            new List<ReportService.SalesReportItem>(), null, null,
            includeProfit: true, includeCost: true,
            totalSales: 0m, totalProfit: 0m));
}
