# 🌐 Backend + Database ngrok ga Deploy

## 🚀 Tezkor Start (Bosqichma-bosqich)

### 1-QADAM: Docker Desktop ni ishga tushiring
- Docker Desktop ni oching
- PostgreSQL container avtomatik yaratiladi

### 2-QADAM: `start-ngrok.bat` ni ishga tushing
```
Double-click: start-ngrok.bat
```

Bu script avtomatik qiladi:
1. ✅ PostgreSQL ni ishga tushiradi (port 3030)
2. ✅ Backend API ni ishga tushiradi (port 5137)
3. ✅ ngrok ni ishga tushiradi (global URL)

### 3-QADAM: ngrok URL ni nusqa oling
ngrok terminalda shunaqa URL ko'rasiz:
```
Forwarding: https://abc-123.ngrok-free.app -> http://localhost:5137
```

Bu URL ni frontend developerga yuboring!

---

## 📱 Frontend Developer uchun Ma'lumot

Frontend developerga shuni yuboring:

```
🌐 API URL: https://abc-123.ngrok-free.app/api

🔐 Test Credentials:
   Email: admin@market.uz
   Password: Admin123!

📚 API Documentation: https://abc-123.ngrok-free.app/swagger

⚠️ Eslatma:
   - Har 2 soatda ngrok URL o'zgaradi (free version)
   - HTTPS enabled
   - CORS already configured
```

---

## 🔧 Flutter Config

Frontend developerga shuni o'zgartirish kerak:

```dart
// lib/core/constants/api_constants.dart

class ApiConstants {
  // ngrok URL (har safar yangilang!)
  static const String baseUrl = 'https://abc-123.ngrok-free.app/api';

  // Yoki local uchun:
  // static const String baseUrl = 'http://localhost:5137/api';

  static const String auth = '/Auth';
  static const String products = '/Products';
  static const String sales = '/Sales';
  // ... qolganlari
}
```

---

## 🛑 To'xtatish

Hammasini to'xtatish uchun:
```
Double-click: stop-ngrok.bat
```

Yoki qo'lda:
- Backend terminal: `Ctrl+C`
- ngrok terminal: `Ctrl+C`
- PostgreSQL (ixtiyoriy): `docker stop market-postgres`

---

## ⚠️ Muhim Eslatmalar

### ngrok Limitations (Free Version):
- ❌ URL har 2 soatda o'zgaradi
- ❌ 1 ta tunnel bir vaqtda
- ✅ 2 soatdan keyin qayta ishga tushirish kifoya
- ✅ Cheksiz bandwidth

### Backend Port:
- **Local:** http://localhost:5137
- **ngrok:** https://xxx.ngrok-free.app
- **Swagger:** http://localhost:5137/swagger

### Database:
- **Type:** PostgreSQL 16
- **Port:** 3030
- **Database:** MarketSystemDB
- **User:** postgres
- **Password:** postgres

---

## 🧪 Test qilish

### 1. Health Check
```bash
curl https://abc-123.ngrok-free.app/health
```

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2026-02-24T10:00:00Z"
}
```

### 2. Login Test
```bash
curl -X POST https://abc-123.ngrok-free.app/api/Auth/Login ^
  -H "Content-Type: application/json" ^
  -d "{\"email\":\"admin@market.uz\",\"password\":\"Admin123!\"}"
```

---

## 🔥 Troubleshooting

### Backend ishga tushmaydi?
```
❌ "Failed to connect to database"

✅ Yechim:
   1. Docker Desktop ishlayaptimi?
   2. PostgreSQL container ishlayaptimi?
      docker ps | findstr postgres
   3. Port 3030 band emasmi?
      netstat -ano | findstr 3030
```

### ngrok topilmadi?
```
❌ "ngrok command not found"

✅ Yechim:
   1. https://ngrok.com/download dan yuklang
   2. ngrok.exe ni shu papkaga qo'ying
   3. Yoki PATH ga qo'shing
```

### Frontend ulana olmaydi?
```
❌ "Network request failed"

✅ Yechim:
   1. ngrok URL to'g'ri yozilganmi?
   2. /api suffix borligiga ishonch hosil qiling
   3. CORS xatolik bo'lsa, backend loglarini tekshiring
```

---

## 📊 Backend Dashboard

Backend ishga tushgach quyidagilarga kirishingiz mumkin:

- **Swagger UI:** http://localhost:5137/swagger
- **Health Check:** http://localhost:5137/health
- **API Base URL:** http://localhost:5137/api

---

## 🎯 Production uchun

ngrok faqat **test** uchun! Production uchun:
- ✅ Render.com (free tier)
- ✅ Railway.app ($5 free credit)
- ✅ Azure App Service
- ✅ VPS server

---

## 💡 Tezkor Qo'llanma

| Amal | Buyruq |
|------|--------|
| Start | `start-ngrok.bat` |
| Stop | `stop-ngrok.bat` |
| Backend status | `curl http://localhost:5137/health` |
| PostgreSQL status | `docker ps \| findstr postgres` |
| ngrok status | ngrok terminalni ko'ring |

---

## 📞 Yordam

Muammo bo'lsa:
1. Backend loglarini ko'ring (terminal 1)
2. ngrok loglarini ko'ring (terminal 2)
3. Browserda http://localhost:5137/swagger ochib ko'ring

---

**Muvaffaqiyatlar! 🚀**
