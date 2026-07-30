using MarketSystem.Application.DTOs;
using MarketSystem.Application.Services;
using MarketSystem.Domain.Enums;
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
    // Fixed Tashkent-local "generated at" so the PDF byte stream is
    // reproducible — the renderer used to call DateTime.Now which made
    // every test run print a different timestamp.
    private static readonly DateTime FixedNow = new(2026, 5, 13, 17, 0, 0);

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

    [Fact]
    public void RenderInvoicePdf_RussianLocale_IsValid()
    {
        var data = new ReportService.InvoiceData(
            MarketName: "Strotech Market",
            MarketDescription: "Qurilish mollari",
            SellerName: "Jahongir",
            CustomerName: "Без клиента",
            InvoiceNumber: Guid.NewGuid(),
            Date: new DateTime(2026, 5, 12, 22, 36, 0),
            PaymentType: "Наличные",
            Items: new List<ReportService.InvoiceItemData>
            {
                new("Taxta", 5m, 18000m, 90000m, null, false),
                new("Mix", 10m, 1000m, 10000m, "Tezkor buyurtma", true),
            },
            TotalAmount: 100000m,
            PaidAmount: 60000m,
            RemainingAmount: 40000m,
            Status: "Debt");

        AssertValidPdf(ReportService.RenderInvoicePdf(data, lang: "ru"));
    }

    // ---- Compact invoice (print-friendly: A4 sheet, content block at top) ----

    [Fact]
    public void RenderInvoiceCompactPdf_DebtSaleWithExternalItemAndComment_IsValid()
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

        AssertValidPdf(ReportService.RenderInvoiceCompactPdf(data));
    }

    [Fact]
    public void RenderInvoiceCompactPdf_PaidSaleNoItems_IsValid()
    {
        var data = new ReportService.InvoiceData(
            "Strotech Market", "", "Jahongir", "Mijoz", Guid.NewGuid(),
            DateTime.Now, "Click", new List<ReportService.InvoiceItemData>(),
            0m, 0m, 0m, "Paid");

        AssertValidPdf(ReportService.RenderInvoiceCompactPdf(data));
    }

    [Fact]
    public void RenderInvoiceCompactPdf_RussianLocale_IsValid()
    {
        var data = new ReportService.InvoiceData(
            MarketName: "Strotech Market",
            MarketDescription: "Qurilish mollari",
            SellerName: "Jahongir",
            CustomerName: "Без клиента",
            InvoiceNumber: Guid.NewGuid(),
            Date: new DateTime(2026, 5, 12, 22, 36, 0),
            PaymentType: "Наличные",
            Items: new List<ReportService.InvoiceItemData>
            {
                new("Taxta", 5m, 18000m, 90000m, null, false),
                new("Mix", 10m, 1000m, 10000m, "Tezkor buyurtma", true),
            },
            TotalAmount: 100000m,
            PaidAmount: 60000m,
            RemainingAmount: 40000m,
            Status: "Debt");

        AssertValidPdf(ReportService.RenderInvoiceCompactPdf(data, lang: "ru"));
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
            totalSales: 515500m, totalProfit: 50000m, receiptCount: 2, generatedAtLocal: FixedNow));

    [Fact]
    public void RenderSalesListPdf_SellerView_NoCostNoProfitColumns_IsValid()
        => AssertValidPdf(ReportService.RenderSalesListPdf(
            SampleRows(), null, null,
            includeProfit: false, includeCost: false,
            totalSales: 515500m, totalProfit: 0m, receiptCount: 2, generatedAtLocal: FixedNow));

    [Fact]
    public void RenderSalesListPdf_EmptyList_RendersNoDataMessage()
        => AssertValidPdf(ReportService.RenderSalesListPdf(
            new List<ReportService.SalesReportItem>(), null, null,
            includeProfit: true, includeCost: true,
            totalSales: 0m, totalProfit: 0m, receiptCount: 0, generatedAtLocal: FixedNow));

    [Fact]
    public void RenderSalesListPdf_RussianLocale_OwnerView_IsValid()
        => AssertValidPdf(ReportService.RenderSalesListPdf(
            SampleRows(), new DateTime(2026, 5, 13), new DateTime(2026, 5, 13),
            includeProfit: true, includeCost: true,
            totalSales: 515500m, totalProfit: 50000m, receiptCount: 2, generatedAtLocal: FixedNow, lang: "ru"));

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
            "KUNLIK HISOBOT", "13.05.2026", kpis, payments, FixedNow));
    }

    [Fact]
    public void RenderSummaryReportPdf_NoPayments_IsValid()
        => AssertValidPdf(ReportService.RenderSummaryReportPdf(
            "DAVRIY HISOBOT", "01.05.2026 — 31.05.2026",
            new List<(string, string, string)> { ("Jami savdo", "0 so'm", "#0F172A") },
            new List<PaymentBreakdownDto>(), FixedNow));

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

        AssertValidPdf(ReportService.RenderComprehensiveReportPdf(report, "13.05.2026", FixedNow));
    }

    // ---- Debtor report ----
    // Qarzdor hisoboti ekrandagi uchta ko'rsatkichni qog'ozga chiqaradi:
    // jami qarz, hozirgi olingan qarz, oxirgi to'lov.

    [Fact]
    public void RenderCustomerDebtPdf_LastDebtWithItems_IsValid()
    {
        var model = new ReportService.DebtorPdfModel(
            CustomerName: "Alisher Karimov",
            CustomerPhone: "+998901234567",
            TotalDebt: 1_000_000m,
            TotalOriginalDebt: 1_300_000m,
            TotalPaid: 300_000m,
            OpenDebtCount: 2,
            LastDebtAmount: 800_000m,
            LastDebtRemaining: 800_000m,
            LastDebtDate: new DateTime(2026, 7, 20, 9, 30, 0),
            LastPaymentAmount: 100_000m,
            LastPaymentType: "Terminal",
            LastPaymentDate: new DateTime(2026, 7, 18, 8, 0, 0),
            OldestDebtDate: new DateTime(2026, 7, 1, 10, 0, 0),
            LastDebt: new ReportService.DebtorPdfRow(
                new DateTime(2026, 7, 20, 9, 30, 0), 800_000m, 0m, 800_000m,
                new DateTime(2026, 8, 20), DebtStatus.Open,
                new List<ReportService.DebtorPdfItem>
                {
                    new("Sement M400", 10m, "qop", 65_000m, 650_000m, null),
                    // Tashqi tovar: Unit bo'sh + izoh bor — ikkisi ham chizilishi kerak.
                    new("Mix (tashqi)", 3m, "", 50_000m, 150_000m, "Tezkor buyurtma"),
                    new("Taxta 40x100, juda uzun nomli tovar misoli", 25.5m, "dona", 19_608m, 500_000m, null),
                }));

        AssertValidPdf(ReportService.RenderCustomerDebtPdf(model, FixedNow));
        AssertValidPdf(ReportService.RenderCustomerDebtPdf(model, FixedNow, "ru"));
    }

    /// <summary>Tovarsiz qarz (masalan boshlang'ich qarz) — "Tovarlar
    /// ko'rsatilmagan" tarmog'i.</summary>
    [Fact]
    public void RenderCustomerDebtPdf_LastDebtWithoutItems_IsValid()
        => AssertValidPdf(ReportService.RenderCustomerDebtPdf(
            new ReportService.DebtorPdfModel(
                "Mijoz", "998901112233",
                500_000m, 500_000m, 0m, 1,
                500_000m, 500_000m, new DateTime(2026, 7, 2, 9, 0, 0),
                0m, null, null, new DateTime(2026, 7, 2, 9, 0, 0),
                new ReportService.DebtorPdfRow(
                    new DateTime(2026, 7, 2, 9, 0, 0), 500_000m, 0m, 500_000m,
                    null, DebtStatus.Open,
                    new List<ReportService.DebtorPdfItem>())),
            FixedNow));

    /// <summary>Qarzi butunlay yo'q mijoz — LastDebt null.</summary>
    [Fact]
    public void RenderCustomerDebtPdf_NoDebtAtAll_IsValid()
        => AssertValidPdf(ReportService.RenderCustomerDebtPdf(
            new ReportService.DebtorPdfModel(
                "Ismi ko'rsatilmagan", null,
                0m, 0m, 0m, 0,
                0m, 0m, null,
                0m, null, null, null,
                LastDebt: null),
            FixedNow));
}
