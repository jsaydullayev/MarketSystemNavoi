# STROTECH.UZ Web Server Configuration

Bu fayllar Flutter Web ilovangizni professional va xavfsiz tarzda joylashtirish uchun kerak.

## Flutter o'zgarishlari

### 1. Clean URLs yoqilgan (`usePathUrlStrategy`)
- Endi URL `/sales` ko'rinishida bo'ladi (hash `#/sales` emas)
- `lib/main.dart`da qo'shilgan

### 2. Route Guardlar qo'shilgan
- `lib/core/routes/route_guard.dart` - Auth va role asosidaga himoya
- `lib/core/routes/auth_route_guard.dart` - Widget-based himoya

## Qaysi serverni ishlatish?

| Server | Tavsiya | Murakkablik | Tezlik |
|--------|---------|-------------|--------|
| Nginx | ✅ Eng yaxshi | O'rtacha | Juda yuqori |
| Firebase Hosting | ✅ Oson | Juda oson | Yuqori (CDN) |
| Apache | ❌ Kam tavsiya | O'rtacha | O'rtacha |

## Nginx deployment (Eng yaxshi variant)

### 1. Build Flutter web
```bash
flutter build web --release
```

### 2. Fayllarni serverga ko'chirish
```bash
scp -r build/web/* user@strotech.uz:/var/www/strotech.uz/
```

### 3. Nginx config ni qo'yish
```bash
sudo cp nginx.conf /etc/nginx/sites-available/strotech.uz
sudo ln -s /etc/nginx/sites-available/strotech.uz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 4. SSL sertifikat olish (HTTPS)
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d strotech.uz -d www.strotech.uz
```

## Firebase Hosting (Eng oson variant)

### 1. Build
```bash
flutter build web --release
```

### 2. Firebase CLI o'rnatish
```bash
npm install -g firebase-tools
firebase login
```

### 3. Init va deploy
```bash
firebase init hosting
# Config ni `firebase.json`dan foydalanish
firebase deploy
```

## Xavfsizlik xususiyatlari

### Security Headers
- `X-Frame-Options: SAMEORIGIN` - Clickjackingdan himoya
- `X-Content-Type-Options: nosniff` - MIME type sniffingdan himoya
- `X-XSS-Protection: 1; mode=block` - XSS himoyasi
- `Referrer-Policy: strict-origin-when-cross-origin` - Privacy
- `Permissions-Policy: ...` - API kirishini cheklash

### SSL/TLS
- TLS 1.2 va 1.3 faqat
- Strong ciphers
- HSTS yoqilgan

### Boshqa
- Directory listing o'chirilgan
- Hidden fayllarga kirish taqiqlangan
- Gzip compression yoqilgan
- Static caching

## Route Guard ishlatish

### Muhim: Route generator'da himoya ishlamaydi!
Provider context route_generator'da mavjud emas, shuning uchun:
- Route generator'da auth check qilib bo'lmaydi
- Har bir protected screen'ni alohida himoya qilish kerak

### 1. ProtectedRoute widget bilan (Admin/Owner sahifalar uchun)
```dart
// lib/features/admin_products/screens/admin_products_screen.dart
class AdminProductsScreen extends StatelessWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
      allowedRoles: ['Admin', 'Owner'],
      child: _AdminProductsContent(), // Asl content
    );
  }
}
```

### 2. AuthRouteGuard bilan (Oddiy auth sahifalar uchun)
```dart
// lib/features/sales/presentation/screens/sales_screen.dart
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthRouteGuard(
      child: _SalesContent(), // Asl content
    );
  }
}
```

### 3. Yoki dashboard'dan navigatsiya qilganda
```dart
// dashboard_screen.dart
onTap: () => Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ProtectedRoute(
      allowedRoles: ['Admin', 'Owner'],
      child: const UsersScreen(),
    ),
  ),
)
```

## Muhim eslatmalar

1. **Route generator**dan context olish qiyin, shuning uchun widget-based yondashuvdan foydalaning
2. Web build va deploydan keyin browser cache'ni tozalash kerak bo'lishi mumkin
3. Productionda albatta HTTPS ishlating
4. Backend API'ga proxy qo'yish kerak bo'lishi mumkin (CORS muammosi uchun)

## URL tuzilishi

```
strotech.uz/           -> Dashboard (Authenticated)
strotech.uz/login      -> Login (Public)
strotech.uz/sales      -> Sales (Authenticated)
strotech.uz/products   -> Products (Authenticated)
strotech.uz/users      -> Users (Admin/Owner only)
strotech.uz/admin-products -> Admin Products (Admin/Owner only)
```

## Masalalar va yechimlar

### URL ishlamayapti
- Web server config'ni tekshiring (try_files / RewriteRule)
- `usePathUrlStrategy()` main.dartda borligini tekshiring

### Auth ishlamayapti
- AuthProvider to'g'ri config qilinganligini tekshiring
- Har bir protected screen'da ProtectedRoute widgetidan foydalaning
- Dashboard'da `Navigator.push` bilan o'tganda ham ProtectedRoute ishlatish

### Role-based himoya ishlamayapti
- `AuthProvider.user['role']` to'g'ri qiymat qaytarishini tekshiring
- `allowedRoles` massivida role nomi to'g'ri ekanini tekshiring ('Admin', 'Owner', 'Seller')

### SSL sertifikati
- `certbot`dan foydalaning (bepul Let's Encrypt)
- Har 90 kunda auto-renew bo'ladi

---

## CHEGARA VA XATOLAR

### Route generator'da auth ishlamaydi
Flutter-da route_generator'da Provider context mavjud emas. Shuning uchun:
- ❌ `generateRoute` ichida auth check qilib bo'lmaydi
- ✅ Har bir protected screen'ni `ProtectedRoute` bilan wrap qilish kerak

### Direct URL kiritish
Foydalanuvchi browserga `/users` kiritganda:
- Agar user login bo'lmasa: LoginScreen ko'rsatiladi
- Agar login bo'lsa lekin role yo'qsa: Dashboard'ga redirect bo'ladi + error message

### Post-login redirect
Login bo'lgandan keyin user orqaga qaytmaydi. Bu normal, chunki:
- Flutter Web SPA (Single Page Application)
- URL state saqlash uchun qo'shimcha kod kerak (future improvement)
