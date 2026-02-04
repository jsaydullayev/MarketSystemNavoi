# Market System Client (Flutter)

## Backend API bilan bog'lash

Flutter app Backend API ga ulanishi uchun:

### 1. Backend API manzilini sozlash:

[lib/core/constants/api_constants.dart](lib/core/constants/api_constants.dart) faylida:
```dart
static const String baseUrl = 'http://localhost:5000/api';
```

O'zgartiring:
- **Development uchun:** `http://localhost:5000/api`
- **Real device uchun:** `http://YOUR_PC_IP:5000/api` (masalan: `http://192.168.1.100:5000/api`)
- **Production uchun:** `https://your-api.com/api`

### 2. Flutter proyektini ishga tushirish:

```bash
# Proyektga o'ting
cd MarketSystem.Client

# Dependencies larni o'rnatish
flutter pub get

# Ios uchun (agar mac'book bo'lsa)
cd ios && pod install && cd ..

# Run
flutter run
```

## Proyekt strukturas:

```
lib/
├── main.dart                     # App kirish qismi
├── core/
│   └── constants/
│       └── api_constants.dart    # API manzillari
├── data/
│   └── services/
│       ├── http_service.dart     # HTTP so'rovlari
│       └── auth_service.dart     # Auth servisi
└── features/
    └── auth/
        └── screens/
            └── login_screen.dart # Login ekrani
```

## Keyingi qadamlar:

1. ✅ Backend API ni ishga tushing
2. ✅ Flutter proyektini oching VS Code da
3. ✅ `flutter pub get` bajaring
4. ✅ `flutter run` bajaring
5. ✅ Login ekrani ko'rinadi

## API endpoints:
- POST `/api/auth/login` - Login
- POST `/api/auth/register` - Register
- GET `/api/products/getall` - Productlar
- GET `/api/customers/getall` - Mijozlar
- va hokazo...

Backend API ishga tushgan bo'lsa, Flutter app ulanadi!
