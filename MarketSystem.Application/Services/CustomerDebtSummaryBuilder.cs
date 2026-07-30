using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

/// <summary>
/// Bitta qarzdorning yig'ma ko'rsatkichlarini — jami qarz, oxirgi olingan qarz,
/// oxirgi to'lov — hisoblaydigan YAGONA manba.
///
/// Nega alohida klass: bu uchlik ikki joyda kerak bo'ladi — <c>DebtService</c>
/// uni JSON sifatida qaytaradi (<c>GET /api/Debts/customer/{id}/summary</c>),
/// <c>ReportService</c> esa aynan shu raqamlarni PDF eksportga chizadi. Hisob
/// ikkiga ko'chirilsa raqamlar vaqt o'tib bir-biridan uzoqlashadi (ekranda bir
/// summa, PDF'da boshqasi) — shuning uchun yuklash ham, hisoblash ham faqat shu
/// yerda turadi.
/// </summary>
internal static class CustomerDebtSummaryBuilder
{
    /// <summary>Bitta qarzdor uchun bir marta yuklangan xom ma'lumot.</summary>
    internal sealed record Snapshot(Customer Customer, List<Debt> Debts, List<Payment> Payments);

    /// <summary>
    /// Mijoz + uning barcha qarzlari (holatidan qat'i nazar) + shu qarzlarning
    /// sotuvlariga tegishli barcha to'lovlar. Mijoz topilmasa (yoki boshqa
    /// market'ga tegishli bo'lsa) <c>null</c>.
    ///
    /// Yopilgan qarzlarni ham olamiz: "oxirgi to'lov" aynan qarzni yopgan to'lov
    /// bo'lishi mumkin, faqat ochiqlarini olsak u ko'rinmay qolardi.
    /// </summary>
    public static async Task<Snapshot?> LoadAsync(
        IAppDbContext context,
        Guid customerId,
        int marketId,
        CancellationToken cancellationToken = default)
    {
        var customer = await context.Customers
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == customerId && c.MarketId == marketId, cancellationToken);

        if (customer is null)
            return null;

        // SaleItems + Product ham kerak: PDF hisobotda qarzdor NIMA olganini
        // ko'rsatamiz, faqat summani emas. AsSplitQuery — aks holda qarz ×
        // tovar dekart ko'paytmasi qaytadi.
        var debts = await context.Debts
            .AsNoTracking()
            .Include(d => d.Sale)
                .ThenInclude(s => s!.SaleItems)
                    .ThenInclude(si => si.Product)
            .Where(d => d.CustomerId == customerId && d.MarketId == marketId)
            .AsSplitQuery()
            .ToListAsync(cancellationToken);

        var saleIds = debts.Select(d => d.SaleId).Distinct().ToList();

        // Bo'sh IN (...) so'rovini Postgres'ga yubormaymiz.
        var payments = saleIds.Count == 0
            ? new List<Payment>()
            : await context.Payments
                .AsNoTracking()
                .Where(p => saleIds.Contains(p.SaleId) && p.MarketId == marketId)
                .OrderByDescending(p => p.CreatedAt)
                .ToListAsync(cancellationToken);

        return new Snapshot(customer, debts, payments);
    }

    /// <summary>
    /// Qarz "olingan" sana — qarz qatorining <c>CreatedAt</c>'i emas, balki
    /// ota-sotuvning sanasi. <c>DebtService.MapToDto</c> ham `createdAt` uchun
    /// aynan shu manbadan foydalanadi, shuning uchun ro'yxatdagi sana bilan
    /// yig'ma ko'rsatkichdagi sana mos tushadi.
    /// </summary>
    private static DateTime TakenAt(Debt debt) => debt.Sale?.CreatedAt ?? debt.CreatedAt;

    /// <summary>
    /// "Oxirgi olingan qarz" — eng yangi OCHIQ qarz. Barchasi yopilgan bo'lsa
    /// (mijoz endi qarzdor emas) umuman oxirgi qarzga tushamiz, aks holda
    /// ekranda bo'sh joy qolardi va oxirgi to'lov nimaga tegishli ekani
    /// tushunarsiz bo'lar edi.
    ///
    /// Yagona manba: yig'ma ko'rsatkich ham, PDF'dagi batafsil blok ham AYNAN
    /// shu qarzni tanlashi kerak — aks holda KPI bir qarzni, tovarlar ro'yxati
    /// boshqasini ko'rsatadi.
    /// </summary>
    public static Debt? PickLastDebt(Snapshot snapshot)
    {
        var open = snapshot.Debts.Where(d => d.Status == DebtStatus.Open).ToList();
        return (open.Count > 0 ? open : snapshot.Debts)
            .OrderByDescending(TakenAt)
            .FirstOrDefault();
    }

    public static CustomerDebtSummaryDto Build(Snapshot snapshot)
    {
        var (customer, debts, payments) = snapshot;

        var open = debts.Where(d => d.Status == DebtStatus.Open).ToList();
        var lastDebt = PickLastDebt(snapshot);

        // payments allaqachon CreatedAt bo'yicha kamayish tartibida keladi, lekin
        // Build() ni tashqi chaqiruvchi boshqa tartibda bersa ham to'g'ri
        // ishlashi uchun qayta tartiblaymiz.
        var ordered = payments.OrderByDescending(p => p.CreatedAt).ToList();
        var lastPayment = ordered.FirstOrDefault();

        // MUHIM: bu yerga qarzning ota-sotuviga tushgan HAR QANDAY to'lov kiradi —
        // keyinchalik qilingan qarz to'lovi ham, sotuv paytidagi boshlang'ich
        // to'lov (oldindan to'lov) ham. Ikkisi ham qarz qoldig'ini kamaytiradi
        // (RemainingDebt = TotalAmount - PaidAmount), shuning uchun ularni
        // ajratmaymiz. Ajratishning ishonchli belgisi yo'q: Payment'da DebtId
        // FK yo'q va boshlang'ich to'lovning CreatedAt'i sotuv bilan bir xil
        // so'rovda yoziladi (farq millisekundlarda).
        var totalRemaining = open.Sum(d => d.RemainingDebt);
        var totalOriginal = open.Sum(d => d.TotalDebt);

        DateTime? oldest = null;
        var forOldest = open.Count > 0 ? open : debts;
        if (forOldest.Count > 0)
            oldest = forOldest.Min(TakenAt);

        return new CustomerDebtSummaryDto(
            customer.Id,
            customer.FullName,
            customer.Phone,
            totalRemaining,
            totalOriginal,
            totalOriginal - totalRemaining,
            open.Count,
            lastDebt?.TotalDebt ?? 0m,
            lastDebt?.RemainingDebt ?? 0m,
            lastDebt is null ? null : TakenAt(lastDebt),
            lastPayment?.Amount ?? 0m,
            lastPayment?.PaymentType.ToString(),
            lastPayment?.CreatedAt,
            oldest,
            ordered.Take(10).Select(p => new DebtPaymentDto(
                p.Id,
                p.SaleId,
                p.Amount,
                p.PaymentType.ToString(),
                p.CreatedAt)).ToList()
        );
    }

}
