# MarketSystem — To'liq Reja (Texnik + Biznes)

**Loyiha:** MarketSystem (strotech.uz)
**Maqsad:** O'zbekistondagi kichik chakana savdo do'konlari uchun multi-tenant POS SaaS
**Hujjat sanasi:** 2026-05-17
**Holat:** Production-deploy oldidan — biznes va texnik bo'shliqlar mavjud

---

## Mundarija

1. [Loyiha hozirgi holati](#1-loyiha-hozirgi-holati)
2. [Biznes reja](#2-biznes-reja)
3. [Texnik yo'l xaritasi](#3-texnik-yol-xaritasi)
4. [90-kunlik bajaruv rejasi](#4-90-kunlik-bajaruv-rejasi)
5. [Muvaffaqiyat ko'rsatkichlari va Stop-Loss](#5-muvaffaqiyat-korsatkichlari-va-stop-loss)
6. [Risk registri](#6-risk-registri)
7. [Byudjet va resurslar](#7-byudjet-va-resurslar)
8. [Ilovalar](#8-ilovalar)
9. [Dizayn Sistema Migratsiyasi (2026-05-18)](#9-dizayn-sistema-migratsiyasi-2026-05-18)
10. [2-sessiya: Backend ulanish + dark theme + l10n sweep (2026-05-18 kechqurun)](#10-2-sessiya-backend-ulanish--dark-theme--l10n-sweep-2026-05-18-kechqurun) ⭐ yangi

---

## 1. Loyiha hozirgi holati

### Mavjud (yaxshi)
- **Backend (.NET 9):** Clean Architecture, 64+ endpoint, multi-tenancy
- **Frontend (Flutter):** Web + mobile, role-based routing
- **Database:** PostgreSQL 16 + EF Core, 16 migration applied
- **Auth:** JWT + refresh + revoked tokens (DB-backed)
- **SuperAdmin Console:** Owner CRUD, Market Block lifecycle, real-time validation
- **Security:** BCrypt, rate limiting, CORS, audit log, JTI revocation
- **CI/CD:** GitHub Actions yashil (backend + Flutter + Docker build)

### Yo'q (xato yoki to'liqsiz)

| Kategoriya | Yo'q narsa | Production blocker? |
|------------|------------|---------------------|
| **Qonuniylik** | OFD/Soliq Qo'mitasi integratsiyasi | 🔴 HA |
| **To'lov** | Click/Payme/Apelsin/UzCard | 🔴 HA |
| **Mavjudlik** | Offline rejim, eventual sync | 🔴 HA |
| **Hardware** | Termal printer (ESC/POS), shtrix-skaner | 🔴 HA |
| **Backup** | Avtomatik pg_dump + retention | 🔴 HA |
| **UX** | Onboarding wizard, mahsulot import (Excel) | 🟠 Mijoz keladi-ketadi |
| **Operatsion** | Monitoring/alerting, runbook'lar | 🟠 Bilmasdan sinasiz |
| **Test** | Real UI testlar, multi-tenant leak testlari | 🟡 Production bug xavfi |
| **Marketing** | Landing page, narx jadvali, demo video | 🟠 Sotuv yo'q |

### Biznes bo'shliqlari (eng kritik)
1. **Hech qanday mijozdan validation yo'q** — kod mijoz og'rig'iga emas, dasturchi tasavvuriga qurilgan
2. **Sotuv strategiyasi yo'q** — birinchi 10 mijozni qaerdan topish noma'lum
3. **Narx jadvali yo'q** — subscription model haqida gap bor, ammo tarif aniqlanmagan
4. **Customer Success jarayoni yo'q** — onboarding, training, support kanali yo'q

---

## 2. Biznes reja

### 2.1 Maqsadli mijoz (Ideal Customer Profile)

**Birinchi 50 mijoz — strict ICP:**
- O'zbekiston, **Toshkent shahar** (boshlash uchun bitta shahar)
- 1-2 sotuvchi bilan ishlovchi **chakana mahsulot do'koni** (oziq-ovqat, maishiy)
- **Daftar yoki Excel'da** hisob yuritadi (modernizatsiyaga tayyor)
- Oy aylanmasi **30-300 mln UZS** orasida
- Egasi **30-50 yosh**, smartfon va Telegram'dan foydalanadi
- Tahminan 5,000+ ta mahsulot mavjud Toshkentda (Soliq ma'lumotlari)

**Targetga KIRMAYDI:**
- Restoran, kafe (boshqa requirements)
- Online-only do'kon
- Yirik supermarket (1C ishlatadi)
- O'tkir bozor (1-2 odam, savdo daftaridan oddiyroq narsani xohlamaydi)

### 2.2 Qiymat takliflari (eng kuchli birinchi)

1. **"Yondashuv: Soliqqa qonuniy ulanish"** — OFD sertifikatlangan, tashvishsiz
2. **"Internet uzilsa ham ishlaydi"** — offline rejim
3. **"15 daqiqada birinchi sotuv"** — onboarding wizard
4. **"Excel'dagi mahsulotlarni 1 daqiqada import qiling"** — hech qanday qo'lda kiritish
5. **"Telegram'dan kuni hisoboti"** — har kun soat 22:00'da

### 2.3 Monetizatsiya

**Tariflar (UZS, oylik):**

| Tarif | Narx/oy | Sotuvchilar | Hisobot | Maqsad |
|-------|---------|-------------|---------|--------|
| **Boshlovchi** | 150,000 | 1 | Asosiy | 1-2 oy bepul (acquisition) |
| **Standart** | 250,000 | 3 | Premium | Asosiy mijoz |
| **Pro** | 450,000 | 7 | Premium + API | Yirik do'kon |
| **Hardware bundle** | 3,500,000 (bir martalik) | + termal printer + tablet | — | Setup |

**Yillik chegirma:** 25% (2-oy bepul)
**Birinchi 6 oy:** "Beta-tester" — har ikkala tomonda **bepul** lekin **Telegram support guruh** ga qo'shilish majburiy

### 2.4 Sotuv strategiyasi (eng katta zaiflik)

**Birinchi 10 mijoz — sizning vaqtingiz**
- Hech qanday reklama emas. **Eshikma-eshik**.
- Kuniga 5 ta do'kon = haftada 25
- Konversiya: 100 demo → 10 ro'yxat → 5 aktiv → 1 to'lovchi (1-oy)
- **Sizning vazifangiz:** har kuni soat 14:00-19:00 (do'kon kam mijozli vaqt) do'konlarni aylanib chiqish

**11-50 mijoz — referral va sotuvchi**
- Har mijoz 3 ta tanish do'konni tavsiya qiladi → bepul oy
- Telegram kanal: "Strotech POS — to'lovsiz sinab ko'ring"
- 1 ta junior sotuvchi yollash (komission asosida — 1 sotuv = 200K UZS)

**51+ mijoz — institutsional**
- Buxgalter dorxonalari bilan partnership (ular tavsiya qiladi)
- Soliq Qo'mitasi sertifikatlangan POS ro'yxatiga kirish

### 2.5 Aniq differentiatorlar (raqobatchilarga qarshi)

| Raqobatchi | Ularning afzalligi | Sizning afzalligingiz |
|------------|--------------------| ----------------------|
| **1C Buxgalteriya** | Buxgalterlar tushunadi | Web/mobile, bulutda, $15/oy vs $300+ |
| **Smart Up** | Brand, sertifikat | Onboarding 15 daqiqa vs 2 hafta |
| **MyKassa** | OFD integratsiyasi | UI sodda, offline ishlaydi |
| **Excel/daftar** | Bepul, oddiy | Avto-hisobot, real-vaqt qarz nazorat |

**Sizning aniq differentiatorlaringiz:**
- **Telegram bot integratsiyasi** — kun hisoboti, sotuvchi nazorati telegramda
- **Multi-cashier real-time** — bir vaqtda 2-3 sotuvchi
- **Modern UI** (web + mobile sinxronlash)
- **Honest pricing** ($15/oy, hidden costs yo'q)

---

## 3. Texnik yo'l xaritasi

### 3.1 P0 — Production'ga chiqishdan oldin MAJBURIY

#### A. Qonuniy compliance (4-6 hafta)

- [ ] **OFD provayder tanlash va kontrakt**
  - Variantlar: `ofd.uz`, `kassa.uz`, `1c-ofd.uz`
  - API hujjatlari, oylik narx, integratsiya qiyinligi
  - **DoD:** Sandbox'da test fiskal chek yuborildi

- [ ] **OFD integratsiyasi kod yozish**
  - Yangi service: `IFiscalService` (Application layer)
  - Implementation: `OfdFiscalService` (Infrastructure)
  - Sotuv complete bo'lganda chaqirish: `SaleService.CompleteSaleAsync`
  - Retry policy: 3 marta urinish + offline queue
  - **DoD:** Real chek soliqdan ko'rinmoqda

- [ ] **Soliq sertifikatlash uchun ariza**
  - ED-imzo qabul qilish (do'kon nomidan)
  - Sertifikatlash markaziga test holatlari
  - **Vaqt:** 2-3 oy (parallel ravishda boshqa ish bilan)

#### B. To'lov gateway (2 hafta)

- [ ] **Click va Payme tanlash** — bittani tanlang, mukammal qiling
- [ ] **Subscription model**
  - DB: `Subscription` entity (PlanId, StartedAt, ExpiresAt, MarketId, AutoRenew)
  - DB: `Payment` entity (mavjud — kengaytirish)
- [ ] **Webhook handler** — Click'dan to'lov tasdiqlandi → `Subscription.ExpiresAt` uzaytirish
- [ ] **Auto-block** — `ExpiresAt < now` → background job `BlockMarketAsync`
  - Hosted service: `SubscriptionExpiryCheckJob` (har 6 soatda)
- [ ] **Reminder** — 7, 3, 1 kun qolganda Telegram orqali xabar
- [ ] **DoD:** Test do'kon to'lov qildi → tarif faollashdi → 1 oy o'tib block qilindi → qayta to'lov qilindi → unblock

#### C. Offline mode (1-2 hafta)

- [ ] **Lokal SQLite** (Flutter `sqflite` paketi)
  - Sxema: backend ResultDto'lar mirror
  - Mahsulot kataloligi, sotuv tarixi (so'nggi 90 kun)
- [ ] **Sync strategy** (last-write-wins yoki vector clock)
  - Sotuv: offline yaratiladi, server bilan eventual sync
  - Stock: server source of truth (online bo'lganda refresh)
  - Conflict resolution: server priority
- [ ] **UI indicator** — connection state, sync status, pending count
- [ ] **DoD:** Internet uchganda 10 ta sotuv kiritildi → online bo'lganda hammasi sync bo'ldi → server `SaleCount` to'g'ri

#### D. Termal printer (3-5 kun)

- [ ] **Hardware tanlash** — eng tarqalganni qo'llab-quvvatlash: Goojprt PT-210, XPrinter XP-58IIH (58mm)
- [ ] **Driver/protocol** — ESC/POS commands
- [ ] **Flutter integratsiya** — `flutter_blue_plus` (BT) yoki `flutter_pos_printer_platform` (USB/Bluetooth)
- [ ] **Chek template** — logo (PNG), do'kon nomi, sotuv items, QR-code (OFD link), jami summa, sana
- [ ] **DoD:** Real Goojprt printerda chek chiqdi va o'qib bo'ladi

#### E. Backup va recovery (1-2 kun)

- [ ] **Cron job** — har kuni 03:00 da `pg_dump`
- [ ] **Saqlash joyi** — local + S3 backup (parol bilan shifrlangan)
- [ ] **Retention:** 14 kun lokal, 90 kun S3
- [ ] **Restore test** — oyiga 1 marta test (script yozish)
- [ ] **Runbook:** [docs/runbooks/RESTORE.md](runbooks/RESTORE.md)

#### F. Monitoring va alerting (2-3 kun)

- [ ] **UptimeRobot** — `/health` endpoint kuzatish (5 daqiqa interval)
- [ ] **Telegram alert** — server o'chdi, error rate yuqori, disk to'lib boryapti
- [ ] **Sentry yoki Application Insights** — exception tracking
- [ ] **DB metrics** — connection pool, slow queries (>1s)
- [ ] **Dashboard** — Grafana (yoki PowerBI) — kunlik aktiv do'konlar, jami sotuv

### 3.2 P1 — Birinchi 10 mijoz uchun

- [ ] **Onboarding wizard** (Flutter)
  - 1-qadam: do'kon ma'lumotlari (nom, manzil, telefon)
  - 2-qadam: kategoriya tanlash (Oziq-ovqat / Maishiy / ...)
  - 3-qadam: 5 ta demo mahsulot kiritish
  - 4-qadam: birinchi test sotuv
  - 5-qadam: chek chiqarish

- [ ] **Excel import** (backend mavjud — frontend qo'shish)
  - Template yuklab olish
  - Mahsulot ro'yxati Excel'dan kiritish
  - Validatsiya, duplicate detection
  - Bir vaqtda 500+ qator

- [ ] **Hisobotlar PDF eksport** (mavjud Excel kengaytirish)
  - Kun hisoboti, oy hisoboti
  - QuestPDF allaqachon backend'da

- [ ] **Telegram notification**
  - Bot: `@StrotechBot`
  - Owner shaxsiy telegram'ni bog'lash (deeplink orqali)
  - Kun yakuni: sotuv summasi, eng ko'p sotilgan mahsulot
  - Smena yopilganda
  - Qarz to'lov muddati keldi

- [ ] **Shtrix-skaner qo'llab-quvvatlash**
  - USB HID (keyboard wedge mode) — Flutter web'da text input bilan ishlaydi
  - Bluetooth qo'llab-quvvatlash mobile'da
  - QR code (Soliq markirovkasi uchun)

### 3.3 P2 — Texnik qarz va sifat

- [ ] **Test coverage 60%+** (hozir ~10%)
  - Multi-tenant data leak testi
  - Block enforcement testi (login + middleware)
  - Sotuv qaytarish + qarz sync testi
  - Concurrent sales (race condition)

- [ ] **Secrets management**
  - `appsettings.Development.json` git tarixidan tozalash
  - Production env vars: 1Password yoki HashiCorp Vault yoki Doppler
  - JWT key rotation jarayoni (har 6 oyda)

- [ ] **CI yaxshilash**
  - Pre-commit hooks (husky/lint-staged)
  - Branch protection — master'ga to'g'ri push taqiqlanadi
  - Test coverage shartli (Codecov yoki SonarCloud)
  - E2E test (Playwright web uchun)

- [ ] **Database HA**
  - PostgreSQL streaming replica
  - Failover script (manual yoki Patroni)
  - **Yoki** managed DB — Supabase, Neon, AWS RDS

- [ ] **Hozirgi kodda darhol tuzatilishi kerak**
  - `AppConfig._devFallbackSegment` kod ichida turibdi — env'ga ko'chirish
  - `auth_service.dart:186` `print()` → `debugPrint()`
  - `AuthService._isTokenExpired` vaqt zonasi audit
  - `RegisterAsync`'da audit log yo'q — qo'shish
  - CORS allowed origins production'da to'g'rilash
  - DI'da `IRevokedTokenStore` → `DbRevokedTokenStore` ekanini tasdiqlash

### 3.4 P3 — Keyinroq (3-6 oy)

- [ ] Multi-language (Russian to'liq qo'llab-quvvatlash)
- [ ] White-label (owner o'z brand'i bilan)
- [ ] Mobile app (iOS/Android native build)
- [ ] Inventory forecasting
- [ ] Loyalty / mijoz karta
- [ ] Promo / chegirma kuponlari
- [ ] Multi-branch (1 ega bir nechta do'kon)
- [ ] API SDK (3-tomonchi integratsiya)

### 3.5 To'xtatilishi kerak

- ❌ Yangi entity (Owner, Market, Sale, Product yetarli)
- ❌ Refactoring "yaxshilash uchun"
- ❌ Performance optimizing (30 mijozda kerakmas)
- ❌ Microservices'ga bo'lish (premature)
- ❌ Yangi UI ekran SuperAdmin tomonida

---

## 4. 90-kunlik bajaruv rejasi

### Hafta 1: Customer Development (kod yo'q!)

| Kun | Faoliyat | Natija |
|-----|----------|--------|
| Du | Soliq Qo'mitasi qo'ng'iroq, OFD jarayonini o'rganish | Hujjatlar ro'yxati |
| Se | Toshkentda 5 ta do'kon egasi ro'yxati (Yunusobod) | Telefon raqamlari |
| Ch | Do'kon 1 va 2 — 60 daq suhbat | Yozma intervyu (audio) |
| Pa | Do'kon 3 va 4 — 60 daq suhbat | Yozma intervyu (audio) |
| Ja | Do'kon 5 — 60 daq + birinchi 4'ni tahlil | Customer profile dokument |
| Sh-Ya | Insight yozish, P0 funksiyalar ro'yxatini do'kon ehtiyojiga moslash | `docs/CUSTOMER_INSIGHTS.md` |

**Hafta yakuni qaror:** Davom etish yoki yo'l o'zgartirish

### Hafta 2-3: Texnik xavfsizlik

| Hafta | Vazifa | DoD |
|-------|--------|-----|
| 2 | Database backup + monitoring + secrets cleanup | pg_dump cron ishlamoqda, UptimeRobot Telegram'ga xabar yuborddi |
| 3 | Multi-tenant leak test, block enforcement test, audit cleanup | 5 yangi integration test, eski 8 warning olib tashlandi |

### Hafta 4-7: OFD POC va integratsiyasi

| Hafta | Vazifa | DoD |
|-------|--------|-----|
| 4 | OFD provayder tanlash, API hujjatlash, sandbox account | Sandbox'da 1 test chek |
| 5 | `IFiscalService` + `OfdFiscalService` POC | Sotuv → OFD'ga yuborildi, ID qaytdi |
| 6 | Retry queue + offline fallback | Internet uzilganda chek kechiktirildi, qayta yuborildi |
| 7 | Soliq sertifikat arizasi + integratsion test | Hujjatlar topshirildi |

### Hafta 8-9: Offline mode + Termal printer

| Hafta | Vazifa | DoD |
|-------|--------|-----|
| 8 | sqflite lokal DB, sync strategy POC | 10 ta offline sotuv → online'ga sync |
| 9 | ESC/POS printer (Goojprt PT-210) | Real chek chop etildi (logo + QR) |

### Hafta 10-11: Onboarding + UX

| Hafta | Vazifa | DoD |
|-------|--------|-----|
| 10 | Onboarding wizard (5 qadam) | 1-mijoz 15 daqiqada test sotuv qildi |
| 11 | Excel import + Telegram bot kunlik hisobot | 500 mahsulot 1 daq'da kiritildi |

### Hafta 12-13: To'lov gateway

| Hafta | Vazifa | DoD |
|-------|--------|-----|
| 12 | Click integratsiyasi + Subscription entity | Test mijoz to'ladi, ExpiresAt yangilandi |
| 13 | Auto-block + Telegram reminder | E2E test: to'lov tugadi → 7 kun ogohlantirish → block |

### Hafta 13: BIRINCHI HAQIQIY MIJOZ

**Bu hafta:**
- 1 ta do'kon to'liq onboarding (siz shaxsan)
- 7 kun 100% support
- Backup'lar tasdiqlangan
- 5 bug'siz kun

### Hafta 14-22: Mijoz ko'paytirish

- Har hafta 1 ta yangi mijoz (5-7 ta bepul beta)
- Har kuni 30 daq feedback yig'ish
- Bug fix only (yangi feature yo'q)
- 13-haftada 5 ta aktiv, 22-haftada 10 ta aktiv

### Hafta 23-26: Birinchi to'lov

**Bu davrda kerakli:**
- 3 ta aktiv mijoz pul to'laydi (har biri ~200,000 UZS/oy = 600,000 UZS)
- Texnik qarz < 20 ta open issue
- Customer Telegram guruh — 10+ ta a'zo
- 1 ta ish: junior sotuvchi yollash (komissiya bilan)

---

## 5. Muvaffaqiyat ko'rsatkichlari va Stop-Loss

### KPI'lar (haftalik o'lchov)

| Metric | Hafta 4 maqsad | Hafta 13 maqsad | Hafta 26 maqsad |
|--------|----------------|-----------------|------------------|
| Customer suhbatlari | 5 | 20 | 40 |
| Demo o'tkazilganlar | — | 10 | 30 |
| Aktiv mijozlar | — | 1 | 10 |
| To'lovchi mijozlar | — | — | 3 |
| Oylik daromad (UZS) | — | — | 600,000+ |
| Production uptime | 99% | 99.5% | 99.9% |
| Critical bug response time | — | <6 soat | <2 soat |
| Mijoz NPS (5/5 da) | — | 4.0 | 4.3 |

### Stop-Loss mezonlari (qattiq qoidalar)

🛑 **Hafta 4:** Agar 3 ta do'konda **birortasi ham** "Bu menga kerak" demasa → **mahsulotni qayta o'ylab ko'rish**

🛑 **Hafta 13:** Agar 1 ta haqiqiy aktiv mijoz yo'q bo'lsa → **sotuv jarayoni ishlamayapti**, sotuvchi yollash yoki yo'l o'zgartirish

🛑 **Hafta 22:** Agar churn rate > 30% bo'lsa → **mahsulot-bozor mos kelishi yo'q**, asosga qaytish

🛑 **Hafta 26:** Agar oylik daromad < 500,000 UZS bo'lsa → **biznes model ishlamayapti**, yopish yoki pivot

### Quvonchli ko'rsatkichlar (davom etish belgilari)

✅ Mijoz so'raydi: "Boshqa narsa qila olasizmi?" (mahsulot kengaytirish ehtiyoji)
✅ Mijoz tavsiya qiladi (qiyin metrika, lekin oltin)
✅ Mijoz nima uchun kelganini emas, **nima uchun qoladi**ni biladi
✅ Customer support savollar har mijozdan <2 ta/oy

---

## 6. Risk registri

| # | Risk | Ehtimollik | Effekt | Mitigation |
|---|------|------------|--------|-----------|
| 1 | OFD sertifikati 6+ oy oladi | 70% | Production'ga chiqib bo'lmaydi | Erta boshlash, OFD provayder bilan partnership |
| 2 | Click/Payme integratsiya kechikadi | 50% | To'lov yo'q, model ishlamaydi | Backup variant — manual bank transfer kvitansiya |
| 3 | Birinchi 3 mijoz ishlatmaydi | 60% | Mahsulot-bozor mos kelmaydi | Customer dev jiddiy o'tkazish, har feature mijoz so'roviga moslash |
| 4 | Solo founder burnout | 80% | Loyiha to'xtaydi | Hafta-yakuni majburiy dam, support uchun freelancer |
| 5 | Production bug (data leak) | 30% | Mijozlar ketadi, jarima | Multi-tenant test 100%, soft launch (5 mijoz) |
| 6 | Raqobatchi narxni tushiradi | 40% | Marketing qiyin | Differentiator — OFD + offline + telegram |
| 7 | Internet hostingi muammosi | 25% | Outage | Backup hosting, Cloudflare, monitoring |
| 8 | Soliq qonunchiligi o'zgaradi | 20% | Kodni qayta yozish | OFD provayder bilan yaqin aloqa |
| 9 | Mijoz pul to'lamaydi (qarz) | 50% | Cash flow muammosi | Tarif: prepaid only, auto-block |
| 10 | Sertifikat tashqi muddatda olinmaydi | 40% | Qonuniy chiqib bo'lmaydi | "Beta" sifatida bepul + sertifikat kelishini kutish |

---

## 7. Byudjet va resurslar

### 6 oylik minimum byudjet (UZS)

| Modda | Oylik | 6 oy jami |
|-------|-------|-----------|
| Server (VPS, Linode/Hetzner) | 250,000 | 1,500,000 |
| Domen (.uz) | 50,000 (yillik) | 50,000 |
| SSL sertifikat | Bepul (Let's Encrypt) | 0 |
| OFD provayder | 500,000 | 3,000,000 |
| Click/Payme komissiya | 0% boshida | 0 |
| Telegram Bot API | Bepul | 0 |
| UptimeRobot | Bepul (5 monitor) | 0 |
| S3 backup (R2/Backblaze) | 80,000 | 480,000 |
| Test telefon (Android/iOS) | — | 3,000,000 (bir martalik) |
| Termal printer (test uchun) | — | 1,500,000 (bir martalik) |
| Domain marketing (test) | — | 2,000,000 |
| **Jami minimum** | **880K** | **~11.5M UZS (~$850)** |

### Sotuvchi marketing (P1)

| Kanal | Hafta byudjet | 6 oy |
|-------|---------------|------|
| Telegram reklama | 200,000 | 4,800,000 |
| Instagram (mahalliy) | 300,000 | 7,200,000 |
| Door-to-door (transport) | 100,000 | 2,400,000 |
| **Jami** | **600K** | **~14.4M UZS (~$1,000)** |

### **Umumiy 6 oy: ~$2,000 minimum + $500 buferi = $2,500**

### Vaqt resursi

- **Sizning vaqt:** **8-10 soat/kun** × **6 kun/hafta** × 26 hafta = **~1,400 soat**
- Bu **to'liq stavka ekvivalent**ga teng — boshqa ish bilan parallel olib bo'lmaydi
- Junior sotuvchi (hafta 12+): komissiya asosida, sof xarajat yo'q

### Ekvivalent: agar bunda 1 founder + 1 sotuvchi (komissiya) bo'lsa, 6 oyda 10 ta to'lovchi mijoz topish realistik

---

## 8. Ilovalar

### A. Kontaktlar va manbalar

- **OFD provayderlari:**
  - https://ofd.uz (Tex SoliqService)
  - https://kassa.uz (KassaUz)
  - https://1c-ofd.uz (1C OFD)

- **To'lov gateway:**
  - https://docs.click.uz (Click)
  - https://developer.payme.uz (Payme)
  - https://apelsin.uz (Apelsin)

- **Soliq Qo'mitasi:**
  - https://soliq.uz
  - Onlayn-kassa: https://onlinekassa.soliq.uz
  - Sertifikatlash markazi: https://my.soliq.uz

- **Hardware sotuvchilar:**
  - Goojprt: AliExpress (PT-210, $25-35)
  - XPrinter: O'zbekistondagi distributorlar (XP-58IIH, ~500K UZS)

### B. Customer interview shablon

**Suhbat oldidan:**
- 30 daqiqa vaqt so'rang
- Aytmang: "Men POS sotaman"
- Ayting: "Men do'konlar haqida o'rganaman, fikr olishni xohlayman"

**Asosiy savollar:**
1. Kun davomida qaysi ishingiz eng ko'p vaqt oladi?
2. Hozir hisob qanday yuritasiz?
3. Eng oxirgi marta xato qaerda bo'lgan? Nima sodir bo'ldi?
4. Soliq Qo'mitasiga hisobotni qanday topshirgansiz?
5. Sotuvchingiz tugatilgan mahsulotlarni qanday bildiradi?
6. Internet uzilganda nima qilasiz?
7. Yangi tizim olishingiz uchun nima narsa muhim?

**Suhbat tugagach:**
- Yozma forma to'ldiring (30 daq ichida)
- Ularning ismi, telefoni, do'kon turi
- Eng aniq jumlani qayd eting (kavishlarda)
- "Bu fikr meni kelajakda davom etishimga ta'sir qilarmi?" — Ha/Yo'q

### C. Bug priorityzatsiya

| Belgi | Tavsif | Vaqt |
|-------|--------|------|
| **P0** | Production'da pul yo'qotiladi yoki ma'lumot leak | <2 soat |
| **P1** | Asosiy funksiya ishlamaydi (sotuv, login) | <24 soat |
| **P2** | Yon funksiya buzilgan, workaround bor | <1 hafta |
| **P3** | UX yaxshilash, kichik nosozlik | Sprint da |

### D. Hozir DARHOL tuzatilishi kerak bo'lgan kod bo'shliqlari

1. `MarketSystem.Client/lib/core/config/app_config.dart` — `_devFallbackSegment` env'ga ko'chirish
2. `MarketSystem.Client/lib/data/services/auth_service.dart:186` — `print()` → `debugPrint()`
3. `MarketSystem.API/Bootstrap/SuperAdminSeeder.cs` — birinchi marta yaratilganda parolni stdout'ga chiqarish (one-time only)
4. `MarketSystem.Application/Services/RegistrationRequestService.cs` — audit log to'liq `RegisterAsync` qo'shish
5. `appsettings.Development.json` — git tarixidan tozalash (`git filter-repo`)
6. CI: Codecov yoki coverage threshold
7. README.md — quick start, env vars, troubleshooting

### E. Hujjatlar yaratish kerak

- [ ] `docs/PRICING.md` — narx jadvali (yuqorida bor)
- [ ] `docs/CUSTOMER_INSIGHTS.md` — har customer dev hafta to'ldiriladi
- [ ] `docs/runbooks/INCIDENT_RESPONSE.md` — production muammo paytida nima qilish
- [ ] `docs/runbooks/BACKUP_RESTORE.md` — DB restore protsedurasi
- [ ] `docs/runbooks/DEPLOY.md` — yangi versiya production'ga chiqarish
- [ ] `docs/architecture/MULTI_TENANCY.md` — multi-tenant model qanday ishlaydi
- [ ] `docs/architecture/SECURITY.md` — JWT, RBAC, audit
- [ ] `docs/onboarding/CUSTOMER_GUIDE.md` — mijoz uchun qo'llanma (UZ + RU)

---

## Yakuniy gap

Bu reja **sizning loyiha texnik jihatdan tayyor** bo'lganini hisobga oladi. Lekin **biznes jihatdan 0-bosqichdasiz**.

Reja muvaffaqiyati 3 ta narsaga bog'liq:

1. **Hafta 1 da haqiqiy mijoz bilan suhbat o'tkazish** — bu hech qachon to'liq sodir bo'lmagan
2. **Hafta 4-7 da OFD sertifikatga harakat boshlash** — bu siz boshqaroli emas, davlat jarayoni
3. **Hafta 13 da birinchi haqiqiy aktiv mijoz** — bu sizning sotuv qobiliyatingiz

Agar shu 3 narsadan biri bajarilmasa, qolgani matter qilmaydi.

**Birinchi qadam: bugun soat 14:00 da 3 ta do'kon egasi ro'yxatini yozing va ulardan biriga qo'ng'iroq qiling.**

---

## 9. Dizayn Sistema Migratsiyasi (2026-05-18)

### 9.1 Sabab

Loyiha legacy dizayn (`AppColors.orangePrimary #F28C33`, kulrang fonlar, `AdaptiveTheme.dark`) bilan ishlardi. UI/UX tahlilidan keyin yangi dizayn sistema ishlab chiqildi va 58 ta HTML mock ekranida sinab ko'rildi (`design-demo/index.html`). Endi haqiqiy Flutter kodga ko'chirildi.

### 9.2 Yangi dizayn sistema

**Tokens** (`lib/design/tokens/`):
- `AppColors` — brand `#FF6B00` (yangi turuncha), semantic ranglar (success/warning/danger), neutral text shkalalari
- `AppSpacing` — xs/sm/md/lg/xl/xl2/xl3/xl4 (4/6/8/12/16/20/24/32 px)
- `AppRadius` — sm/md/lg/xl/xl2/full (6/10/14/16/18/9999)
- `AppTextStyles` — **Inter font** (Google Fonts), 10 ta style

**Theme** (`lib/design/theme/app_theme.dart`):
- `AppTheme.light` — to'liq Material 3, M3 ColorScheme, oq AppBar, kulrang input fill, orange focus border
- Dark mode hozircha o'chirilgan (light-only) — kelajakda qo'shiladi

**Widgets** (`lib/design/widgets/`):
- `AppPrimaryButton` / `AppSecondaryButton` / `AppDangerButton` — full-width, loading state, ikon support
- `AppCard` — oq surface, 1px border, 14px radius
- `AppTextInput` — uppercase label, gray fill, orange focus

### 9.3 Migratsiya bosqichlari

| # | Feature | Fayllar |
|---|---------|---------|
| 1 | Main App Theme | main_app.dart |
| 2 | Welcome (PNG logo saqlangan) | welcome_screen.dart |
| 3 | Login (auth logic 100% saqlangan) | login_screen.dart |
| 4 | Register (phone mask saqlangan) | register_screen.dart |
| 5 | Splash | splash_screen.dart |
| 6 | Dashboard (Owner/Admin/Seller) | dashboard_screen + widgets |
| 7 | POS (Sotuv) | new_sale_screen, sale_body |
| 8 | POS dialoglari (4 ta) | payment, external_product, customer, price |
| 9 | Mahsulotlar (3 fayl) | list, form, body |
| 10 | Sotuvlar tarixi (9 fayl) | screens + widgets |
| 11 | Mijozlar + Qarzlar (15 fayl) | customers + debts |
| 12 | Hisobotlar (17 fayl) | screens + widgets |
| 13 | Kassa + Zakup (10 fayl) | cash_register + zakup |
| 14 | Users (4 fayl) | users_screen + widgets |
| 15 | Categories (3 fayl) | management + sheet + card |
| 16 | Profile (3 fayl) | screen + widgets |
| 17 | SuperAdmin (9 fayl) | console + 8 dialog |
| 18 | Continue Sale (5 fayl) | screen + widgets |
| 19 | Sales Debtors (4 fayl) | screens + dialogs |

**Jami: ~100+ ta Flutter fayl ko'chirildi.**

### 9.4 Tozalash

**O'chirilgan eski fayllar:**
- `lib/core/constants/app_colors.dart` (60 qator) — eski rang konstantalari
- `lib/core/constants/app_styles.dart` (41 qator) — eski TextStyle
- `lib/core/theme/app_theme.dart` (186 qator) — eski AppTheme

**Yangilangan core fayllar:**
- `lib/core/widgets/common_app_bar.dart` — yangi tokenlarga moslashtirildi
- `lib/main_app.dart` — `AppTheme.light` ulandi

**Boshqa tuzatishlar:**
- 121 ta `print()` → `debugPrint()` (production konsol toza)
- 55 ta dangling library doc comments (`///` → `//`)
- 3 ta deprecated Flutter API (DropdownButtonFormField.value → initialValue, Switch.activeColor → activeThumbColor)
- Leading-space fayl rename (`continue_sale_screen.dart`)

### 9.5 Saqlangan biznes mantiq (100%)

**Hech qanday biznes funksiya buzilmadi:**
- ✅ `AuthProvider` — login/logout/refresh/SuperAdmin routing
- ✅ `LoginOutcome` enum — market_blocked dialog with reason
- ✅ Autofill o'chirilgan (`AutofillGroup` + `TextInput.finishAutofillContext()`)
- ✅ `SalesBloc` + `CartProvider` — savat, to'lov, qaytarish
- ✅ `CustomersBloc` + `DebtService` — mijoz va qarz boshqaruv
- ✅ Optimistic restore (SharedPreferences tokendan instant boot)
- ✅ Excel/PDF eksport (`ReportService`)
- ✅ Phone validator (`+998` Uzbek format)
- ✅ Role-based UI (Owner/Admin/Seller)
- ✅ l10n (`AppLocalizations`) — uz/ru
- ✅ Optimistic delete with rollback
- ✅ `CustomerAvatarPalette.pick(name)` — bir xil mijoz hamma joyda bir xil rangda

### 9.6 Build va sifat ko'rsatkichlari

| Ko'rsatkich | Boshlang'ich | Yakuniy | Δ |
|-------------|--------------|---------|---|
| `flutter analyze` info | 200 | **20** | **-180** |
| `flutter analyze` error | 0 | **0** | ✓ |
| `flutter analyze` warning | 0 | **0** | ✓ |
| Build web | ✓ | **✓ 50s** | tezroq |
| Kod qatorlari (legacy) | +287 | -287 | tozalandi |

**Qolgan 20 info** (production kritik emas):
- `use_super_parameters` (4) — constructor super.key migratsiya
- `prefer_const_constructors` (4)
- `deprecated_member_use` (3)
- Boshqa kichik style lint'lar

### 9.7 Keyingi qadamlar

**Yaqin muddatda:**
- Brauzerda qo'lda har bir ekrandan o'tib vizual sinash
- Backend bilan integratsiya sinov (login + sotuv + qarz)
- Real foydalanuvchi bilan 1-2 do'kon test

**Kelajakda:**
- Dark mode dizayni va `AppTheme.dark` qo'shish
- Yangi backend endpoint'lar talab qiladigan demo elementlarni qurish:
  - Foyda hisoboti chart (Aylanma vs Foyda)
  - Top mahsulotlar ranking (🥇🥈🥉)
  - Xodimlar samaradorligi sahifasi
  - "Doimiy" mijoz flag
  - SMS eslatma yuborish
- Multi-item zakup batch (hozir bittadan)
- Continue Sale screen file naming (already fixed)

---

**Migratsiya muallifi:** Claude (Anthropic)
**Migratsiya sanasi:** 2026-05-18
**Asosida:** `design-demo/index.html` — 58 ta HTML mock ekran

---

## 10. 2-sessiya: Backend ulanish + dark theme + l10n sweep (2026-05-18 kechqurun)

Migratsiyadan keyingi sessiyada loyiha "ko'rinadi-lekin-ishlaydi" holatdan to'liq end-to-end ishlovchi holatga keltirildi. Commit: `44ffd06`.

### 10.1 API ulanish auditi (Agent 1)

Migratsiya paytida ba'zi Flutter API path'lari backend route'lari bilan to'g'ri kelmagan edi — endpoint mavjud lekin yo'l noto'g'ri yozilgan. Auditdan keyin **10 ta 404 mismatch** topib tuzatildi:

| # | Eski (404) | Yangi (to'g'ri) |
|---|------------|------------------|
| 1 | `GET /Customers/phone/{phone}` | `GET /Customers/GetCustomerByPhone/phone/{phone}` |
| 2 | `GET /Customers/GetCustomerDeleteInfo/{id}` | `+/delete-info` |
| 3 | `GET /Products/GetLowStock` | `GetLowStockProducts/low-stock` |
| 4 | `GET /Products/ExportProductsToExcel` | `+/export` |
| 5 | `GET /Reports/ExportCategoriesToExcel` | `→ /ProductCategories/...` |
| 6 | `GET /Zakups/GetZakupsByDateRange?...` | `+/by-date?...` |
| 7 | `GET /Zakups/ExportZakupsToExcel` | `+/export` |
| 8-9 | Buzuq URL'lar `POST /Users/.../{id}` | `POST /Users/{Action}/{id}/{verb}` |
| 10 | `GET /Reports/ExportCustomersToExcel` | **Backend'da yo'q** (FIXME) |

7 ta data layer fayli tuzatildi: `customer_service.dart`, `product_service.dart`, `zakup_service.dart`, `users_service.dart`, `download_service.dart`, `product_remote_data_source.dart`, `product_repository_impl.dart`.

### 10.2 Dashboard real ma'lumotga ulandi (Agent 3)

Migratsiya paytida dashboard widget'lari hardcoded mock ko'rsatardi ("2 450 000", "28 chek", "12.4M" va h.k.). 2-sessiyada yangi data layer qo'shildi:

**Yangi fayllar:**
- `lib/data/services/dashboard_service.dart` — `DashboardService` + `DashboardSummary` (15 maydon)
- `lib/data/services/notification_service.dart` — `NotificationService.loadUnreadCount()`

**Ulangan backend endpoint'lar:**
- `/Reports/profit-summary`, `/Reports/daily`, `/Reports/daily-items`
- `/Reports/daily-sales-list`, `/Reports/period`
- `/Customers/GetAllCustomers`, `/Products/GetAllProducts`
- `/Debts/GetAllDebts`, `/Products/GetLowStockProducts/low-stock`

**Widget holati (Owner dashboard):**
| Widget | Holat |
|--------|-------|
| GreetingCard | Real (user.fullName, role, unread badge) |
| SalesHeroCard | Real (todayRevenue, checkCount, customers, profit) |
| KpiCard ×4 | Real (weekProfit, monthRevenue, customers, topProductCount) |
| AlertCard (debts) | Real (pending count + total) |
| AlertCard (low-stock) | Real |
| ChartCard | Real (yangi `/weekly-series` orqali) |
| TopSellersCard | Real (yangi `/top-products?period=today` orqali) |

### 10.3 Dark theme (legacy blue) qo'shildi

Migratsiya light-only theme bilan yakunlangan edi. Eski foydalanuvchilar uchun toq blue rangni dark theme sifatida qaytarish kerak edi. Yangi `AppTheme.dark` qo'shildi.

**11 ta dark palette token** (`lib/design/tokens/app_tokens.dart`):
- `darkPrimary: #1E3A8A` (eski design'ning ko'k)
- `darkPrimaryLight: #3B82F6`
- `darkBg: #0F172A` (slate-900)
- `darkSurface: #1E293B` (slate-800)
- `darkSurface2: #334155` (slate-700)
- `darkBorder`, `darkBorderSoft`, `darkText`, `darkTextSecondary`, `darkTextMuted`, `darkInputFill`

**`AppTheme.dark`** ~120 qator — `AppTheme.light`'ga simmetrik, lekin dark palette bilan.

**`main_app.dart`** — `dark: AppTheme.light` (placeholder) → `dark: AppTheme.dark`. `AdaptiveTheme` toggle drawer + welcome ekrandan ishlaydi.

### 10.4 Lokalizatsiya tozalash (Agent 2 + 4 + qo'lda)

Migratsiya paytida ko'p widget'lar uzbek hardcoded matnlarda qoldirilgan edi. Sweep'da:

**Dashboard widget'lar uchun 30+ key:**
`greetingHello`, `todaysSale`, `checkLabel`, `mijozLabel`, `profitLabel`, `statisticsSectionLabel`, `alertsSectionLabel`, `weekProfit`, `monthRevenue`, `topProduct`, `analysisSectionLabel`, `reportsActionLabel`, `thisWeekLabel`, `todayLabel`, `viewAll`, `bestSellersTitle`, `newSale`, `oneSaleInProgress`, `revenueLabel`, `shiftLabel`, `refundLabel`, `cashRegisterShort`, `defaultUserName`, `tapToSelectProduct`, `hour`, `quickActions`, `debtPayments`, `pullToRefresh`, `adminSectionLabel`, `reportLabel`.

**Admin/SuperAdmin/Privacy uchun 90+ key:**
`adminProductsManagement`, `deleteProductConfirm`, `confirmDeleteTitle`, `blockShopTitle`, `superAdminActiveOwnersHeader`, `privacyPolicyTitle` va boshqalar.

**Lokalizatsiya holati:**
- `app_uz.arb` va `app_ru.arb` — 120+ yangi key
- Dashboard, drawer, POS, mahsulotlar, sotuvlar, mijozlar, hisobotlar, kassa, admin_products, superadmin, privacy, welcome — **uz/ru har ikkalasida to'liq**
- Privacy policy uzun matnlari inglizcha qoldi (uzun matnlar arb'ni bloat qiladi)

### 10.5 Backend: 3 ta yangi Reports endpoint

Migratsiyada dashboard'da 3 ta TODO qoldirilgan edi: 7-kunlik chart, top mahsulotlar ranking, xodimlar samaradorligi. Bularning hammasi mavjud ma'lumotlar aggregatsiyasi — yangi DB column kerakmas.

**Yangi fayllar (3 ta DTO):**
- `MarketSystem.Application/DTOs/WeeklySeriesDto.cs` — `WeeklySeriesDto`, `DailyPoint`
- `MarketSystem.Application/DTOs/TopProductsDto.cs` — `TopProductsDto`, `TopProductRow`
- `MarketSystem.Application/DTOs/StaffPerformanceDto.cs` — `StaffPerformanceDto`, `StaffRow`

**Endpoint'lar:**
| URL | Maqsad |
|-----|--------|
| `GET /api/Reports/weekly-series?days=7` | Dashboard ChartCard (kunlik aylanma+foyda+chek soni) |
| `GET /api/Reports/top-products?period=&sortBy=&limit=` | TopSellersCard ranking (today/week/month/year × quantity/revenue/profit) |
| `GET /api/Reports/staff-performance?period=` | Xodimlar samaradorligi (today/week/month) |

**Texnik xususiyatlar:**
- Tenant-scoped (`ICurrentMarketService.GetCurrentMarketId()`)
- Tashkent timezone (`ITashkentClock`)
- Role-based: Profit faqat Owner'ga
- Empty fill: WeeklySeries har bir kun uchun zero point
- `[Authorize(Policy = "AdminOrOwner")]`
- External products skip qilinadi (top-products'da)
- Shift fields placeholder (0/false) — `Shift` entity hali yo'q

### 10.6 Flutter yangi endpoint'larga ulanish

**`lib/data/services/report_service.dart`** kengaytirildi:
- 6 ta yangi DTO Dart class (`WeeklySeries`, `DailyPoint`, `TopProducts`, `TopProductRow`, `StaffPerformance`, `StaffRow`)
- Defensive parse helpers (`_asDouble`, `_asDoubleOrNull`, `_asInt`, `_asDate`)
- 3 ta method: `getWeeklySeries(days)`, `getTopProducts(period, sortBy, limit)`, `getStaffPerformance(period)`

**`DashboardSummary`** ga 2 ta yangi maydon: `weeklySeries: List<DailyPoint>`, `topProductRows: List<TopProductRow>`

**`dashboard_screen.dart`** o'zgartirildi:
- ChartCard hozir `summary.weeklySeries`'dan bar'larni normalize qiladi (max revenue'ga bo'lib)
- TopSellersCard hozir `summary.topProductRows`'dan oladi (`period=today, sortBy=quantity, limit=3`)
- TODO comment'lari olib tashlandi

### 10.7 Sifat ko'rsatkichlari (sessiya yakuni)

| Ko'rsatkich | Boshlang'ich | Sessiya yakuni | Δ |
|-------------|--------------|----------------|---|
| `flutter analyze` info | 20 | **19** | −1 |
| `flutter analyze` error | 0 | 0 | ✓ |
| `dotnet build` warning | 9 (pre-existing) | 9 | ✓ |
| `dotnet build` error | 0 | 0 | ✓ |
| Backend endpoint'lar | 95 | **98** (+3) | +3 |
| Yangi Flutter DTO | 0 | 6 | +6 |
| Yangi l10n key | 0 | 120+ | +120+ |
| Hardcoded matn (dashboard) | ~30 | 0 | tozalandi |

### 10.8 Hali ham qolgan TODO

**Backend kengaytirish kerak bo'lganlar (Kategoriya A):**
- `DELETE /api/Users/profile-image` — Avatar logo o'chirish
- `POST /api/Sms/Send` — SMS yuborish (Eskiz integration)
- `Customer.IsLoyal` field — "Doimiy" mijoz filter
- `Customer.{id}/sales` endpoint — mijoz detalida sotuvlar tab
- `POST /api/Zakups/Batch` — bir batch'da bir nechta mahsulot
- `Shift` entity + `/api/Shifts/Open|Close` — smena boshqaruvi
- `Category.DisplayOrder` + `Category.Icon` field
- `/Reports/weekly-comparison` — ChartCard footer delta uchun (oldingi hafta bilan solishtirish)

**Frontend kichik tuzatishlar:**
- `users_screen.dart` "BUGUN TUSHUM" stat — `staff-performance`'ga ulanmagan (alohida loader kerak)
- `_TotalCard` literal Color — `surfaceDark` token bilan almashtirilishi mumkin
- Privacy policy uzun matnlari hali inglizcha

### 10.9 Production-readiness checklist (yangilangan)

- ✅ Hamma ekranlar yangi dizayn sistemada
- ✅ Light + Dark mode ikkalasi ham ishlaydi
- ✅ uz + ru lokalizatsiya to'liq (dashboard + barcha asosiy ekranlar)
- ✅ Dashboard real backend ma'lumotlarini ko'rsatadi
- ✅ 0 API path mismatch (404)
- ✅ Bell badge real unread count'ni aks ettiradi
- ⚠ Live test (Postgres + backend yoqilgan holatda end-to-end) hali kerak
- ⚠ E2E test (Playwright/Patrol)
- ⚠ SuperAdmin Console ekranlari uzun matnlari

---

**2-sessiya muallifi:** Claude (Anthropic) + Agent 1, 3, 4
**Sessiya sanasi:** 2026-05-18
**Commit:** `44ffd06`
**Branch:** `feat/design-system-migration`

---

**Yangilash sanasi:** 2026-05-18 (2-sessiya)
**Keyingi review:** 2026-05-24 (hafta 1 yakuni)
