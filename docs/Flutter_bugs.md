🔴 Jiddiy xatoliklar (Dark mode buzilgan)

1. KPI kartalar dark mode'da noto'g'ri ko'rinadi
   Fayl: dashboard_kpi_alert_cards.dart → KpiCard.\_toneColors()

4 ta tondan 3 tasi theme-aware EMAS. Ikona fonlari xom light-rang konstantalaridan olingan:

green → successLight (#D1FAE5 — och nazarli yashil)
purple → accentPurpleLight (#EDE9FE — och lavanda)
blue → infoLight (#DBEAFE — och ko'k)
faqat orange → context.colors.brandLight ✅ (to'g'ri)
Natija: dark navy fonda och pastel plitkalar "yopishtirilgandek" ko'rinadi, brand bilan to'qnashadi.

2. AlertCard butunlay light-mode'ga qotirilgan
   Fayl: dashboard_kpi_alert_cards.dart → AlertCard.\_colors()

\_colors() umuman isDark parametrini olmaydi. dangerLight / warningLight / successLight fonlar + to'q matn — dark mode'da navy ustida och pushti/amber/yashil chiziq qoladi. Bu app_theme_colors.dartdagi izohga to'g'ridan-to'g'ri zid — u yerda "semantik ranglar ikkala fonda ham to'g'ri o'qiladi" deyilgan, lekin bu faqat asosiy ranglarga taalluqli, amalda ishlatilgan Light variantlar uchun emas.

3. \_RetryBanner ham xuddi shu muammo
   Fayl: owner_dashboard_body.dart → \_RetryBanner AppColors.dangerLight foni + danger matn qotirilgan — dark mode'da xira.

🟠 O'rta darajadagi muammolar 4. Emoji ikonka sifatida hamma joyda
Fayllar: KPI/Alert/TopSellers (💰📊👥💎⚠️💸📦✅🛒⏳)

Platformaga qarab har xil chiziladi (iOS ≠ Android)
Theme'ga moslab bo'yab bo'lmaydi (dark mode'da ham bir xil)
O'lcham/balans nazoratsiz, professional POS ilovaga to'g'ri kelmaydi
Accessibility (screen reader) muammosi 5. Tipografika shkalasi chetlab o'tilgan
Deyarli har bir widgetда AppTextStyles.xxx().copyWith(fontSize: ...) bor — KpiCard 22/11, AlertCard 13/12, RetryBanner 12. Shkala mavjud, lekin ishlatilmaydi → type tizimi faqat dekorativ, izchillik yo'qoladi.

6. Uchta har xil "press" tizimi
   AppButton → Listener + AnimationController
   Tappable → ZoomTapAnimation yoki Listener
   Kartalar → InkWell ripple
   Uchta turli interaktiv model = bosish hissi ekrandan ekranga o'zgaradi.

7. Magic number radiuslar
   AppRadius.md + 2 (=12) input'larda — shkalada yo'q qiymat. Token tizimini buzadi.

🟡 Kichik / sayqal muammolari
Spacing nomlanishi — xl/xl2/xl3/xl4 chalkash (4 ta "xl").
Uppercase + letterSpacing label'lar — kirill (RU) matni uchun o'qilishi qiyinlashadi.
Shadow tizimi yo'q — hammasi border bilan tekis, AppButton o'zining shadow'ini inline yasaydi. Soya token'lari yo'q.
childAspectRatio: 1.3 qotirilgan + textScaler hisobga olinmagan — katta shrift sozlamasida KPI matni kesilishi mumkin.
prefers-reduced-motion / accessibility animatsiyalarda hisobga olinmagan.
📋 Tuzatish rejasi (4 faza)
Faza 1 — Dark mode buglarini yopish (eng shoshilinch, ~yarim kun)
KpiCard.\_toneColors'ni isDarkga moslab qayta yozish — har tonning dark variantini berish (yoki context.colors orqali yechish)
AlertCard.\_colors()'ga isDark qo'shib, dark uchun navy-tinted fonlar + yuqori kontrast matn
\_RetryBanner'ni context.colorsga ko'chirish
app_theme_colors.dart'ga semantik tint'larning theme-resolved variantlarini qo'shish (dangerSurface, warningSurface, ... dark uchun)
Faza 2 — Token tizimini mustahkamlash (~1 kun)
Tipografika: copyWith(fontSize:) chaqiruvlarini yo'q qilib, yetishmagan shkala bosqichlarini (masalan, kpiValue, cardTitle) token sifatida qo'shish
Spacing nomlarini qayta tartiblash (space1...space8 yoki sm/md/lg/xl/2xl)
Shadow token'lari qo'shish (elevation1/2/3), AppButton'ni shularga ulash
Magic radiuslarni (md+2) shkala qiymatiga keltirish
Faza 3 — Komponent izchilligi (~1-2 kun)
Emoji'larni icon tizimiga ko'chirish (Material Symbols yoki maxsus icon set) — theme'ga moslashuvchi, bo'yaladigan
Press/tap mexanizmini bittaga birlashtirish (Tappable standart bo'lsin)
Yetishmagan komponentlarni qo'shish: Badge, Chip, Modal, Toast, EmptyState
Faza 4 — Accessibility & sayqal (~yarim kun)
MediaQuery.textScaler'ni KPI grid'da hisobga olish (aspect ratio yoki min-height)
prefers-reduced-motion / disableAnimations'ni animatsiyalarda tekshirish
Kirill uchun label uppercase'ni qayta ko'rish
Kontrast auditi (WCAG AA) — barcha semantik fon+matn juftliklari
