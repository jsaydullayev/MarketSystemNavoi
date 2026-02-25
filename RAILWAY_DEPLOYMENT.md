# Railway Deployment Guide - MarketSystem API

## 🚀 Railway'ga Deploy Qilish

### 1. Railway CLI ni o'rnatish

```bash
npm install -g @railway/cli
```

### 2. Railway'ga login

```bash
railway login
```

### 3. Yangi project yaratish

```bash
railway init
```

Yoki Railway dashboard orqali: https://railway.app/new

### 4. PostgreSQL Database qo'shish

Railway dashboardda:
1. **New Service** → **Database** → **PostgreSQL**
2. Database yaratilgach, **Variables** tab'ga o'ting
3. `DATABASE_URL` ni ko'ring (o'rniga `DefaultConnection` ishlatamiz)

### 5. Environment Variables sozlash

Railway dashboardda **Variables** tab'iga quyidagilarni qo'shing:

```bash
# Database Connection (Railway automatic qiymat beradi)
DATABASE_URL=<Railway自动提供>

# Lekin biz 'DefaultConnection' ishlatamiz
ConnectionStrings__DefaultConnection=${DATABASE_URL}

# JWT Secret Key (must be 32+ characters)
Jwt__Key=YOUR_SUPER_SECRET_KEY_THAT_IS_AT_LEAST_32_CHARACTERS_LONG_FOR_RAILWAY_PRODUCTION
Jwt__Issuer=MarketSystemAPI
Jwt__Audience=MarketSystemClient
Jwt__AccessTokenExpireHours=14
Jwt__RefreshTokenDays=5

# Environment
ASPNETCORE_ENVIRONMENT=Production
ASPNETCORE_URLS=http://+:8080
PORT=8080
```

### 6. Deploy qilish

```bash
# Link existing project
railway link

# Deploy
railway up
```

Yoriq: Railway'ga GitHub repository qo'shsangiz, har bir push'da automatic deploy bo'ladi.

### 7. Database Migration

Automatic migration ishlaydi (Program.cs da sozlangan). Birinchi deploy'dan keyin:

1. Railway logs'ni tekshiring:
   ```bash
   railway logs
   ```

2. "Database migrations applied successfully" degan xabarni kutishingiz kerak

3. Seed data uchun API'ni chaqiring:
   ```bash
   # Railway URL'ingizni oling
   railway domain

   # Seed endpoint (Production'da o'chirilgan)
   # Agar kerak bo'lsa, Production'da ham yoqish uchun Program.cs ni o'zgartiring
   curl https://your-app.railway.app/seed
   ```

### 8. Frontend (Flutter) URL yangilash

`MarketSystem.Client/lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  // Development
  static const String baseUrl = 'http://localhost:5137/api';

  // Production (Railway) - deploy'dan keyin yangilang
  // static const String baseUrl = 'https://your-app.railway.app/api';
}
```

## 📋 Deploy Checklist

- [ ] Railway project yaratildi
- [ ] PostgreSQL database qo'shildi
- [ ] Environment variables sozlandi:
  - [ ] `ConnectionStrings__DefaultConnection`
  - [ ] `Jwt__Key` (32+ characters)
  - [ ] `Jwt__Issuer`, `Jwt__Audience`
  - [ ] `ASPNETCORE_ENVIRONMENT=Production`
- [ ] Dockerfile va railway.json bor
- [ ] .dockerignore Dockerfile'ni ignore qilmaydi
- [ ] CORS settings Railway domaininga mos
- [ ] Health check endpoint ishlaydi (`/health`)
- [ ] Database migration muvaffaqiyatli bo'ldi
- [ ] Frontend URL yangilandi

## 🔧 Troubleshooting

### Database connection error

Railway Variables'da `DATABASE_URL` va `ConnectionStrings__DefaultConnection` bir xil ekanligini tekshiring.

### JWT Token error

`Jwt__Key` kamida 32 ta belgidan iborat bo'lishi kerak.

### CORS error

Production CORS policy'ni tekshiring - Railway `.railway.app` domainlariga ruxsat berishi kerak.

### Health check failed

Application 8080 portda tinglashi kerak. `PORT=8080` environment variable borligini tekshiring.

## 📊 Monitoring

Railway dashboardda:
- **Metrics**: CPU, Memory usage
- **Logs**: Application logs
- **Deploys**: Deploy history
- **Settings**: Environment variables

## 🔄 Continuous Deployment

GitHub repository qo'shib, automatic deploy yoqish:

1. Railway Dashboard → Project
2. **New Service** → **Deploy from GitHub repo**
3. Repository tanlang
4. Branch tanlang (masalan, `main` yoki `master`)
5. Root path: `/`
6. Dockerfile path: `Dockerfile`

Endi har commit'da automatic deploy bo'ladi! 🎉
