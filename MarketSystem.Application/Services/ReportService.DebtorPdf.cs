using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Extensions;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace MarketSystem.Application.Services;

/// <summary>
/// Bitta qarzdor bo'yicha PDF hisobot. Bu ReportService'ning partial bo'lagi —
/// shu sababli <c>PdfTheme</c>, <c>BrandMark</c> va jadval yacheykalari kabi
/// mavjud chizma yordamchilari qayta yozilmaydi.
///
/// Hisobot ATAYLAB qisqa: uchta asosiy raqam + oxirgi olingan qarzning
/// tovarlari. Qarzlar va to'lovlarning to'liq ro'yxati chiqarilmaydi —
/// qarzdorlik suhbatida kerak bo'lgani "qancha qarzi bor, oxirgi marta nima
/// olgan, oxirgi marta qachon to'lagan", qolgani esa hisobotni bir necha
/// varaqlik fakturaga aylantirib yuboradi.
///
/// Ma'lumot manbasi <c>CustomerDebtSummaryBuilder</c> — ekran ham xuddi shu
/// yerdan oziqlanadi, shuning uchun PDF'dagi raqamlar ilovadagi bilan bir xil.
/// </summary>
public partial class ReportService
{
    // Chizishga tayyor model: BARCHA sanalar allaqachon Toshkent vaqtiga
    // o'girilgan. Shu tufayli renderer sof (clock'ga bog'liq emas) va
    // PdfExportTests'dagi boshqa rendererlar kabi alohida sinaladi.

    /// <summary>Qarzdor olgan bitta tovar.</summary>
    internal sealed record DebtorPdfItem(
        string Name,
        decimal Quantity,
        string Unit,
        decimal SalePrice,
        decimal Total,
        string? Comment);

    /// <summary>Batafsil chiziladigan yagona qarz — oxirgi olingani.</summary>
    internal sealed record DebtorPdfRow(
        DateTime Date,
        decimal Total,
        decimal Paid,
        decimal Remaining,
        DateTime? DueDate,
        DebtStatus Status,
        List<DebtorPdfItem> Items);

    internal sealed record DebtorPdfModel(
        string CustomerName,
        string? CustomerPhone,
        decimal TotalDebt,
        decimal TotalOriginalDebt,
        decimal TotalPaid,
        int OpenDebtCount,
        decimal LastDebtAmount,
        decimal LastDebtRemaining,
        DateTime? LastDebtDate,
        decimal LastPaymentAmount,
        string? LastPaymentType,
        DateTime? LastPaymentDate,
        DateTime? OldestDebtDate,
        // Qarzi bo'lmasa null — bunda tovarlar bloki umuman chizilmaydi.
        DebtorPdfRow? LastDebt);

    public async Task<byte[]> ExportCustomerDebtPdfAsync(
        Guid customerId,
        string lang = "uz",
        CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var snapshot = await CustomerDebtSummaryBuilder.LoadAsync(
            _context, customerId, marketId, cancellationToken);

        if (snapshot is null)
            throw new KeyNotFoundException($"Customer with ID {customerId} not found.");

        var summary = CustomerDebtSummaryBuilder.Build(snapshot);

        // KPI qaysi qarzni "oxirgi olingan" deb tanlagan bo'lsa, tovarlar ham
        // AYNAN shu qarzdan chiqadi — yagona manba PickLastDebt.
        var lastDebt = CustomerDebtSummaryBuilder.PickLastDebt(snapshot);

        DateTime? ToLocal(DateTime? utc) => utc.HasValue ? _clock.ToLocal(utc.Value) : null;
        string Unknown() => lang.Equals("ru", StringComparison.OrdinalIgnoreCase)
            ? "Неизвестный товар" : "Noma'lum mahsulot";

        DebtorPdfRow? lastRow = null;
        if (lastDebt is not null)
        {
            lastRow = new DebtorPdfRow(
                _clock.ToLocal(lastDebt.Sale?.CreatedAt ?? lastDebt.CreatedAt),
                lastDebt.TotalDebt,
                lastDebt.TotalDebt - lastDebt.RemainingDebt,
                lastDebt.RemainingDebt,
                ToLocal(lastDebt.DueDate),
                lastDebt.Status,
                (lastDebt.Sale?.SaleItems ?? new List<SaleItem>())
                    .Select(si => new DebtorPdfItem(
                        // Tashqi (external) tovarda Product qatori yo'q —
                        // sotuv paytida saqlangan nomga tushamiz.
                        si.IsExternal
                            ? (si.ExternalProductName ?? Unknown())
                            : (si.Product?.Name ?? Unknown()),
                        si.Quantity,
                        si.IsExternal ? "" : (si.Product?.GetUnitName() ?? "dona"),
                        si.SalePrice,
                        si.SalePrice * si.Quantity,
                        si.Comment))
                    .ToList());
        }

        var model = new DebtorPdfModel(
            string.IsNullOrWhiteSpace(summary.CustomerName)
                ? (lang.Equals("ru", StringComparison.OrdinalIgnoreCase) ? "Без имени" : "Ismi ko'rsatilmagan")
                : summary.CustomerName,
            summary.CustomerPhone,
            summary.TotalDebt,
            summary.TotalOriginalDebt,
            summary.TotalPaid,
            summary.OpenDebtCount,
            summary.LastDebtAmount,
            summary.LastDebtRemaining,
            ToLocal(summary.LastDebtDate),
            summary.LastPaymentAmount,
            summary.LastPaymentType,
            ToLocal(summary.LastPaymentDate),
            ToLocal(summary.OldestDebtDate),
            lastRow);

        try
        {
            return RenderCustomerDebtPdf(model, _clock.NowLocal, lang);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Debtor PDF generation failed: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Qarzdor hisobotini A4 portret PDF sifatida chizadi. Sof funksiya —
    /// tashqi holatga bog'liq emas, shuning uchun to'g'ridan-to'g'ri sinaladi.
    /// </summary>
    internal static byte[] RenderCustomerDebtPdf(
        DebtorPdfModel model,
        DateTime generatedAtLocal,
        string lang = "uz")
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;
        string Som(decimal v) => $"{v:N0}{L(" so'm", " сум")}";
        const string Dash = "—";

        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(0);
                page.DefaultTextStyle(x => x.FontSize(9).FontColor(PdfTheme.Ink));

                page.Header().PaddingHorizontal(28).PaddingTop(22).PaddingBottom(14)
                    .BorderBottom(2).BorderColor(PdfTheme.Ink).Row(row =>
                {
                    row.AutoItem().Element(c => BrandMark(c, "S"));
                    row.RelativeItem().PaddingLeft(13).Column(col =>
                    {
                        col.Item().Text(L("Qarzdor bo'yicha hisobot", "Отчёт по должнику"))
                            .FontSize(18).Bold().FontColor(PdfTheme.Ink);
                        col.Item().PaddingTop(2).Text(t =>
                        {
                            t.Span(model.CustomerName).FontSize(11).SemiBold().FontColor(PdfTheme.Ink);
                            if (!string.IsNullOrWhiteSpace(model.CustomerPhone))
                                t.Span($"  ·  {model.CustomerPhone}").FontSize(10).FontColor(PdfTheme.Muted);
                        });
                    });
                    row.ConstantItem(150).AlignRight().AlignBottom()
                        .Text($"{L("Yaratilgan: ", "Создан: ")}{generatedAtLocal:dd.MM.yyyy HH:mm}")
                        .FontSize(9).FontColor(PdfTheme.Muted);
                });

                page.Content().PaddingHorizontal(28).PaddingTop(16).Column(column =>
                {
                    // ── Uchta asosiy raqam ──
                    column.Item().PaddingBottom(6).Row(row =>
                    {
                        DebtorKpi(row,
                            L("Jami qarzi", "Общий долг"),
                            $"{model.TotalDebt:N0}", L("so'm", "сум"),
                            model.OpenDebtCount > 0
                                ? L($"{model.OpenDebtCount} ta ochiq qarz",
                                    $"{model.OpenDebtCount} {RuDebtPlural(model.OpenDebtCount)}")
                                : L("Ochiq qarz yo'q", "Открытых долгов нет"),
                            model.TotalDebt > 0 ? PdfTheme.Danger : PdfTheme.Success,
                            first: true);

                        DebtorKpi(row,
                            L("Oxirgi olingan qarz", "Последний взятый долг"),
                            $"{model.LastDebtAmount:N0}", L("so'm", "сум"),
                            model.LastDebtDate.HasValue
                                ? $"{model.LastDebtDate.Value:dd.MM.yyyy}  ·  {L("qoldiq", "остаток")} {model.LastDebtRemaining:N0}"
                                : Dash,
                            PdfTheme.Ink,
                            first: false);

                        DebtorKpi(row,
                            L("Oxirgi to'lov", "Последний платёж"),
                            $"{model.LastPaymentAmount:N0}", L("so'm", "сум"),
                            model.LastPaymentDate.HasValue
                                ? $"{model.LastPaymentDate.Value:dd.MM.yyyy HH:mm}  ·  {PaymentLabel(model.LastPaymentType ?? "", isRu)}"
                                : L("To'lov qilinmagan", "Платежей не было"),
                            model.LastPaymentAmount > 0 ? PdfTheme.Success : PdfTheme.Muted,
                            first: false);
                    });

                    column.Item().PaddingTop(10).PaddingBottom(16).BorderTop(1).BorderColor(PdfTheme.Line)
                        .PaddingTop(8).Row(row =>
                    {
                        MiniFact(row, L("Olingan jami summa", "Взято всего"), Som(model.TotalOriginalDebt), first: true);
                        MiniFact(row, L("To'langan", "Оплачено"), Som(model.TotalPaid), first: false);
                        MiniFact(row, L("Birinchi qarz sanasi", "Дата первого долга"),
                            model.OldestDebtDate.HasValue ? $"{model.OldestDebtDate.Value:dd.MM.yyyy}" : Dash, first: false);
                    });

                    // ── Oxirgi olingan qarz: TOVARLAR bilan ──
                    // Hisobotdagi yagona batafsil blok.
                    if (model.LastDebt is not { } lastRow)
                    {
                        column.Item()
                            .Text(L("Qarz yozuvi topilmadi", "Записей о долге нет"))
                            .FontSize(10).FontColor(PdfTheme.Muted);
                        return;
                    }

                    var (statusLabel, statusColor) = DebtStatusInfo(lastRow.Status, isRu);

                    column.Item().PaddingBottom(8)
                        .Text(L("Oxirgi olingan qarz", "Последний взятый долг"))
                        .FontSize(12).Bold().FontColor(PdfTheme.Ink);

                    column.Item().Border(1).BorderColor(PdfTheme.Line).Column(card =>
                    {
                        card.Item().Background(PdfTheme.Zebra)
                            .PaddingVertical(6).PaddingHorizontal(9).Row(head =>
                        {
                            head.RelativeItem().AlignMiddle().Text(t =>
                            {
                                t.Span($"{lastRow.Date:dd.MM.yyyy HH:mm}")
                                    .FontSize(9.5f).SemiBold().FontColor(PdfTheme.Ink);
                                if (lastRow.DueDate.HasValue)
                                    t.Span($"   {L("Muddat", "Срок")}: {lastRow.DueDate.Value:dd.MM.yyyy}")
                                        .FontSize(8.5f).FontColor(PdfTheme.Muted);
                            });
                            head.AutoItem().AlignMiddle()
                                .Text(statusLabel).FontSize(9).Bold().FontColor(statusColor);
                        });

                        card.Item().PaddingHorizontal(9).PaddingTop(7).Row(sums =>
                        {
                            MiniFact(sums, L("Olingan", "Взято"), Som(lastRow.Total), first: true);
                            MiniFact(sums, L("To'langan", "Оплачено"), Som(lastRow.Paid), first: false);
                            MiniFact(sums, L("Qoldiq", "Остаток"), Som(lastRow.Remaining), first: false);
                        });

                        if (lastRow.Items.Count == 0)
                        {
                            card.Item().PaddingHorizontal(9).PaddingVertical(7)
                                .Text(L("Tovarlar ko'rsatilmagan", "Товары не указаны"))
                                .FontSize(8.5f).FontColor(PdfTheme.Muted);
                            return;
                        }

                        card.Item().PaddingHorizontal(9).PaddingTop(8).PaddingBottom(4).Table(items =>
                        {
                            items.ColumnsDefinition(columns =>
                            {
                                columns.RelativeColumn();
                                columns.ConstantColumn(74);
                                columns.ConstantColumn(78);
                                columns.ConstantColumn(88);
                            });

                            items.Header(header =>
                            {
                                header.Cell().Element(SalesListHeadCell).Text(L("OLINGAN TOVAR", "ВЗЯТЫЙ ТОВАР"));
                                header.Cell().Element(SalesListHeadCell).AlignRight().Text(L("MIQDOR", "КОЛ-ВО"));
                                header.Cell().Element(SalesListHeadCell).AlignRight().Text(L("NARX", "ЦЕНА"));
                                header.Cell().Element(SalesListHeadCell).AlignRight().Text(L("JAMI", "СУММА"));
                            });

                            foreach (var it in lastRow.Items)
                            {
                                items.Cell().Element(SalesListBodyCell).Column(nameCol =>
                                {
                                    nameCol.Item().Text(it.Name).FontSize(8.5f);
                                    if (!string.IsNullOrWhiteSpace(it.Comment))
                                        nameCol.Item().Text(it.Comment)
                                            .FontSize(7.5f).Italic().FontColor(PdfTheme.Muted);
                                });
                                items.Cell().Element(SalesListBodyCell).AlignRight()
                                    .Text($"{it.Quantity:0.###} {it.Unit}".TrimEnd()).FontSize(8.5f);
                                items.Cell().Element(SalesListBodyCell).AlignRight()
                                    .Text($"{it.SalePrice:N0}").FontSize(8.5f).FontColor(PdfTheme.Muted);
                                items.Cell().Element(SalesListBodyCell).AlignRight()
                                    .Text($"{it.Total:N0}").FontSize(8.5f).SemiBold();
                            }
                        });
                    });
                });

                page.Footer().Element(f => DebtorFooterBand(f, model.TotalDebt, isRu));
            });
        }).GeneratePdf();
    }

    // ── Qarzdor hisoboti uchun chizma yordamchilari ──

    // SummaryKpi ustiga izoh (sana / to'lov turi) qo'shilgan variant: qarzdorlik
    // raqamlari sanasiz ma'nosini yo'qotadi — "oxirgi to'lov 500 000" o'zi
    // yetarli emas, qachon to'langani ham kerak.
    private static void DebtorKpi(QuestPDF.Fluent.RowDescriptor row,
        string label, string value, string suffix, string caption, string accent, bool first)
    {
        row.RelativeItem().Element(e =>
        {
            var box = first
                ? e.PaddingRight(16)
                : e.BorderLeft(1).BorderColor(PdfTheme.Line).PaddingLeft(16).PaddingRight(16);
            box.Column(col =>
            {
                col.Item().Text(label.ToUpperInvariant())
                    .FontSize(7.5f).Bold().FontColor(PdfTheme.Muted).LetterSpacing(0.05f);
                col.Item().PaddingTop(5).Text(t =>
                {
                    t.Span(value).FontSize(16).Bold().FontColor(accent);
                    if (!string.IsNullOrEmpty(suffix))
                        t.Span($" {suffix}").FontSize(9).FontColor(PdfTheme.Faint);
                });
                col.Item().PaddingTop(3).Text(caption).FontSize(7.5f).FontColor(PdfTheme.Muted);
            });
        });
    }

    private static void MiniFact(QuestPDF.Fluent.RowDescriptor row, string label, string value, bool first)
    {
        row.RelativeItem().Element(e =>
        {
            var box = first ? e.PaddingRight(16) : e.PaddingLeft(16).PaddingRight(16);
            box.Row(inner =>
            {
                // PaddingRight, chunki QuestPDF Text ichidagi oxirgi bo'shliqni
                // qirqib tashlaydi — "$"{label}: " yozilsa ham qog'ozda
                // "Olingan jami summa:1 300 000" bo'lib chiqadi.
                inner.AutoItem().PaddingRight(4)
                    .Text($"{label}:").FontSize(8.5f).FontColor(PdfTheme.Muted);
                inner.AutoItem().Text(value).FontSize(8.5f).SemiBold().FontColor(PdfTheme.Ink);
            });
        });
    }

    private static void DebtorFooterBand(IContainer footer, decimal totalDebt, bool isRu)
    {
        footer.BorderTop(1).BorderColor(PdfTheme.Line)
            .PaddingHorizontal(28).PaddingVertical(9).Row(row =>
        {
            row.RelativeItem().AlignMiddle().Text(t =>
            {
                if (isRu)
                {
                    t.Span("Создано в ").FontSize(8).FontColor(PdfTheme.Muted);
                    t.Span("Strotech").FontSize(8).Bold().FontColor(PdfTheme.BrandDark);
                    t.Span("  ·  strotech.uz").FontSize(8).FontColor(PdfTheme.Muted);
                }
                else
                {
                    t.Span("Strotech").FontSize(8).Bold().FontColor(PdfTheme.BrandDark);
                    t.Span(" tomonidan yaratildi  ·  strotech.uz").FontSize(8).FontColor(PdfTheme.Muted);
                }
            });
            row.RelativeItem().AlignRight().AlignMiddle().Text(t =>
            {
                t.Span(isRu ? "Общий долг:  " : "Jami qarz:  ")
                    .FontSize(9).SemiBold().FontColor(PdfTheme.Muted);
                t.Span($"{totalDebt:N0}{(isRu ? " сум" : " so'm")}")
                    .FontSize(10).Bold().FontColor(totalDebt > 0 ? PdfTheme.Danger : PdfTheme.Success);
                t.Span("      ").FontSize(9);
                t.Span(isRu ? "Стр. " : "Sahifa ").FontSize(8).FontColor(PdfTheme.Muted);
                t.CurrentPageNumber().FontSize(8).FontColor(PdfTheme.Muted);
                t.Span(" / ").FontSize(8).FontColor(PdfTheme.Muted);
                t.TotalPages().FontSize(8).FontColor(PdfTheme.Muted);
            });
        });
    }

    /// <summary>
    /// Rus tilidagi "ochiq qarz" ko'pligi: 1 → открытый долг, 2-4 → открытых
    /// долга, 5+ → открытых долгов (11-14 istisno).
    /// </summary>
    private static string RuDebtPlural(int count)
    {
        int mod100 = count % 100;
        int mod10 = count % 10;

        if (mod100 is >= 11 and <= 14) return "открытых долгов";
        return mod10 switch
        {
            1 => "открытый долг",
            2 or 3 or 4 => "открытых долга",
            _ => "открытых долгов",
        };
    }

    private static (string Label, string Color) DebtStatusInfo(DebtStatus status, bool isRu) => status switch
    {
        DebtStatus.Open => (isRu ? "Открыт" : "Ochiq", PdfTheme.Danger),
        DebtStatus.Closed => (isRu ? "Закрыт" : "Yopilgan", PdfTheme.Success),
        DebtStatus.Returned => (isRu ? "Возврат" : "Qaytarilgan", PdfTheme.InfoBlue),
        _ => (status.ToString(), PdfTheme.Muted),
    };
}
