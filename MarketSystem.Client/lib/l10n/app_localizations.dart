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

  /// No description provided for @close.
  ///
  /// In uz, this message translates to:
  /// **'Yopish'**
  String get close;

  /// No description provided for @total.
  ///
  /// In uz, this message translates to:
  /// **'Jami'**
  String get total;

  /// No description provided for @paid.
  ///
  /// In uz, this message translates to:
  /// **'To\'langan'**
  String get paid;

  /// No description provided for @remaining.
  ///
  /// In uz, this message translates to:
  /// **'Qolgan'**
  String get remaining;

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

  /// No description provided for @updateSuccess.
  ///
  /// In uz, this message translates to:
  /// **'Muvaffaqiyatli yangilandi!'**
  String get updateSuccess;

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

  /// No description provided for @enterPhone.
  ///
  /// In uz, this message translates to:
  /// **'Telefon raqamini kiriting'**
  String get enterPhone;

  /// No description provided for @priceMustBePositive.
  ///
  /// In uz, this message translates to:
  /// **'Narx musbat bo\'lishi kerak'**
  String get priceMustBePositive;

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

  /// No description provided for @transfer.
  ///
  /// In uz, this message translates to:
  /// **'O\'tkazma'**
  String get transfer;

  /// No description provided for @selectProduct.
  ///
  /// In uz, this message translates to:
  /// **'Mahsulotni tanlang'**
  String get selectProduct;

  /// No description provided for @selectCustomer.
  ///
  /// In uz, this message translates to:
  /// **'Mijozni tanlang'**
  String get selectCustomer;

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

  /// No description provided for @registerScreenTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ro\'yxatdan o\'tish'**
  String get registerScreenTitle;

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

  /// No description provided for @darkMode.
  ///
  /// In uz, this message translates to:
  /// **'Qorong\'i'**
  String get darkMode;

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
