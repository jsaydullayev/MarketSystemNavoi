import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('uz')
  ];

  /// No description provided for @appTitle.
  ///
  /// In uz, this message translates to:
  /// **'Market Tizimi'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In uz, this message translates to:
  /// **'Tizimga kirish'**
  String get login;

  /// No description provided for @register.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish'**
  String get register;

  /// No description provided for @username.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi nomi'**
  String get username;

  /// No description provided for @password.
  ///
  /// In uz, this message translates to:
  /// **'Parol'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In uz, this message translates to:
  /// **'To\'liq ism'**
  String get fullName;

  /// No description provided for @role.
  ///
  /// In uz, this message translates to:
  /// **'Rol'**
  String get role;

  /// No description provided for @language.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Tilni tanlang'**
  String get selectLanguage;

  /// No description provided for @uzbek.
  ///
  /// In uz, this message translates to:
  /// **'O\'zbek tili'**
  String get uzbek;

  /// No description provided for @russian.
  ///
  /// In uz, this message translates to:
  /// **'Rus tili'**
  String get russian;

  /// No description provided for @logout.
  ///
  /// In uz, this message translates to:
  /// **'Tizimdan chiqish'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Rostdan ham tizimdan chiqmoqchimisiz?'**
  String get logoutConfirm;

  /// No description provided for @yes.
  ///
  /// In uz, this message translates to:
  /// **'Ha'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'q'**
  String get no;

  /// No description provided for @dashboard.
  ///
  /// In uz, this message translates to:
  /// **'Boshqaruv paneli'**
  String get dashboard;

  /// No description provided for @profile.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @products.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar'**
  String get products;

  /// No description provided for @sales.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvlar'**
  String get sales;

  /// No description provided for @customers.
  ///
  /// In uz, this message translates to:
  /// **'Mijozlar'**
  String get customers;

  /// No description provided for @zakup.
  ///
  /// In uz, this message translates to:
  /// **'Xaridlar'**
  String get zakup;

  /// No description provided for @reports.
  ///
  /// In uz, this message translates to:
  /// **'Hisobotlar'**
  String get reports;

  /// No description provided for @debts.
  ///
  /// In uz, this message translates to:
  /// **'Qarzdorlik'**
  String get debts;

  /// No description provided for @users.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilar'**
  String get users;

  /// No description provided for @adminProducts.
  ///
  /// In uz, this message translates to:
  /// **'Admin: Mahsulotlar'**
  String get adminProducts;

  /// No description provided for @productList.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar ro\'yxati'**
  String get productList;

  /// No description provided for @productManagement.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlarni boshqarish'**
  String get productManagement;

  /// No description provided for @salesHistory.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvlar tarixi'**
  String get salesHistory;

  /// No description provided for @customerList.
  ///
  /// In uz, this message translates to:
  /// **'Mijozlar ro\'yxati'**
  String get customerList;

  /// No description provided for @purchaseHistory.
  ///
  /// In uz, this message translates to:
  /// **'Xaridlar tarixi'**
  String get purchaseHistory;

  /// No description provided for @productPurchases.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot xaridlari'**
  String get productPurchases;

  /// No description provided for @systemReports.
  ///
  /// In uz, this message translates to:
  /// **'Tizim hisobotlari'**
  String get systemReports;

  /// No description provided for @customerDebts.
  ///
  /// In uz, this message translates to:
  /// **'Mijozlar qarzlari'**
  String get customerDebts;

  /// No description provided for @userManagement.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilarni boshqarish'**
  String get userManagement;

  /// No description provided for @priceManagement.
  ///
  /// In uz, this message translates to:
  /// **'Narxlarni boshqarish'**
  String get priceManagement;

  /// No description provided for @profileSaved.
  ///
  /// In uz, this message translates to:
  /// **'Profil saqlandi'**
  String get profileSaved;

  /// No description provided for @add.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shish'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In uz, this message translates to:
  /// **'Tahrirlash'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In uz, this message translates to:
  /// **'Saqlash'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilish'**
  String get cancel;

  /// No description provided for @search.
  ///
  /// In uz, this message translates to:
  /// **'Qidirish'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In uz, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @name.
  ///
  /// In uz, this message translates to:
  /// **'Nomi'**
  String get name;

  /// No description provided for @quantity.
  ///
  /// In uz, this message translates to:
  /// **'Miqdori'**
  String get quantity;

  /// No description provided for @costPrice.
  ///
  /// In uz, this message translates to:
  /// **'Sotib olish narxi'**
  String get costPrice;

  /// No description provided for @salePrice.
  ///
  /// In uz, this message translates to:
  /// **'Sotish narxi'**
  String get salePrice;

  /// No description provided for @minSalePrice.
  ///
  /// In uz, this message translates to:
  /// **'Min. sotish narxi'**
  String get minSalePrice;

  /// No description provided for @minThreshold.
  ///
  /// In uz, this message translates to:
  /// **'Min. chegara'**
  String get minThreshold;

  /// No description provided for @temporary.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtinchalik'**
  String get temporary;

  /// No description provided for @actions.
  ///
  /// In uz, this message translates to:
  /// **'Amallar'**
  String get actions;

  /// No description provided for @loading.
  ///
  /// In uz, this message translates to:
  /// **'Yuklanmoqda...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik'**
  String get error;

  /// No description provided for @success.
  ///
  /// In uz, this message translates to:
  /// **'Muvaffaqiyatli'**
  String get success;

  /// No description provided for @noData.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumot yo\'q'**
  String get noData;

  /// No description provided for @confirmDelete.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu elementni o\'chirmoqchimisiz?'**
  String get confirmDelete;

  /// No description provided for @confirm.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash'**
  String get confirm;

  /// No description provided for @total.
  ///
  /// In uz, this message translates to:
  /// **'Jami'**
  String get total;

  /// No description provided for @from.
  ///
  /// In uz, this message translates to:
  /// **'Dan'**
  String get from;

  /// No description provided for @to.
  ///
  /// In uz, this message translates to:
  /// **'Gacha'**
  String get to;

  /// No description provided for @paid.
  ///
  /// In uz, this message translates to:
  /// **'To\'langan'**
  String get paid;

  /// No description provided for @date.
  ///
  /// In uz, this message translates to:
  /// **'Sana'**
  String get date;

  /// No description provided for @seller.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi'**
  String get seller;

  /// No description provided for @customer.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz'**
  String get customer;

  /// No description provided for @phone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon'**
  String get phone;

  /// No description provided for @comment.
  ///
  /// In uz, this message translates to:
  /// **'Izoh'**
  String get comment;

  /// No description provided for @status.
  ///
  /// In uz, this message translates to:
  /// **'Holati'**
  String get status;

  /// No description provided for @draft.
  ///
  /// In uz, this message translates to:
  /// **'Qoralama'**
  String get draft;

  /// No description provided for @completed.
  ///
  /// In uz, this message translates to:
  /// **'Tugatilgan'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In uz, this message translates to:
  /// **'Bekor qilingan'**
  String get cancelled;

  /// No description provided for @active.
  ///
  /// In uz, this message translates to:
  /// **'Faol'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In uz, this message translates to:
  /// **'Nofaol'**
  String get inactive;

  /// No description provided for @owner.
  ///
  /// In uz, this message translates to:
  /// **'Egasi'**
  String get owner;

  /// No description provided for @admin.
  ///
  /// In uz, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @loginSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Tizimga muvaffaqiyatli kirdingiz!'**
  String get loginSuccess;

  /// No description provided for @loginError.
  ///
  /// In uz, this message translates to:
  /// **'Kirish xatosi. Ma\'lumotlaringizni tekshiring.'**
  String get loginError;

  /// No description provided for @registerSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan muvaffaqiyatli o\'tdingiz!'**
  String get registerSuccess;

  /// No description provided for @registerError.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish xatosi. Qaytadan urinib ko\'ring.'**
  String get registerError;

  /// No description provided for @updateError.
  ///
  /// In uz, this message translates to:
  /// **'Yangilash xatosi.'**
  String get updateError;

  /// No description provided for @deleteSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Muvaffaqiyatli o\'chirildi!'**
  String get deleteSuccess;

  /// No description provided for @deleteError.
  ///
  /// In uz, this message translates to:
  /// **'O\'chirish xatosi.'**
  String get deleteError;

  /// No description provided for @enterUsername.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi nomini kiriting'**
  String get enterUsername;

  /// No description provided for @enterPassword.
  ///
  /// In uz, this message translates to:
  /// **'Parolni kiriting'**
  String get enterPassword;

  /// No description provided for @enterFullName.
  ///
  /// In uz, this message translates to:
  /// **'To\'liq ismni kiriting'**
  String get enterFullName;

  /// No description provided for @enterName.
  ///
  /// In uz, this message translates to:
  /// **'Ismni kiriting'**
  String get enterName;

  /// No description provided for @enterPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamini kiriting'**
  String get enterPhone;

  /// No description provided for @quantityMustBePositive.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor musbat bo\'lishi kerak'**
  String get quantityMustBePositive;

  /// No description provided for @fieldRequired.
  ///
  /// In uz, this message translates to:
  /// **'Ushbu maydon to\'ldirilishi shart'**
  String get fieldRequired;

  /// No description provided for @invalidInput.
  ///
  /// In uz, this message translates to:
  /// **'Noto\'g\'ri ma\'lumot'**
  String get invalidInput;

  /// No description provided for @serverError.
  ///
  /// In uz, this message translates to:
  /// **'Server xatosi. Iltimos, keyinroq urinib ko\'ring.'**
  String get serverError;

  /// No description provided for @networkError.
  ///
  /// In uz, this message translates to:
  /// **'Tarmoq xatosi. Internet aloqangizni tekshiring.'**
  String get networkError;

  /// No description provided for @updateProfile.
  ///
  /// In uz, this message translates to:
  /// **'Profilni yangilash'**
  String get updateProfile;

  /// No description provided for @changePassword.
  ///
  /// In uz, this message translates to:
  /// **'Parolni o\'zgartirish'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgi parol'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In uz, this message translates to:
  /// **'Yangi parol'**
  String get newPassword;

  /// No description provided for @changePasswordHint.
  ///
  /// In uz, this message translates to:
  /// **'Parolni o\'zgartirish uchun hozirgi parolni kiriting'**
  String get changePasswordHint;

  /// No description provided for @uploadImage.
  ///
  /// In uz, this message translates to:
  /// **'Rasm yuklash'**
  String get uploadImage;

  /// No description provided for @uploadProfileImage.
  ///
  /// In uz, this message translates to:
  /// **'Profil rasmini yuklash'**
  String get uploadProfileImage;

  /// No description provided for @imageUploadSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Rasm muvaffaqiyatli yuklandi!'**
  String get imageUploadSuccess;

  /// No description provided for @imageUploadError.
  ///
  /// In uz, this message translates to:
  /// **'Rasm yuklash xatosi.'**
  String get imageUploadError;

  /// No description provided for @imageTooLarge.
  ///
  /// In uz, this message translates to:
  /// **'Rasm hajmi juda katta. Maksimum hajmi 5MB.'**
  String get imageTooLarge;

  /// No description provided for @addProduct.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot qo\'shish'**
  String get addProduct;

  /// No description provided for @editProduct.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotni tahrirlash'**
  String get editProduct;

  /// No description provided for @addCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz qo\'shish'**
  String get addCustomer;

  /// No description provided for @editCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozni tahrirlash'**
  String get editCustomer;

  /// No description provided for @addSale.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv qo\'shish'**
  String get addSale;

  /// No description provided for @addPayment.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov qo\'shish'**
  String get addPayment;

  /// No description provided for @cash.
  ///
  /// In uz, this message translates to:
  /// **'Naqd'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In uz, this message translates to:
  /// **'Karta'**
  String get card;

  /// No description provided for @noProducts.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar yo\'q'**
  String get noProducts;

  /// No description provided for @noCustomers.
  ///
  /// In uz, this message translates to:
  /// **'Mijozlar yo\'q'**
  String get noCustomers;

  /// No description provided for @createSale.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv yaratish'**
  String get createSale;

  /// No description provided for @saleItems.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv elementlari'**
  String get saleItems;

  /// No description provided for @payments.
  ///
  /// In uz, this message translates to:
  /// **'To\'lovlar'**
  String get payments;

  /// No description provided for @addSaleItem.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv elementi qo\'shish'**
  String get addSaleItem;

  /// No description provided for @completeSale.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvni tugatish'**
  String get completeSale;

  /// No description provided for @cancelSale.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvni bekor qilish'**
  String get cancelSale;

  /// No description provided for @saleCreated.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv muvaffaqiyatli yaratildi!'**
  String get saleCreated;

  /// No description provided for @saleCompleted.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv muvaffaqiyatli tugatildi!'**
  String get saleCompleted;

  /// No description provided for @saleCancelled.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv muvaffaqiyatli bekor qilindi!'**
  String get saleCancelled;

  /// No description provided for @zakupCreated.
  ///
  /// In uz, this message translates to:
  /// **'Xarid muvaffaqiyatli qo\'shildi!'**
  String get zakupCreated;

  /// No description provided for @productUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot muvaffaqiyatli yangilandi!'**
  String get productUpdated;

  /// No description provided for @customerUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz muvaffaqiyatli yangilandi!'**
  String get customerUpdated;

  /// No description provided for @adminCanEditPrices.
  ///
  /// In uz, this message translates to:
  /// **'Eslatma: Admin foydalanuvchilari faqat narxlarni tahrirlashi mumkin, nom va miqdorni emas.'**
  String get adminCanEditPrices;

  /// No description provided for @quantityUpdatedViaZakup.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor faqat Xaridlar orqali yangilanadi.'**
  String get quantityUpdatedViaZakup;

  /// No description provided for @createZakup.
  ///
  /// In uz, this message translates to:
  /// **'Xarid yaratish'**
  String get createZakup;

  /// No description provided for @zakupInfo.
  ///
  /// In uz, this message translates to:
  /// **'Xarid ma\'lumotlari'**
  String get zakupInfo;

  /// No description provided for @selectProductToAdd.
  ///
  /// In uz, this message translates to:
  /// **'Zaxira qo\'shish uchun mahsulotni tanlang'**
  String get selectProductToAdd;

  /// No description provided for @quantityToAdd.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shiladigan miqdor'**
  String get quantityToAdd;

  /// No description provided for @purchasePrice.
  ///
  /// In uz, this message translates to:
  /// **'Sotib olish narxi'**
  String get purchasePrice;

  /// No description provided for @totalCost.
  ///
  /// In uz, this message translates to:
  /// **'Jami xarajat'**
  String get totalCost;

  /// No description provided for @addToStock.
  ///
  /// In uz, this message translates to:
  /// **'Zaxiraga qo\'shish'**
  String get addToStock;

  /// No description provided for @dailyReport.
  ///
  /// In uz, this message translates to:
  /// **'Kundalik hisobot'**
  String get dailyReport;

  /// No description provided for @periodReport.
  ///
  /// In uz, this message translates to:
  /// **'Davriy hisobot'**
  String get periodReport;

  /// No description provided for @startDate.
  ///
  /// In uz, this message translates to:
  /// **'Boshlanish sanasi'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In uz, this message translates to:
  /// **'Tugash sanasi'**
  String get endDate;

  /// No description provided for @generate.
  ///
  /// In uz, this message translates to:
  /// **'Yaratish'**
  String get generate;

  /// No description provided for @exportToExcel.
  ///
  /// In uz, this message translates to:
  /// **'Excelga eksport qilish'**
  String get exportToExcel;

  /// No description provided for @totalSales.
  ///
  /// In uz, this message translates to:
  /// **'Jami sotuvlar'**
  String get totalSales;

  /// No description provided for @totalPurchases.
  ///
  /// In uz, this message translates to:
  /// **'Jami xaridlar'**
  String get totalPurchases;

  /// No description provided for @profit.
  ///
  /// In uz, this message translates to:
  /// **'Foyda'**
  String get profit;

  /// No description provided for @netIncome.
  ///
  /// In uz, this message translates to:
  /// **'Toza daromad'**
  String get netIncome;

  /// No description provided for @transactionCount.
  ///
  /// In uz, this message translates to:
  /// **'Tranzaksiya soni'**
  String get transactionCount;

  /// No description provided for @sellerName.
  ///
  /// In uz, this message translates to:
  /// **'Sotuvchi nomi'**
  String get sellerName;

  /// No description provided for @totalProfit.
  ///
  /// In uz, this message translates to:
  /// **'Jami foyda'**
  String get totalProfit;

  /// No description provided for @productName.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot nomi'**
  String get productName;

  /// No description provided for @totalCostValue.
  ///
  /// In uz, this message translates to:
  /// **'Jami xarajat qiymati'**
  String get totalCostValue;

  /// No description provided for @totalSaleValue.
  ///
  /// In uz, this message translates to:
  /// **'Jami sotuv qiymati'**
  String get totalSaleValue;

  /// No description provided for @potentialProfit.
  ///
  /// In uz, this message translates to:
  /// **'Potensial foyda'**
  String get potentialProfit;

  /// No description provided for @payDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qarzni to\'lash'**
  String get payDebt;

  /// No description provided for @debtPaid.
  ///
  /// In uz, this message translates to:
  /// **'Qarz muvaffaqiyatli to\'landi!'**
  String get debtPaid;

  /// No description provided for @amount.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor'**
  String get amount;

  /// No description provided for @paymentType.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov turi'**
  String get paymentType;

  /// No description provided for @remainingDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qolgan qarz'**
  String get remainingDebt;

  /// No description provided for @totalDebt.
  ///
  /// In uz, this message translates to:
  /// **'Jami qarz'**
  String get totalDebt;

  /// No description provided for @userInformation.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi ma\'lumotlari'**
  String get userInformation;

  /// No description provided for @readOnly.
  ///
  /// In uz, this message translates to:
  /// **'Faqat o\'qish'**
  String get readOnly;

  /// No description provided for @loginScreenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Xush kelibsiz!'**
  String get loginScreenTitle;

  /// No description provided for @loginScreenSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish uchun tizimga kiring'**
  String get loginScreenSubtitle;

  /// No description provided for @registerScreenSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Boshlash uchun ro\'yxatdan o\'ting'**
  String get registerScreenSubtitle;

  /// No description provided for @welcomeScreenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Market Tizimi'**
  String get welcomeScreenTitle;

  /// No description provided for @welcomeScreenSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Sizning biznes boshqaruv yechimingiz'**
  String get welcomeScreenSubtitle;

  /// No description provided for @lightMode.
  ///
  /// In uz, this message translates to:
  /// **'Yorqin'**
  String get lightMode;

  /// No description provided for @usernameMinLength.
  ///
  /// In uz, this message translates to:
  /// **'Username kamida 3 ta belgi'**
  String get usernameMinLength;

  /// No description provided for @passwordMinLength.
  ///
  /// In uz, this message translates to:
  /// **'Parol kamida 6 ta belgi'**
  String get passwordMinLength;

  /// No description provided for @passwordConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tasdiqlash'**
  String get passwordConfirm;

  /// No description provided for @passwordConfirmRequired.
  ///
  /// In uz, this message translates to:
  /// **'Parolni tasdiqlash shart'**
  String get passwordConfirmRequired;

  /// No description provided for @passwordMismatch.
  ///
  /// In uz, this message translates to:
  /// **'Parollar mos emas'**
  String get passwordMismatch;

  /// No description provided for @registerScreenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish'**
  String get registerScreenTitle;

  /// No description provided for @createNewAccount.
  ///
  /// In uz, this message translates to:
  /// **'Yangi hisob yaratish'**
  String get createNewAccount;

  /// No description provided for @backToLogin.
  ///
  /// In uz, this message translates to:
  /// **'Login sahifasiga qaytish'**
  String get backToLogin;

  /// No description provided for @saving.
  ///
  /// In uz, this message translates to:
  /// **'Saqlanmoqda...'**
  String get saving;

  /// No description provided for @cashRegister.
  ///
  /// In uz, this message translates to:
  /// **'Kassa'**
  String get cashRegister;

  /// No description provided for @currentBalance.
  ///
  /// In uz, this message translates to:
  /// **'Joriy Balans'**
  String get currentBalance;

  /// No description provided for @lastUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Oxirgi yangilanish'**
  String get lastUpdated;

  /// No description provided for @withdrawCash.
  ///
  /// In uz, this message translates to:
  /// **'Pul Olish'**
  String get withdrawCash;

  /// No description provided for @withdrawalHistory.
  ///
  /// In uz, this message translates to:
  /// **'Pul Olish Tarixi'**
  String get withdrawalHistory;

  /// No description provided for @noWithdrawals.
  ///
  /// In uz, this message translates to:
  /// **'Hali pul olish tarixi yo\'q'**
  String get noWithdrawals;

  /// No description provided for @insufficientFunds.
  ///
  /// In uz, this message translates to:
  /// **'Balans yetarli emas'**
  String get insufficientFunds;

  /// No description provided for @withdrawSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Pul muvaffaqiyatli olindi'**
  String get withdrawSuccess;

  /// No description provided for @accessDenied.
  ///
  /// In uz, this message translates to:
  /// **'Sizga bu bo\'limga kirish ruxsati yo\'q'**
  String get accessDenied;

  /// No description provided for @info.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumot'**
  String get info;

  /// No description provided for @registrationPendingInfo.
  ///
  /// In uz, this message translates to:
  /// **'Registratsiya uchun so\'rovingiz adminga yuborildi. Tez orada administrator registratsiyaga ruxsat beradi.'**
  String get registrationPendingInfo;

  /// No description provided for @understand.
  ///
  /// In uz, this message translates to:
  /// **'Tushunarli'**
  String get understand;

  /// No description provided for @categories.
  ///
  /// In uz, this message translates to:
  /// **'Kategoriyalar'**
  String get categories;

  /// No description provided for @dailySales.
  ///
  /// In uz, this message translates to:
  /// **'Kunlik savdo'**
  String get dailySales;

  /// No description provided for @drafts.
  ///
  /// In uz, this message translates to:
  /// **'Draftlar'**
  String get drafts;

  /// No description provided for @darkMode.
  ///
  /// In uz, this message translates to:
  /// **'Qorong\'i rejim'**
  String get darkMode;

  /// No description provided for @user.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi'**
  String get user;

  /// No description provided for @security.
  ///
  /// In uz, this message translates to:
  /// **'Xavfsizlik'**
  String get security;

  /// No description provided for @updateSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlar muvaffaqiyatli yangilandi'**
  String get updateSuccess;

  /// No description provided for @category.
  ///
  /// In uz, this message translates to:
  /// **'Kategoriya'**
  String get category;

  /// No description provided for @unit.
  ///
  /// In uz, this message translates to:
  /// **'Birlik'**
  String get unit;

  /// No description provided for @minPrice.
  ///
  /// In uz, this message translates to:
  /// **'Min. narx'**
  String get minPrice;

  /// No description provided for @temporaryProduct.
  ///
  /// In uz, this message translates to:
  /// **'Vaqtinchalik'**
  String get temporaryProduct;

  /// No description provided for @none.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'q'**
  String get none;

  /// No description provided for @stock.
  ///
  /// In uz, this message translates to:
  /// **'Zaxira'**
  String get stock;

  /// No description provided for @zakupSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Zakup muvaffaqiyatli qo\'shildi!'**
  String get zakupSuccess;

  /// No description provided for @number.
  ///
  /// In uz, this message translates to:
  /// **'Soni'**
  String get number;

  /// No description provided for @addCategory.
  ///
  /// In uz, this message translates to:
  /// **'Kategoriya qo\'shish'**
  String get addCategory;

  /// No description provided for @editCategory.
  ///
  /// In uz, this message translates to:
  /// **'Kategoriyani tahrirlash'**
  String get editCategory;

  /// No description provided for @categoryName.
  ///
  /// In uz, this message translates to:
  /// **'Kategoriya nomi'**
  String get categoryName;

  /// No description provided for @description.
  ///
  /// In uz, this message translates to:
  /// **'Tavsif'**
  String get description;

  /// No description provided for @isActive.
  ///
  /// In uz, this message translates to:
  /// **'Faol holatda'**
  String get isActive;

  /// No description provided for @newSale.
  ///
  /// In uz, this message translates to:
  /// **'Yangi sotuv'**
  String get newSale;

  /// No description provided for @totalAmount.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy summa'**
  String get totalAmount;

  /// No description provided for @all.
  ///
  /// In uz, this message translates to:
  /// **'Barchasi'**
  String get all;

  /// No description provided for @debt.
  ///
  /// In uz, this message translates to:
  /// **'Qarz'**
  String get debt;

  /// No description provided for @noCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozsiz'**
  String get noCustomer;

  /// No description provided for @exportExcel.
  ///
  /// In uz, this message translates to:
  /// **'Excelga yuklash'**
  String get exportExcel;

  /// No description provided for @saleDetails.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv tafsilotlari'**
  String get saleDetails;

  /// No description provided for @soldProducts.
  ///
  /// In uz, this message translates to:
  /// **'Sotilgan mahsulotlar'**
  String get soldProducts;

  /// No description provided for @returnAmount.
  ///
  /// In uz, this message translates to:
  /// **'Qaytariladigan summa'**
  String get returnAmount;

  /// No description provided for @maxQuantity.
  ///
  /// In uz, this message translates to:
  /// **'Maksimal miqdor'**
  String get maxQuantity;

  /// No description provided for @returnSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Muvaffaqiyatli qaytarildi'**
  String get returnSuccess;

  /// No description provided for @errorOccurred.
  ///
  /// In uz, this message translates to:
  /// **'Xatolik yuz berdi'**
  String get errorOccurred;

  /// No description provided for @unknown.
  ///
  /// In uz, this message translates to:
  /// **'Noma\'lum'**
  String get unknown;

  /// No description provided for @totalSum.
  ///
  /// In uz, this message translates to:
  /// **'Jami summa'**
  String get totalSum;

  /// No description provided for @returnAction.
  ///
  /// In uz, this message translates to:
  /// **'Qaytarish'**
  String get returnAction;

  /// No description provided for @unknownProduct.
  ///
  /// In uz, this message translates to:
  /// **'Noma\'lum mahsulot'**
  String get unknownProduct;

  /// No description provided for @processReturn.
  ///
  /// In uz, this message translates to:
  /// **'Vozvrat qilish'**
  String get processReturn;

  /// No description provided for @maxReturn.
  ///
  /// In uz, this message translates to:
  /// **'Maksimal qaytarish'**
  String get maxReturn;

  /// No description provided for @piece.
  ///
  /// In uz, this message translates to:
  /// **'dona'**
  String get piece;

  /// No description provided for @reasonOptional.
  ///
  /// In uz, this message translates to:
  /// **'Sababi (ixtiyoriy)'**
  String get reasonOptional;

  /// No description provided for @defect.
  ///
  /// In uz, this message translates to:
  /// **'Brak'**
  String get defect;

  /// No description provided for @finishReturn.
  ///
  /// In uz, this message translates to:
  /// **'Vozvratni yakunlash'**
  String get finishReturn;

  /// No description provided for @price.
  ///
  /// In uz, this message translates to:
  /// **'Narx'**
  String get price;

  /// No description provided for @saleAsDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qarzga yozildi'**
  String get saleAsDebt;

  /// No description provided for @saleSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Sotildi'**
  String get saleSuccess;

  /// No description provided for @cartEmptyWarning.
  ///
  /// In uz, this message translates to:
  /// **'Savat bo\'sh! Avval mahsulot qo\'shing'**
  String get cartEmptyWarning;

  /// No description provided for @draftSaved.
  ///
  /// In uz, this message translates to:
  /// **'Savdo draft sifatida saqlandi!'**
  String get draftSaved;

  /// No description provided for @returnText.
  ///
  /// In uz, this message translates to:
  /// **'Vozvrat'**
  String get returnText;

  /// No description provided for @saleText.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv'**
  String get saleText;

  /// No description provided for @takeAsDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qarzga olish'**
  String get takeAsDebt;

  /// No description provided for @terminal.
  ///
  /// In uz, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @transfer.
  ///
  /// In uz, this message translates to:
  /// **'O\'tkazma'**
  String get transfer;

  /// No description provided for @click.
  ///
  /// In uz, this message translates to:
  /// **'Click'**
  String get click;

  /// No description provided for @enterCorrectAmount.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, to\'g\'ri summani kiriting'**
  String get enterCorrectAmount;

  /// No description provided for @changeAmount.
  ///
  /// In uz, this message translates to:
  /// **'Ortiqcha (Sdacha)'**
  String get changeAmount;

  /// No description provided for @youEntered.
  ///
  /// In uz, this message translates to:
  /// **'Siz kiritdingiz'**
  String get youEntered;

  /// No description provided for @totalAmountLabel.
  ///
  /// In uz, this message translates to:
  /// **'Jami summa:'**
  String get totalAmountLabel;

  /// No description provided for @tooMuchAmount.
  ///
  /// In uz, this message translates to:
  /// **'Ko\'p summa kiritildi!'**
  String get tooMuchAmount;

  /// No description provided for @fullAmountWarning.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, to\'liq summani kiriting yoki \"Qarzga yozish\"ni tanlang.'**
  String get fullAmountWarning;

  /// No description provided for @newDebt.
  ///
  /// In uz, this message translates to:
  /// **'Yangi qarz'**
  String get newDebt;

  /// No description provided for @onDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qarzga'**
  String get onDebt;

  /// No description provided for @remaining.
  ///
  /// In uz, this message translates to:
  /// **'Qolgan:'**
  String get remaining;

  /// No description provided for @selectCustomerForDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qarzga olish uchun avval mijoz tanlang'**
  String get selectCustomerForDebt;

  /// No description provided for @selectCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz tanlang'**
  String get selectCustomer;

  /// No description provided for @clickPayment.
  ///
  /// In uz, this message translates to:
  /// **'Click to\'lov'**
  String get clickPayment;

  /// No description provided for @transferAmount.
  ///
  /// In uz, this message translates to:
  /// **'Transfer summa (so\'m)'**
  String get transferAmount;

  /// No description provided for @accountNumber.
  ///
  /// In uz, this message translates to:
  /// **'Hisob raqam'**
  String get accountNumber;

  /// No description provided for @cardAmount.
  ///
  /// In uz, this message translates to:
  /// **'Plastik summa'**
  String get cardAmount;

  /// No description provided for @currencySom.
  ///
  /// In uz, this message translates to:
  /// **'so\'m'**
  String get currencySom;

  /// No description provided for @bankCard.
  ///
  /// In uz, this message translates to:
  /// **'Plastik karta'**
  String get bankCard;

  /// No description provided for @cashAmount.
  ///
  /// In uz, this message translates to:
  /// **'Naqd summa'**
  String get cashAmount;

  /// No description provided for @paymentMethods.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov usullari'**
  String get paymentMethods;

  /// No description provided for @invalidPriceOrQty.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor va narx xato!'**
  String get invalidPriceOrQty;

  /// No description provided for @customerNotSelected.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz tanlanmagan'**
  String get customerNotSelected;

  /// No description provided for @searchProduct.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot qidirish...'**
  String get searchProduct;

  /// No description provided for @warehouse.
  ///
  /// In uz, this message translates to:
  /// **'Ombor'**
  String get warehouse;

  /// No description provided for @saveDraft.
  ///
  /// In uz, this message translates to:
  /// **'Ha, saqlash'**
  String get saveDraft;

  /// No description provided for @discardSale.
  ///
  /// In uz, this message translates to:
  /// **'Yo\'q, chiqib ketish'**
  String get discardSale;

  /// No description provided for @draftSavePrompt.
  ///
  /// In uz, this message translates to:
  /// **'Savatda {count} ta mahsulot bor. Draft sifatida saqlashni xohlaysizmi?'**
  String draftSavePrompt(Object count);

  /// No description provided for @enterAmount.
  ///
  /// In uz, this message translates to:
  /// **'Summani kiriting'**
  String get enterAmount;

  /// No description provided for @saveSaleTitle.
  ///
  /// In uz, this message translates to:
  /// **'Savdani saqlash?'**
  String get saveSaleTitle;

  /// No description provided for @selectCustomerTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mijozni tanlang'**
  String get selectCustomerTitle;

  /// No description provided for @noCustomersFound.
  ///
  /// In uz, this message translates to:
  /// **'Mijozlar topilmadi'**
  String get noCustomersFound;

  /// No description provided for @itemUpdated.
  ///
  /// In uz, this message translates to:
  /// **'o\'zgartirildi'**
  String get itemUpdated;

  /// No description provided for @draftSales.
  ///
  /// In uz, this message translates to:
  /// **'Davom etayotgan savdolar'**
  String get draftSales;

  /// No description provided for @newUser.
  ///
  /// In uz, this message translates to:
  /// **'Yangi foydalanuvchi'**
  String get newUser;

  /// No description provided for @debtDetails.
  ///
  /// In uz, this message translates to:
  /// **'Qarz detallari'**
  String get debtDetails;

  /// No description provided for @draftSale.
  ///
  /// In uz, this message translates to:
  /// **'Draft savdo'**
  String get draftSale;

  /// No description provided for @debtors.
  ///
  /// In uz, this message translates to:
  /// **'Qarzdorlar'**
  String get debtors;

  /// No description provided for @noDebts.
  ///
  /// In uz, this message translates to:
  /// **'Qarzlar yo\'q'**
  String get noDebts;

  /// No description provided for @debtHistory.
  ///
  /// In uz, this message translates to:
  /// **'Qarzlar tarixi'**
  String get debtHistory;

  /// No description provided for @retry.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retry;

  /// No description provided for @customerDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz muvaffaqiyatli o\'chirildi'**
  String get customerDeleted;

  /// No description provided for @customerAdded.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz muvaffaqiyatli qo\'shildi'**
  String get customerAdded;

  /// No description provided for @addNewCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Yangi mijoz'**
  String get addNewCustomer;

  /// No description provided for @searchCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz qidirish...'**
  String get searchCustomer;

  /// No description provided for @customerNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz topilmadi'**
  String get customerNotFound;

  /// No description provided for @phoneNumber.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqami'**
  String get phoneNumber;

  /// No description provided for @fullNameOptional.
  ///
  /// In uz, this message translates to:
  /// **'To\'liq ism (ixtiyoriy)'**
  String get fullNameOptional;

  /// No description provided for @commentOptional.
  ///
  /// In uz, this message translates to:
  /// **'Izoh (ixtiyoriy)'**
  String get commentOptional;

  /// No description provided for @debtStatus.
  ///
  /// In uz, this message translates to:
  /// **'Qarz holati'**
  String get debtStatus;

  /// No description provided for @debtAmountSom.
  ///
  /// In uz, this message translates to:
  /// **'Qarz miqdori (so\'m)'**
  String get debtAmountSom;

  /// No description provided for @debtAmountRequired.
  ///
  /// In uz, this message translates to:
  /// **'Qarz miqdorini kiritish shart'**
  String get debtAmountRequired;

  /// No description provided for @debtAmountPositive.
  ///
  /// In uz, this message translates to:
  /// **'Qarz musbat son bo\'lishi kerak'**
  String get debtAmountPositive;

  /// No description provided for @debtRecordWillBeCreated.
  ///
  /// In uz, this message translates to:
  /// **'Bu mijoz uchun qarz yozuvi yaratiladi'**
  String get debtRecordWillBeCreated;

  /// No description provided for @noDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qarzsiz'**
  String get noDebt;

  /// No description provided for @yesDelete.
  ///
  /// In uz, this message translates to:
  /// **'Ha, o\'chirish'**
  String get yesDelete;

  /// No description provided for @deleteCustomerConfirm.
  ///
  /// In uz, this message translates to:
  /// **'{name} o\'chirilsinmi?'**
  String deleteCustomerConfirm(Object name);

  /// No description provided for @deleteCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozni o\'chirish'**
  String get deleteCustomer;

  /// No description provided for @noProductsFound.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar mavjud emas'**
  String get noProductsFound;

  /// No description provided for @inDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qarzda'**
  String get inDebt;

  /// No description provided for @debtor.
  ///
  /// In uz, this message translates to:
  /// **'Qarzdor'**
  String get debtor;

  /// No description provided for @phoneRequired.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqam kiritish shart'**
  String get phoneRequired;

  /// No description provided for @phoneFormatHint.
  ///
  /// In uz, this message translates to:
  /// **'Format: 998XXXXXXXXX (12 ta raqam)'**
  String get phoneFormatHint;

  /// No description provided for @productNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot topilmadi'**
  String get productNotFound;

  /// No description provided for @priceSom.
  ///
  /// In uz, this message translates to:
  /// **'Narxi: {price} so\'m'**
  String priceSom(Object price);

  /// No description provided for @selectProduct.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot tanlang'**
  String get selectProduct;

  /// No description provided for @addedBy.
  ///
  /// In uz, this message translates to:
  /// **'Qo\'shdi: {user}'**
  String addedBy(Object user);

  /// No description provided for @costPriceSom.
  ///
  /// In uz, this message translates to:
  /// **'Olingan narxi: {price} so\'m'**
  String costPriceSom(Object price);

  /// No description provided for @addPurchase.
  ///
  /// In uz, this message translates to:
  /// **'Zakup qo\'shish'**
  String get addPurchase;

  /// No description provided for @noPurchases.
  ///
  /// In uz, this message translates to:
  /// **'Xaridlar yo\'q'**
  String get noPurchases;

  /// No description provided for @errorLoadingData.
  ///
  /// In uz, this message translates to:
  /// **'Ma\'lumotlarni yuklab olishda xatolik'**
  String get errorLoadingData;

  /// No description provided for @fileSaved.
  ///
  /// In uz, this message translates to:
  /// **'Fayl saqlandi'**
  String get fileSaved;

  /// No description provided for @fileSaveError.
  ///
  /// In uz, this message translates to:
  /// **'Faylni saqlashda xatolik yuz berdi'**
  String get fileSaveError;

  /// No description provided for @costPriceField.
  ///
  /// In uz, this message translates to:
  /// **'Olingan narxi (so\'m)'**
  String get costPriceField;

  /// No description provided for @noProductsAddFirst.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar yo\'q. Avval mahsulot qo\'shing'**
  String get noProductsAddFirst;

  /// No description provided for @onlyAdminOwnerCanAdd.
  ///
  /// In uz, this message translates to:
  /// **'Faqat Admin va Owner zakup qo\'sha oladi'**
  String get onlyAdminOwnerCanAdd;

  /// No description provided for @fillAmountAndPrice.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor va narxni to\'ldiring'**
  String get fillAmountAndPrice;

  /// No description provided for @activated.
  ///
  /// In uz, this message translates to:
  /// **'Aktivatsiya qilindi'**
  String get activated;

  /// No description provided for @deactivated.
  ///
  /// In uz, this message translates to:
  /// **'Deaktivatsiya qilindi'**
  String get deactivated;

  /// No description provided for @cannotDeleteSelf.
  ///
  /// In uz, this message translates to:
  /// **'O\'zingizni o\'chira olmaysiz'**
  String get cannotDeleteSelf;

  /// No description provided for @deleteUser.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchini o\'chirish'**
  String get deleteUser;

  /// No description provided for @deleteUserConfirm.
  ///
  /// In uz, this message translates to:
  /// **'{name} ni o\'chirmoqchimisiz?'**
  String deleteUserConfirm(Object name);

  /// No description provided for @searchUser.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi qidirish...'**
  String get searchUser;

  /// No description provided for @userNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchi topilmadi'**
  String get userNotFound;

  /// No description provided for @noUsersFound.
  ///
  /// In uz, this message translates to:
  /// **'Foydalanuvchilar yo\'q'**
  String get noUsersFound;

  /// No description provided for @nameRequired.
  ///
  /// In uz, this message translates to:
  /// **'Ism kiritish shart'**
  String get nameRequired;

  /// No description provided for @usernameRequired.
  ///
  /// In uz, this message translates to:
  /// **'Username shart'**
  String get usernameRequired;

  /// No description provided for @minThreeChars.
  ///
  /// In uz, this message translates to:
  /// **'Kamida 3 ta belgi'**
  String get minThreeChars;

  /// No description provided for @noSpacesAllowed.
  ///
  /// In uz, this message translates to:
  /// **'Bo\'sh joy bo\'lmasin'**
  String get noSpacesAllowed;

  /// No description provided for @passwordRequired.
  ///
  /// In uz, this message translates to:
  /// **'Parol shart'**
  String get passwordRequired;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In uz, this message translates to:
  /// **'Tasdiqlash shart'**
  String get confirmPasswordRequired;

  /// No description provided for @userCreatedSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Muvaffaqiyatli yaratildi!'**
  String get userCreatedSuccess;

  /// No description provided for @giveCredentialsToUser.
  ///
  /// In uz, this message translates to:
  /// **'Username va parolni yangi foydalanuvchiga bering'**
  String get giveCredentialsToUser;

  /// No description provided for @noPermissionToEditdd.
  ///
  /// In uz, this message translates to:
  /// **'Yopilgan qarzni tahrirlash huquqi yo\'q (faqat Owner/Admin)'**
  String get noPermissionToEditdd;

  /// No description provided for @priceUpdatedSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Narx muvaffaqiyatli yangilandi'**
  String get priceUpdatedSuccess;

  /// No description provided for @allDebtsPaid.
  ///
  /// In uz, this message translates to:
  /// **'Barcha qarzlar to\'langan'**
  String get allDebtsPaid;

  /// No description provided for @debtCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta qarz'**
  String debtCount(Object count);

  /// No description provided for @pay.
  ///
  /// In uz, this message translates to:
  /// **'To\'lash'**
  String get pay;

  /// No description provided for @cls.
  ///
  /// In uz, this message translates to:
  /// **'Yopiq'**
  String get cls;

  /// No description provided for @open.
  ///
  /// In uz, this message translates to:
  /// **'Ochiq'**
  String get open;

  /// No description provided for @ddDebtAudit.
  ///
  /// In uz, this message translates to:
  /// **'Bu qarz yopiq. O\'zgartirish audit logga yoziladi.'**
  String get ddDebtAudit;

  /// No description provided for @exampleComment.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Xato narx qo\'yilgan'**
  String get exampleComment;

  /// No description provided for @commentRequiredLabel.
  ///
  /// In uz, this message translates to:
  /// **'Izoh (majburiy)'**
  String get commentRequiredLabel;

  /// No description provided for @priceWithCurrency.
  ///
  /// In uz, this message translates to:
  /// **'Narx (so\'m)'**
  String get priceWithCurrency;

  /// No description provided for @newPriceLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yangi narx'**
  String get newPriceLabel;

  /// No description provided for @productQuantityAndOldPrice.
  ///
  /// In uz, this message translates to:
  /// **'{quantity} dona  ·  Eski narx: {price} so\'m'**
  String productQuantityAndOldPrice(Object price, Object quantity);

  /// No description provided for @editPriceTitle.
  ///
  /// In uz, this message translates to:
  /// **'Narxni tahrirlash'**
  String get editPriceTitle;

  /// No description provided for @product.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot'**
  String get product;

  /// No description provided for @yesConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Ha, tasdiqlayman'**
  String get yesConfirm;

  /// No description provided for @confirmPriceChangeDesc.
  ///
  /// In uz, this message translates to:
  /// **'Narxni {price} so\'mga o\'zgartirmoqchimisiz?'**
  String confirmPriceChangeDesc(Object price);

  /// No description provided for @commentRequiredError.
  ///
  /// In uz, this message translates to:
  /// **'Izoh kiritish majburiy'**
  String get commentRequiredError;

  /// No description provided for @priceMustBePositive.
  ///
  /// In uz, this message translates to:
  /// **'Narx 0 dan katta bo\'lishi kerak'**
  String get priceMustBePositive;

  /// No description provided for @paymentSuccess.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov muvaffaqiyatli amalga oshirildi!'**
  String get paymentSuccess;

  /// No description provided for @paymentAmountLabel.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov summasi'**
  String get paymentAmountLabel;

  /// No description provided for @payingTooMuchWarning.
  ///
  /// In uz, this message translates to:
  /// **'Qarz miqdoridan {amount} so\'m ko\'p to\'layapsiz'**
  String payingTooMuchWarning(Object amount);

  /// No description provided for @processPayment.
  ///
  /// In uz, this message translates to:
  /// **'To\'lovni amalga oshirish'**
  String get processPayment;

  /// No description provided for @salesCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta savdo'**
  String salesCount(Object count);

  /// No description provided for @netProfit.
  ///
  /// In uz, this message translates to:
  /// **'Sof foyda'**
  String get netProfit;

  /// No description provided for @noSalesToday.
  ///
  /// In uz, this message translates to:
  /// **'Bu kunda sotuvlar yo\'q'**
  String get noSalesToday;

  /// No description provided for @downloadExcel.
  ///
  /// In uz, this message translates to:
  /// **'Excel yuklab olish'**
  String get downloadExcel;

  /// No description provided for @reportDownloaded.
  ///
  /// In uz, this message translates to:
  /// **'Hisobot yuklab olindi'**
  String get reportDownloaded;

  /// No description provided for @downloadError.
  ///
  /// In uz, this message translates to:
  /// **'Yuklab olishda xatolik'**
  String get downloadError;

  /// No description provided for @reportDownloadSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Hisobot muvaffaqiyatli yuklab olindi!'**
  String get reportDownloadSuccess;

  /// No description provided for @byPaymentType.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov turlari bo\'yicha'**
  String get byPaymentType;

  /// No description provided for @select.
  ///
  /// In uz, this message translates to:
  /// **'Tanlash'**
  String get select;

  /// No description provided for @noReports.
  ///
  /// In uz, this message translates to:
  /// **'Hisobotlar yo\'q'**
  String get noReports;

  /// No description provided for @totalValue.
  ///
  /// In uz, this message translates to:
  /// **'Jami qiymat'**
  String get totalValue;

  /// No description provided for @sellingPrice.
  ///
  /// In uz, this message translates to:
  /// **'Sotuv narxi'**
  String get sellingPrice;

  /// No description provided for @productCount.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar soni'**
  String get productCount;

  /// No description provided for @incomingPrice.
  ///
  /// In uz, this message translates to:
  /// **'Kelgan narxi'**
  String get incomingPrice;

  /// No description provided for @andMoreProducts.
  ///
  /// In uz, this message translates to:
  /// **'Va yana {count} ta mahsulot bor...'**
  String andMoreProducts(Object count);

  /// No description provided for @totalSale.
  ///
  /// In uz, this message translates to:
  /// **'Jami savdo'**
  String get totalSale;

  /// No description provided for @saleCount.
  ///
  /// In uz, this message translates to:
  /// **'Savdolar soni'**
  String get saleCount;

  /// No description provided for @averageSale.
  ///
  /// In uz, this message translates to:
  /// **'O\'rtacha savdo'**
  String get averageSale;

  /// No description provided for @averageTransactionValue.
  ///
  /// In uz, this message translates to:
  /// **'Har bir savdoning o\'rtacha summasi'**
  String get averageTransactionValue;

  /// No description provided for @transactionStats.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta tranzaksiya  •  {percentage}%'**
  String transactionStats(Object count, Object percentage);

  /// No description provided for @daily.
  ///
  /// In uz, this message translates to:
  /// **'Kunlik'**
  String get daily;

  /// No description provided for @monthly.
  ///
  /// In uz, this message translates to:
  /// **'Oylik'**
  String get monthly;

  /// No description provided for @insufficientFundsWithBalance.
  ///
  /// In uz, this message translates to:
  /// **'Yetarli pul yo\'q! Mavjud: {balance} so\'m'**
  String insufficientFundsWithBalance(Object balance);

  /// No description provided for @withdrawalSuccessType.
  ///
  /// In uz, this message translates to:
  /// **'{type} muvaffaqiyatli olindi'**
  String withdrawalSuccessType(Object type);

  /// No description provided for @totalBalance.
  ///
  /// In uz, this message translates to:
  /// **'Umumiy balans'**
  String get totalBalance;

  /// No description provided for @updatedAt.
  ///
  /// In uz, this message translates to:
  /// **'Yangilandi: {time}'**
  String updatedAt(Object time);

  /// No description provided for @todaysIncomes.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi tushumlar'**
  String get todaysIncomes;

  /// No description provided for @cashMoney.
  ///
  /// In uz, this message translates to:
  /// **'Naqd pul'**
  String get cashMoney;

  /// No description provided for @todaysSales.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi savdolar'**
  String get todaysSales;

  /// No description provided for @itemsCount.
  ///
  /// In uz, this message translates to:
  /// **'{count} ta'**
  String itemsCount(Object count);

  /// No description provided for @selectPaymentTypeAndAmount.
  ///
  /// In uz, this message translates to:
  /// **'Pul turini va miqdorini tanlang'**
  String get selectPaymentTypeAndAmount;

  /// No description provided for @paymentTypeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Pul turi'**
  String get paymentTypeLabel;

  /// No description provided for @waiting.
  ///
  /// In uz, this message translates to:
  /// **'Kutilmoqda...'**
  String get waiting;

  /// No description provided for @productRemoved.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot olib tashlandi'**
  String get productRemoved;

  /// No description provided for @priceUpdated.
  ///
  /// In uz, this message translates to:
  /// **'Narx yangilandi'**
  String get priceUpdated;

  /// No description provided for @productReturned.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulot qaytarildi'**
  String get productReturned;

  /// No description provided for @saleNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Savdo topilmadi'**
  String get saleNotFound;

  /// No description provided for @productsNotFound.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotlar topilmadi'**
  String get productsNotFound;

  /// No description provided for @productAddedToCart.
  ///
  /// In uz, this message translates to:
  /// **'{name} savatga qo\'shildi'**
  String productAddedToCart(Object name);

  /// No description provided for @changePrice.
  ///
  /// In uz, this message translates to:
  /// **'Narxni o\'zgartirish'**
  String get changePrice;

  /// No description provided for @currentPrice.
  ///
  /// In uz, this message translates to:
  /// **'Hozirgi narx'**
  String get currentPrice;

  /// No description provided for @quantityCount.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor: {quantity} ta'**
  String quantityCount(Object quantity);

  /// No description provided for @priceChangedFor.
  ///
  /// In uz, this message translates to:
  /// **'{name} uchun narx o\'zgartirildi'**
  String priceChangedFor(Object name);

  /// No description provided for @noSales.
  ///
  /// In uz, this message translates to:
  /// **'Savdolar yo\'q'**
  String get noSales;

  /// No description provided for @debtAmount.
  ///
  /// In uz, this message translates to:
  /// **'Qarz: {amount}'**
  String debtAmount(Object amount);

  /// No description provided for @noDebtors.
  ///
  /// In uz, this message translates to:
  /// **'Qarzdorlar yo\'q'**
  String get noDebtors;

  /// No description provided for @debtorsWillBeShownHere.
  ///
  /// In uz, this message translates to:
  /// **'Qarzli mijozlar bu yerda ko\'rsatiladi'**
  String get debtorsWillBeShownHere;

  /// No description provided for @today.
  ///
  /// In uz, this message translates to:
  /// **'Bugun'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In uz, this message translates to:
  /// **'Kecha'**
  String get yesterday;

  /// No description provided for @daysAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} kun oldin'**
  String daysAgo(Object count);

  /// No description provided for @monthsAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} oy oldin'**
  String monthsAgo(Object count);

  /// No description provided for @yearsAgo.
  ///
  /// In uz, this message translates to:
  /// **'{count} yil oldin'**
  String yearsAgo(Object count);

  /// No description provided for @deleteSale.
  ///
  /// In uz, this message translates to:
  /// **'Savdoni o\'chirish'**
  String get deleteSale;

  /// No description provided for @deleteSaleConfirm.
  ///
  /// In uz, this message translates to:
  /// **'Haqiqatan ham bu savdoni o\'chirmoqchimisiz?'**
  String get deleteSaleConfirm;

  /// No description provided for @noDebtSalesFound.
  ///
  /// In uz, this message translates to:
  /// **'Qarz savdolari topilmadi'**
  String get noDebtSalesFound;

  /// No description provided for @debtorCustomers.
  ///
  /// In uz, this message translates to:
  /// **'Qarzdor mijozlar'**
  String get debtorCustomers;

  /// No description provided for @ongoing.
  ///
  /// In uz, this message translates to:
  /// **'Davom etayotgan'**
  String get ongoing;

  /// No description provided for @debtSales.
  ///
  /// In uz, this message translates to:
  /// **'Qarz savdolar'**
  String get debtSales;

  /// No description provided for @paidSales.
  ///
  /// In uz, this message translates to:
  /// **'To\'langan savdolar'**
  String get paidSales;

  /// No description provided for @saleDeleted.
  ///
  /// In uz, this message translates to:
  /// **'Savdo o\'chirildi'**
  String get saleDeleted;

  /// No description provided for @draftSaveError.
  ///
  /// In uz, this message translates to:
  /// **'Draft saqlashda xatolik'**
  String get draftSaveError;

  /// No description provided for @enterQuantityHint.
  ///
  /// In uz, this message translates to:
  /// **'Miqdor kiriting...'**
  String get enterQuantityHint;

  /// No description provided for @selectCustomerForDebtWarning.
  ///
  /// In uz, this message translates to:
  /// **'Qarzga olish uchun mijoz tanlang!'**
  String get selectCustomerForDebtWarning;

  /// No description provided for @makePayment.
  ///
  /// In uz, this message translates to:
  /// **'TO\'LOV QILISH'**
  String get makePayment;

  /// No description provided for @closed.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get closed;

  /// No description provided for @customerRemoved.
  ///
  /// In uz, this message translates to:
  /// **'Mijoz olib tashlandi'**
  String get customerRemoved;

  /// No description provided for @removeCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozni olib tashlash'**
  String get removeCustomer;

  /// No description provided for @paymentMethod.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov usuli'**
  String get paymentMethod;

  /// No description provided for @paymentAmount.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov miqdori'**
  String get paymentAmount;

  /// No description provided for @selectPaymentMethod.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov usulini tanlang'**
  String get selectPaymentMethod;

  /// No description provided for @enterValidAmount.
  ///
  /// In uz, this message translates to:
  /// **'To\'g\'ri miqdor kiriting'**
  String get enterValidAmount;

  /// No description provided for @continueAction.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueAction;

  /// No description provided for @saleIdTitle.
  ///
  /// In uz, this message translates to:
  /// **'Savdo #{id}'**
  String saleIdTitle(Object id);

  /// No description provided for @noOngoingSales.
  ///
  /// In uz, this message translates to:
  /// **'Davom etayotgan savdolar yo\'q'**
  String get noOngoingSales;

  /// No description provided for @initialSalesWillBeShownHere.
  ///
  /// In uz, this message translates to:
  /// **'Boshlang\'ich savdolar bu yerda ko\'rsatiladi'**
  String get initialSalesWillBeShownHere;

  /// No description provided for @returnProduct.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotni qaytarish'**
  String get returnProduct;

  /// No description provided for @availableQuantity.
  ///
  /// In uz, this message translates to:
  /// **'Mavjud miqdor'**
  String get availableQuantity;

  /// No description provided for @returnQuantity.
  ///
  /// In uz, this message translates to:
  /// **'Qaytarish miqdori'**
  String get returnQuantity;

  /// No description provided for @invalidQuantity.
  ///
  /// In uz, this message translates to:
  /// **'Noto\'g\'ri miqdor'**
  String get invalidQuantity;

  /// No description provided for @paymentHistory.
  ///
  /// In uz, this message translates to:
  /// **'To\'lov tarixi'**
  String get paymentHistory;

  /// No description provided for @hasDebt.
  ///
  /// In uz, this message translates to:
  /// **'Qarz bor'**
  String get hasDebt;

  /// No description provided for @noPayments.
  ///
  /// In uz, this message translates to:
  /// **'To\'lovlar yo\'q'**
  String get noPayments;

  /// No description provided for @noPermissionToEditClosed.
  ///
  /// In uz, this message translates to:
  /// **'Yopilgan qarzni tahrirlash uchun huquqingiz yo\'q (faqat Egasi/Admin)'**
  String get noPermissionToEditClosed;

  /// No description provided for @closedDebtAudit.
  ///
  /// In uz, this message translates to:
  /// **'Yopilgan qarzlar auditi'**
  String get closedDebtAudit;

  /// No description provided for @requestSentToAdmin.
  ///
  /// In uz, this message translates to:
  /// **'Zapros adminga yuborildi'**
  String get requestSentToAdmin;

  /// No description provided for @requestSentDescription.
  ///
  /// In uz, this message translates to:
  /// **'Sizning so\'rovingiz administratorga yuborildi. Tasdiqlashdan keyin siz bilan bog\'lanamiz.'**
  String get requestSentDescription;

  /// No description provided for @back.
  ///
  /// In uz, this message translates to:
  /// **'Orqaga'**
  String get back;

  /// No description provided for @marketName.
  ///
  /// In uz, this message translates to:
  /// **'Market nomi'**
  String get marketName;

  /// No description provided for @enterMarketName.
  ///
  /// In uz, this message translates to:
  /// **'Market nomini kiriting'**
  String get enterMarketName;

  /// No description provided for @marketNameTooShort.
  ///
  /// In uz, this message translates to:
  /// **'Market nomi kamida 3 ta belgidan iborat bo\'lishi kerak'**
  String get marketNameTooShort;

  /// No description provided for @newCategory.
  ///
  /// In uz, this message translates to:
  /// **'Yangi kategoriya'**
  String get newCategory;

  /// No description provided for @fillIn.
  ///
  /// In uz, this message translates to:
  /// **'To\'ldiring'**
  String get fillIn;

  /// No description provided for @addFirstCategory.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi kategoriyangizni qo\'shing'**
  String get addFirstCategory;

  /// No description provided for @todaysReport.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi hisobot'**
  String get todaysReport;

  /// No description provided for @anonymousCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Nomsiz mijoz'**
  String get anonymousCustomer;

  /// No description provided for @saleDetail.
  ///
  /// In uz, this message translates to:
  /// **'Savdo tafsiloti'**
  String get saleDetail;

  /// No description provided for @registerMarket.
  ///
  /// In uz, this message translates to:
  /// **'Marketni Ro\'yxatdan O\'tkazish'**
  String get registerMarket;

  /// No description provided for @afterMarketRegisterInfo.
  ///
  /// In uz, this message translates to:
  /// **'Market ro\'yxatdan o\'tgandan so\'ng, Admin va Seller foydalanuvchilar qo\'shishingiz mumkin'**
  String get afterMarketRegisterInfo;

  /// No description provided for @descriptionOptional.
  ///
  /// In uz, this message translates to:
  /// **'Tavsif (ixtiyoriy)'**
  String get descriptionOptional;

  /// No description provided for @marketShortInfo.
  ///
  /// In uz, this message translates to:
  /// **'Market haqida qisqacha ma\'lumot'**
  String get marketShortInfo;

  /// No description provided for @subdomainRules.
  ///
  /// In uz, this message translates to:
  /// **'Faqat kichik harflar, raqamlar va tire (-) bo\'lishi mumkin'**
  String get subdomainRules;

  /// No description provided for @canBeLeftEmpty.
  ///
  /// In uz, this message translates to:
  /// **'Bo\'sh qoldirish mumkin'**
  String get canBeLeftEmpty;

  /// No description provided for @exampleMyShop.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: myshop'**
  String get exampleMyShop;

  /// No description provided for @subdomainOptional.
  ///
  /// In uz, this message translates to:
  /// **'Subdomain (ixtiyoriy)'**
  String get subdomainOptional;

  /// No description provided for @pleaseEnterMarketName.
  ///
  /// In uz, this message translates to:
  /// **'Iltimos, market nomini kiriting'**
  String get pleaseEnterMarketName;

  /// No description provided for @exampleMyStore.
  ///
  /// In uz, this message translates to:
  /// **'Masalan: Do\'konim'**
  String get exampleMyStore;

  /// No description provided for @enterMarketDetails.
  ///
  /// In uz, this message translates to:
  /// **'Market ma\'lumotlarini kiriting'**
  String get enterMarketDetails;

  /// No description provided for @createYourMarket.
  ///
  /// In uz, this message translates to:
  /// **'O\'zingizning marketingizni yarating'**
  String get createYourMarket;

  /// No description provided for @marketRegistration.
  ///
  /// In uz, this message translates to:
  /// **'Market Registratsiyasi'**
  String get marketRegistration;

  /// No description provided for @nowYouCanAddUsers.
  ///
  /// In uz, this message translates to:
  /// **'Endi siz Admin va Seller foydalanuvchilar qo\'shishingiz mumkin.'**
  String get nowYouCanAddUsers;

  /// No description provided for @marketRegisteredSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Market muvaffaqiyatli ro\'yxatdan o\'tkazildi!'**
  String get marketRegisteredSuccess;

  /// No description provided for @productUsedInSales.
  ///
  /// In uz, this message translates to:
  /// **'Bu mahsulot savdolarda ishlatilgan, o\'chirib bo\'lmaydi'**
  String get productUsedInSales;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
