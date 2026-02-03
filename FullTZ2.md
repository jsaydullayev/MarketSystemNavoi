# MarketSystem – Full Technical Specification (TZ)

## 1. Project Overview

MarketSystem – bu market(lar) uchun mo‘ljallangan markazlashgan savdo va sklad boshqaruv tizimi. Tizim real vaqt rejimida savdolarni, sklad qoldiqlarini, foydani, qarzlarni va to‘lovlarni nazorat qiladi.

Platformalar:

- Desktop (Windows)
- Android, IOS

Arxitektura:

- Backend: ASP.NET Core (Web API)
- Frontend: Android, IOS (bitta backend)
- Database: PostgreSQL

---

## 2. Domain Glossary

- **Product** – sotiladigan tovar
- **Zakup** – tovarning kelish jarayoni (faqat admin)
- **Sale** – bitta sotuv operatsiyasi
- **SaleItem** – sotuvdagi alohida tovar
- **Debt** – to‘liq yopilmagan sotuv
- **Mix Payment** – bir sotuvda bir nechta to‘lov turi
- **Branch** – market filiali
- **Seller** – sotuvchi
- **Owner** – tizim egasi

---

## 3. Roles & Permissions

### 3.1 Roles

- Owner
- Admin
- Seller

### 3.2 Permission Matrix

| Action                       | Owner | Admin | Seller             |
| ---------------------------- | ----- | ----- | ------------------ |
| Zakup qilish                 | ✅    | ✅    | ❌                 |
| Product qo‘shish (temporary) | ❌    | ❌    | ✅                 |
| Sale qilish                  | ❌    | ❌    | ✅                 |
| Sale o‘chirish               | ❌    | ✅    | ❌                 |
| Past narxda sotish           | ❌    | ❌    | ✅ (comment bilan) |
| Hisobot ko‘rish              | ✅    | ✅    | ❌                 |
| Threshold sozlash            | ❌    | ✅    | ❌                 |

---

## 4. Database Entities (Detailed)

### 4.1 Customer

Mijoz qarz va sotuvlarni bog‘lash uchun kerak.

- Id (UUID)
- Phone (string, unique, nullable=false)
- FullName (string, nullable=true)
- CreatedAt (datetime)
- IsDeleted (bool)

### 4.2 User

- Id (UUID)
- FullName
- Username
- PasswordHash
- Role (Owner/Admin/Seller)
- IsActive

### 4.3 Product

- Id
- Name
- IsTemporary (bool)
- CreatedBySellerId (nullable)

**Izoh:** Narxlar Product’da emas, faqat BranchProduct’da saqlanadi.
Temporary product yaratilganda seller BranchProduct orqali CostPrice, SalePrice, MinSalePrice kiritadi.

- Id
- Name
- IsTemporary (bool)
- CreatedBySellerId (nullable)

### 4.5 Sale

- Id
- BranchId
- SellerId
- CustomerId (nullable)
- Status (Draft/Paid/Debt/Closed/Cancelled)
- TotalAmount
- PaidAmount
- CreatedAt

### 4.6 SaleItem

- Id
- SaleId
- ProductId
- Quantity
- CostPrice
- SalePrice
- Comment (nullable)

### 4.7 Payment

- Id
- SaleId
- PaymentType (Cash/Terminal/Transfer)
- Amount
- CreatedAt

### 4.8 Debt

- Id
- SaleId
- CustomerId
- TotalDebt
- RemainingDebt
- Status (Open/Closed)

### 4.9 Zakup

- Id
- ProductId
- Quantity
- CostPrice
- CreatedByAdminId
- CreatedAt

### 4.10 AuditLog

- Id
- EntityType
- EntityId
- Action
- UserId
- Payload (JSON)
- CreatedAt

---

## 5. Sale Lifecycle (State Machine)

### 5.1 Sale Statuses

- Draft
- Paid
- Debt
- Closed
- Cancelled

### 5.2 State Transitions

| From  | To        | Trigger         | Handler           |
| ----- | --------- | --------------- | ----------------- |
| Draft | Paid      | 100% payment    | PaymentHandler    |
| Draft | Debt      | Partial payment | DebtHandler       |
| Debt  | Closed    | Full payment    | DebtCloseHandler  |
| Any   | Cancelled | Admin action    | SaleCancelHandler |

---

## 6. Business Rules

### 6.1 Pricing Rules

- Product har doim `cost_price`, `sale_price`, `min_sale_price` ga ega
- Agar `sale_price < min_sale_price`:
    - Comment REQUIRED
    - UI’da sariq rangda belgilanadi

### 6.2 Profit Formula

```text
ItemProfit = (SalePrice - CostPrice) * Quantity
SaleProfit = SUM(ItemProfit)
```

### 6.3 Stock Rules

- Quantity manfiy bo‘lishi taqiqlanadi
- Stock update faqat transaction ichida
- Qaytarilgan tovar skladda qayta qo‘shiladi

---

## 7. Payment Logic

### 7.1 Payment Types

- Cash
- Terminal
- Transfer

**Note:** Debt payment type mavjud emas. Debt — bu Sale holati (status).

**Note:** Debt payment type mavjud emas. Debt — bu Sale holati (status).

- Cash
- Terminal
- Transfer
- Debt

### 7.2 Mix Payment

- Bir sale’da bir nechta payment bo‘lishi mumkin
- Payment summalar yig‘indisi `total_amount` ga teng bo‘lishi shart
- Qisman to‘lov bo‘lsa → Debt ochiladi

---

## 8. Debt Logic

- Bitta mijozda bir nechta debt bo‘lishi mumkin
- Debt Sale bilan bog‘langan bo‘ladi
- Agar Payment yig‘indisi TotalAmount dan kam bo‘lsa:
    - Sale.Status = Debt
    - Debt yozuvi yaratiladi
- Debt to‘liq yopilganda:
    - RemainingDebt = 0
    - Debt.Status = Closed
    - Sale.Status = Closed

## 9. Zakup Logic

- Zakup faqat Admin tomonidan amalga oshiriladi
- Zakup alohida Zakup table’da tarix sifatida saqlanadi
- Zakup vaqtida:
    - SalePrice va MinSalePrice **ixtiyoriy**, admin xohishiga ko‘ra yangilanadi

---

## 10. Stock Threshold & Notification

- Har bir product uchun min_threshold admin tomonidan belgilanadi
- Quantity <= MinThreshold bo‘lsa:
    - UI’da qizil rang bilan belgilanadi
    - Sotish ruxsat etiladi, lekin warning chiqariladi
- Threshold qiymatini faqat Admin o‘zgartira oladi
- Barcha userlar ko‘ra oladi

## 11. Real-Time Visibility

**"Spiska" taʼrifi:** bu sotuvchining **Active Draft Sale (cart)** holatidagi savdosi.

Real-time ko‘rinadigan maʼlumotlar:

- Seller
- Draft Sale ID
- SaleItem ro‘yxati (Product, Quantity)
- Jami summa

Cheklovlar:

- Boshqa sotuvchilar faqat ko‘rishi mumkin (read-only)
- O‘zgartirish taqiqlanadi

Texnologiya: **SignalR (WebSockets asosida)**

---

## 12. Reports & Analytics

### 12.1 Hisobotlar

1. Sotilgan tovarlar umumiy summasi
2. Zakup summasi
3. Profit
4. Sof daromad

### 12.2 Export

- Ekranda ko‘rish
- Excel formatda yuklab olish

---

## 13. Delete & History Policy

- Soft delete (`IsDeleted = true`)
- Tarix 1 oy saqlanadi

---

## 14. Handlers (Core Logic)

### 14.1 SaleCreateHandler

- Validation
- Stock check
- Sale & SaleItem create

### 14.2 PaymentHandler

- Payment create
- Sale status update

### 14.3 DebtHandler

- Debt create/update
- Status control

### 14.4 StockUpdateHandler

- Atomic stock update
- Rollback on error

---

## 15. Logging & Audit

### 15.1 AuditLog

Har bir muhim event yoziladi:

- Sale create/update/delete
- Payment create
- Debt close
- Zakup create

Log fields:

- EntityType
- EntityId
- Action
- UserId
- Payload (JSON)
- CreatedAt

### 15.2 Log Levels

- Info – normal flow
- Warning – validation bypass (past narx, threshold)
- Error – transaction failure

## 16. Non-Functional Requirements

- Internet orqali ishlaydi
- Transactional consistency
- Optimistic concurrency control (RowVersion)
- SignalR real-time communication
- JWT-based authentication
- Production-level logging

## 17. Acceptance Criteria (Summary)

- ❌ Negative stock bo‘lmasligi kerak
- ❌ Comment’siz past narxga sotish bo‘lmasligi kerak
- ✅ Mix payment to‘g‘ri ishlashi
- ✅ Debt lifecycle to‘liq ishlashi
- ✅ Real-time Draft Sale ko‘rinishi ishlashi
- ✅ Excel export ishlashi
- ✅ Sale cancel bo‘lsa, stock qayta tiklanadi
- ⚠️ Quantity <= MinThreshold bo‘lsa sotish **ruxsat**, lekin warning beriladi
- Draft status: Seller savdoni Draft sifatida boshlaydi

---
