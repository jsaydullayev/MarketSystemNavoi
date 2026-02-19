# Market System Client - Yangi Struktura

## Project Overview

Bu Flutter projecti **strotech** strukturasiga asoslangan holda qayta tashkillashtirildi.

## Yangi Struktura

```
MarketSystem.Client/lib/
├── core/                           # CORE INFRASTRUCTURE
│   ├── app/
│   │   └── main_app.dart          # Main app widget
│   ├── constants/
│   │   ├── api_constants.dart
│   │   ├── app_strings.dart         # App string constants
│   │   └── app_colors.dart          # App color constants
│   ├── extensions/                   # Dart extensions (future)
│   ├── failure/
│   │   └── failures.dart           # Error/failure models
│   ├── handlers/                     # 🎯 HANDLERS
│   │   ├── network_handler.dart      # Network operations handler
│   │   ├── auth_handler.dart         # Auth operations handler
│   │   ├── storage_handler.dart      # Local storage handler
│   │   └── navigation_handler.dart   # Navigation handler
│   ├── interceptor/
│   │   ├── api_interceptor.dart     # API request/response interceptor
│   │   └── error_interceptor.dart   # Error handling interceptor
│   ├── mapper/                       # Data mappers (future)
│   ├── network/                      # Network layer (future)
│   ├── routes/
│   │   ├── app_routes.dart          # Route constants
│   │   └── route_generator.dart     # Route generator
│   ├── theme/
│   │   └── app_theme.dart          # App theming
│   ├── utils/
│   │   ├── di.dart                  # Dependency Injection setup
│   │   └── validators.dart          # Input validators (future)
│   └── widgets/                      # Common widgets (future)
│
├── features/                       # FEATURE MODULES (Clean Architecture)
│   ├── auth/                       # 📱 AUTH FEATURE
│   │   ├── data/                   # Data layer
│   │   │   ├── models/
│   │   │   ├── repositories/
│   │   │   └── sources/
│   │   ├── domain/                 # Domain layer
│   │   │   ├── entities/           # Domain entities
│   │   │   ├── repositories/       # Repository interfaces
│   │   │   └── usecases/          # Business logic use cases
│   │   └── presentation/           # Presentation layer
│   │       ├── bloc/               # BLoC state management (future)
│   │       ├── pages/              # Screen pages
│   │       └── widgets/            # Feature widgets
│   │
│   ├── products/                   # 📦 PRODUCTS FEATURE (future)
│   ├── sales/                      # 💰 SALES FEATURE (future)
│   ├── customers/                  # 👥 CUSTOMERS FEATURE (future)
│   ├── zakup/                      # 🛒 ZAKUP FEATURE (future)
│   ├── reports/                    # 📊 REPORTS FEATURE (future)
│   └── ... (boshqa features)
│
├── platform_handlers/              # 🎯 PLATFORM-SPECIFIC HANDLERS
│   ├── android/
│   │   ├── android_handler.dart      # Android-specific operations
│   │   ├── permission_handler.dart   # Android permissions
│   │   └── notification_handler.dart # Android notifications
│   ├── ios/
│   │   ├── ios_handler.dart         # iOS-specific operations
│   │   ├── permission_handler.dart   # iOS permissions
│   │   └── notification_handler.dart
│   ├── web/
│   │   ├── web_handler.dart         # Web-specific operations
│   │   ├── url_handler.dart         # Web URL handling
│   │   └── storage_handler.dart    # Web storage
│   ├── windows/
│   │   ├── windows_handler.dart     # Windows-specific operations
│   │   ├── file_handler.dart        # Windows file system
│   │   └── registry_handler.dart    # Windows registry
│   └── platform_interface.dart     # Common interface for all platforms
│
├── config/                         # Configuration files (future)
├── l10n/                           # Localization
└── main.dart                       # App entry point
```

## Asosiy O'zgarishlar

### 1. Platform Handlers
- Har bir platform (Android, iOS, Web, Windows) uchun alohida handlerlar
- Platform interface orqali umumiy contract
- Har bir platformning o'ziga xos hususiyatlariga mos kodlar

### 2. Core Handlers
- **NetworkHandler**: Dio asosida HTTP so'rovlarni boshqarish
- **AuthHandler**: Token va autentifikatsiyani boshqarish
- **StorageHandler**: Lokal xotirani boshqarish
- **NavigationHandler**: Navigatsiyani boshqarish

### 3. Clean Architecture
Har bir feature moduli uch qatlam:
- **Data Layer**: Models, Repositories implementation, Data sources
- **Domain Layer**: Entities, Repository interfaces, Use cases
- **Presentation Layer**: BLoC, Pages, Widgets

### 4. Dependency Injection
- `get_it` package using
- `setupDependencyInjection()` function
- Barcha services singletons sifatida ro'yxatga olingan

## Keyinchi Qadam

1. ✅ Platform handlers yaratildi
2. ✅ Core handlers yaratildi
3. ✅ Interceptorlar yaratildi
4. ✅ Routes yaratildi
5. ✅ DI setup yaratildi
6. 🔄 Feature modullarini qayta tashkillashtirish (jarayonmoqda)

## TODO

- [ ] Barcha feature modullarini Clean Architecture bo'yicha qayta tashkillashtirish
- [ ] BLoC state management qo'shish
- [ ] Use cases yaratish
- [ ] Repository implementations yaratish
- [ ] Data sources yaratish
- [ ] Mapperlar yaratish
- [ ] main.dart ni DI bilan yangilash
