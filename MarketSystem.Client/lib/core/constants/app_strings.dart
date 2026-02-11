/// App Strings Constants
/// Centralized string constants for the app
library;

/// App name and info
class AppStrings {
  static const String appName = 'Market System';
  static const String appVersion = '1.0.0';

  // Authentication
  static const String login = 'Tizimga kirish';
  static const String register = 'Ro\'yxatdan o\'tish';
  static const String logout = 'Chiqish';
  static const String email = 'Email';
  static const String password = 'Parol';
  static const String confirmPassword = 'Parolni tasdiqlash';
  static const String forgotPassword = 'Parolni unutdingizmi?';
  static const String loginSuccess = 'Tizimga muvaffaqiyatli kirdingiz';
  static const String registerSuccess = 'Muvaffaqiyatli ro\'yxatdan o\'tdingiz';
  static const String logoutSuccess = 'Tizimdan muvaffaqiyatli chiqdingiz';

  // Dashboard
  static const String dashboard = 'Bosh sahifa';
  static const String home = 'Bosh sahifa';
  static const String settings = 'Sozlamalar';
  static const String profile = 'Profil';

  // Products
  static const String products = 'Mahsulotlar';
  static const String productName = 'Mahsulot nomi';
  static const String productPrice = 'Mahsulot narxi';
  static const String productQuantity = 'Mahsulot miqdori';
  static const String addProduct = 'Mahsulot qo\'shish';
  static const String editProduct = 'Mahsulotni tahrirlash';
  static const String deleteProduct = 'Mahsulotni o\'chirish';
  static const String productAdded = 'Mahsulot muvaffaqiyatli qo\'shildi';
  static const String productUpdated = 'Mahsulot muvaffaqiyatli yangilandi';
  static const String productDeleted = 'Mahsulot muvaffaqiyatli o\'chirildi';

  // Sales
  static const String sales = 'Sotuvlar';
  static const String newSale = 'Yangi sotuv';
  static const String saleTotal = 'Jami summa';
  static const String saleDiscount = 'Chegirma';
  static const String saleCompleted = 'Sotuv muvaffaqiyatli yakunlandi';
  static const String saleCancelled = 'Sotuv bekor qilindi';

  // Customers
  static const String customers = 'Mijozlar';
  static const String addCustomer = 'Mijoz qo\'shish';
  static const String customerName = 'Mijoz nomi';
  static const String customerPhone = 'Telefon raqami';
  static const String customerAdded = 'Mijoz muvaffaqiyatli qo\'shildi';

  // Debts
  static const String debts = 'Qarzdorlik';
  static const String totalDebt = 'Jami qarz';
  static const String paidDebt = 'To\'langan';
  static const String unpaidDebt = 'To\'lanmagan';

  // Reports
  static const String reports = 'Hisobotlar';
  static const String dailyReport = 'Kunlik hisobot';
  static const String monthlyReport = 'Oylik hisobot';
  static const String salesReport = 'Sotuv hisoboti';
  static const String profitReport = 'Foyda hisoboti';

  // Common
  static const String save = 'Saqlash';
  static const String cancel = 'Bekor qilish';
  static const String delete = 'O\'chirish';
  static const String edit = 'Tahrirlash';
  static const String search = 'Qidirish';
  static const String filter = 'Filter';
  static const String sort = 'Saralash';
  static const String refresh = 'Yangilash';
  static const String loadMore = 'Ko\'proq yuklash';
  static const String noData = 'Ma\'lumot yo\'q';
  static const String loading = 'Yuklanmoqda...';
  static const String error = 'Xatolik yuz berdi';
  static const String success = 'Muvaffaqiyatli';
  static const String warning = 'Ogohlantirish';
  static const String confirm = 'Tasdiqlash';
  static const String yes = 'Ha';
  static const String no = 'Yo\'q';
  static const String ok = 'OK';

  // Error messages
  static const String errorInternet = 'Internet bilan aloqa yo\'q';
  static const String errorServer = 'Server xatosi';
  static const String errorAuth = 'Autentifikatsiya xatosi';
  static const String errorPermission = 'Ruxsat yo\'q';
  static const String errorNotFound = 'Ma\'lumot topilmadi';
  static const String errorValidation = 'Ma\'lumotlarni to\'g\'ri kiriting';
  static const String errorUnknown = 'Noma\'lum xatolik';

  // Menu items
  static const String menuDashboard = 'Bosh sahifa';
  static const String menuProducts = 'Mahsulotlar';
  static const String menuSales = 'Sotuvlar';
  static const String menuCustomers = 'Mijozlar';
  static const String menuZakup = 'Xaridlar';
  static const String menuReports = 'Hisobotlar';
  static const String menuDebts = 'Qarzdorlik';
  static const String menuUsers = 'Foydalanuvchilar';
  static const String menuAdminProducts = 'Admin: Mahsulotlar';
}
