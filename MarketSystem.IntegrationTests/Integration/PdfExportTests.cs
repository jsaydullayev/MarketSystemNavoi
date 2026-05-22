using MarketSystem.Application.DTOs;
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

    // ---- Daily / period summary report ----

    [Fact]
    public void RenderSummaryReportPdf_WithKpisAndPayments_IsValid()
    {
        var kpis = new List<(string, string, string)>
        {
            ("Jami savdo", "3 823 500 so'm", "#0F172A"),
            ("To'langan", "3 700 000 so'm", "#16A34A"),
            ("Qarz", "123 500 so'm", "#DC2626"),
            ("Cheklar soni", "7", "#0F172A"),
            ("Sof foyda", "483 000 so'm", "#16A34A"),
        };
        var payments = new List<PaymentBreakdownDto>
        {
            new("Cash", 2_000_000m, 4),
            new("Click", 1_823_500m, 3),
        };

        AssertValidPdf(ReportService.RenderSummaryReportPdf(
            "KUNLIK HISOBOT", "13.05.2026", kpis, payments));
    }

    [Fact]
    public void RenderSummaryReportPdf_NoPayments_IsValid()
        => AssertValidPdf(ReportService.RenderSummaryReportPdf(
            "DAVRIY HISOBOT", "01.05.2026 — 31.05.2026",
            new List<(string, string, string)> { ("Jami savdo", "0 so'm", "#0F172A") },
            new List<PaymentBreakdownDto>()));

    // ---- Comprehensive report ----

    [Fact]
    public void RenderComprehensiveReportPdf_WithSellers_IsValid()
    {
        var daily = new DailyReportDto(
            new DateTime(2026, 5, 13), 3_823_500m, 3_700_000m, 123_500m, 500_000m,
            483_000m, 483_000m, 7,
            new List<PaymentBreakdownDto> { new("Cash", 2_000_000m, 4) });
        var sellers = new List<SellerReportDto>
        {
            new(Guid.NewGuid(), "Jahongir", 3_823_500m, 483_000m, 7),
            new(Guid.NewGuid(), "Ixtiyor", 0m, null, 0),
        };
        var report = new ComprehensiveReportDto(
            new DateTime(2026, 5, 13), daily, sellers,
            new List<InventoryReportDto>(),
            10_000_000m, 14_000_000m, 42, 14_000_000m, 3, 1);

        AssertValidPdf(ReportService.RenderComprehensiveReportPdf(report, "13.05.2026"));
    }
}
