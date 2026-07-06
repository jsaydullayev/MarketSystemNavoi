// ignore_for_file: prefer_single_quotes
// Bilingual katalog ataylab tirnoqni aralashtiradi: o'zbekcha satrlar qo'sh
// tirnoqda (ular "Ko'rish" kabi apostrof saqlaydi), ruscha satrlar bir
// tirnoqda. Hamma joyda bir tirnoq majburlash \' escape'larni talab qilardi.
import '../../../core/auth/permissions.dart';

/// One toggleable permission row in the Owner permission-matrix screen.
///
/// [labelUz]/[labelRu] — short switch title (e.g. "Qo'shish").
/// [descUz]/[descRu]   — full, plain-language explanation of exactly what the
///                        permission unlocks. Shown as the switch subtitle so
///                        the Owner knows precisely what they are granting.
class PermissionEntry {
  final String key;
  final String labelUz;
  final String labelRu;
  final String descUz;
  final String descRu;
  const PermissionEntry(
    this.key,
    this.labelUz,
    this.labelRu, {
    required this.descUz,
    required this.descRu,
  });

  String label(String lang) => lang == 'ru' ? labelRu : labelUz;
  String desc(String lang) => lang == 'ru' ? descRu : descUz;
}

/// A section of related permissions, rendered as a titled card.
class PermissionGroup {
  final String titleUz;
  final String titleRu;
  final List<PermissionEntry> entries;
  const PermissionGroup(this.titleUz, this.titleRu, this.entries);

  String title(String lang) => lang == 'ru' ? titleRu : titleUz;
}

/// Owner-facing catalogue: every permission key grouped by domain, with
/// Uzbek/Russian labels + full descriptions. Mirrors the backend
/// `PermissionKeys` catalogue — keep the two in sync when keys are added.
const List<PermissionGroup> permissionGroups = [
  PermissionGroup('Boshqaruv paneli', 'Panel upravleniya', [
    PermissionEntry(
      Permissions.dashboardAccess,
      'Panelga kirish',
      'Dostup k paneli',
      descUz:
          "Bosh sahifani ochish va umumiy ko'rsatkichlarni — kunlik tushum, "
          "savdolar soni, kam qolgan tovarlar va tezkor bo'limlarni ko'rish.",
      descRu:
          'Открытие главной страницы и сводки: дневная выручка, число продаж, '
          'заканчивающиеся товары и быстрые разделы.',
    ),
  ]),
  PermissionGroup('Bildirishnomalar', 'Uvedomleniya', [
    PermissionEntry(
      Permissions.notificationsAccess,
      'Bildirishnoma olish',
      'Poluchenie uvedomleniy',
      descUz:
          "Bildirishnomalarni olish: kam qolgan tovarlar, to'lov muddati "
          "yaqinlashgan qarzlar va yangi qarzga yozilgan savdolar haqida "
          "ogohlantirish. O'chirilsa, xodimga qo'ng'iroq belgisi va "
          "bildirishnomalar sahifasi ko'rinmaydi.",
      descRu:
          'Получение уведомлений: заканчивающиеся товары, приближающийся срок '
          'оплаты долгов и новые продажи в долг. При отключении значок '
          'колокольчика и страница уведомлений скрываются.',
    ),
  ]),
  PermissionGroup('Mahsulotlar', 'Tovary', [
    PermissionEntry(
      Permissions.productsAccess,
      "Ko'rish",
      'Prosmotr',
      descUz:
          "Mahsulotlar bo'limini ochish; tovarlar ro'yxati, sotuv narxi va "
          "ombordagi qoldiqni ko'rish.",
      descRu:
          'Открытие раздела товаров; просмотр списка, цены продажи и остатка '
          'на складе.',
    ),
    PermissionEntry(
      Permissions.productsCreate,
      "Qo'shish",
      'Dobavlenie',
      descUz:
          "Yangi mahsulot qo'shish — nomi, sotuv narxi, o'lchov birligi va "
          "kategoriyasi bilan.",
      descRu:
          'Добавление нового товара — с названием, ценой продажи, единицей '
          'измерения и категорией.',
    ),
    PermissionEntry(
      Permissions.productsEdit,
      'Tahrirlash',
      'Redaktirovanie',
      descUz:
          "Mavjud mahsulotni tahrirlash: narx, nom, kategoriya, minimal qoldiq "
          "va narx ko'rinishini o'zgartirish.",
      descRu:
          'Редактирование товара: изменение цены, названия, категории, '
          'минимального остатка и видимости цены.',
    ),
    PermissionEntry(
      Permissions.productsDelete,
      "O'chirish",
      'Udalenie',
      descUz: "Mahsulotni ro'yxatdan butunlay o'chirish.",
      descRu: 'Полное удаление товара из списка.',
    ),
    PermissionEntry(
      Permissions.productsExport,
      'Excelga eksport',
      'Eksport v Excel',
      descUz: "Mahsulotlar ro'yxatini Excel faylga yuklab olish.",
      descRu: 'Выгрузка списка товаров в файл Excel.',
    ),
    PermissionEntry(
      Permissions.productsImport,
      'Exceldan import',
      'Import iz Excel',
      descUz:
          "Excel fayldan bir vaqtning o'zida ko'p mahsulotni import qilish.",
      descRu: 'Импорт множества товаров из файла Excel за один раз.',
    ),
  ]),
  PermissionGroup('Kategoriyalar', 'Kategorii', [
    PermissionEntry(
      Permissions.categoriesAccess,
      "Ko'rish",
      'Prosmotr',
      descUz: "Mahsulot kategoriyalari ro'yxatini ko'rish.",
      descRu: 'Просмотр списка категорий товаров.',
    ),
    PermissionEntry(
      Permissions.categoriesManage,
      'Boshqarish',
      'Upravlenie',
      descUz:
          "Kategoriya qo'shish, nomi va emoji'sini tahrirlash hamda o'chirish.",
      descRu:
          'Добавление, редактирование (название/эмодзи) и удаление категорий.',
    ),
  ]),
  PermissionGroup('Sotuvlar', 'Prodazhi', [
    PermissionEntry(
      Permissions.salesAccess,
      "Ko'rish",
      'Prosmotr',
      descUz:
          "Sotuvlar bo'limini ochish; savdolar ro'yxati, cheklar va ularning "
          "holatini ko'rish.",
      descRu:
          'Открытие раздела продаж; просмотр списка продаж, чеков и их статусов.',
    ),
    PermissionEntry(
      Permissions.salesCreate,
      'Sotuv yaratish',
      'Sozdanie prodazhi',
      descUz:
          "Yangi savdo yaratish, tovarlarni savatga qo'shish va to'lovni "
          "rasmiylashtirish.",
      descRu:
          'Создание новой продажи, добавление товаров в корзину и оформление '
          'оплаты.',
    ),
    PermissionEntry(
      Permissions.salesEdit,
      'Tahrirlash / qaytarish',
      'Redaktirovanie / vozvrat',
      descUz:
          "Savdoni tahrirlash: tovar narxini o'zgartirish yoki sotilgan tovarni "
          "qaytarish.",
      descRu:
          'Редактирование продажи: изменение цены товара или возврат проданного '
          'товара.',
    ),
    PermissionEntry(
      Permissions.salesDelete,
      "O'chirish / bekor qilish",
      'Udalenie / otmena',
      descUz: "Savdoni butunlay o'chirish yoki bekor qilish.",
      descRu: 'Удаление или отмена продажи.',
    ),
    PermissionEntry(
      Permissions.salesExport,
      'Excelga eksport',
      'Eksport v Excel',
      descUz: "Savdolarni Excel yoki PDF faylga yuklab olish.",
      descRu: 'Выгрузка продаж в файл Excel или PDF.',
    ),
    PermissionEntry(
      Permissions.salesInvoice,
      'Chek chop etish',
      'Pechat cheka',
      descUz: "Savdo cheki (hisob-faktura) PDF'ini yuklab olish va chop etish.",
      descRu: 'Скачивание и печать PDF-чека (счёта) продажи.',
    ),
  ]),
  PermissionGroup('Mijozlar', 'Klienty', [
    PermissionEntry(
      Permissions.customersAccess,
      "Ko'rish",
      'Prosmotr',
      descUz:
          "Mijozlar bo'limini ochish; mijozlar ro'yxati, telefon raqamlari va "
          "qarzlarini ko'rish.",
      descRu:
          'Открытие раздела клиентов; просмотр списка, телефонов и долгов.',
    ),
    PermissionEntry(
      Permissions.customersManage,
      "Qo'shish / tahrirlash",
      'Dobavlenie / redaktirovanie',
      descUz:
          "Yangi mijoz qo'shish va mavjud mijoz ma'lumotlarini (ism, telefon) "
          "tahrirlash.",
      descRu:
          'Добавление нового клиента и редактирование данных (имя, телефон).',
    ),
    PermissionEntry(
      Permissions.customersDelete,
      "O'chirish",
      'Udalenie',
      descUz: "Mijozni o'chirish.",
      descRu: 'Удаление клиента.',
    ),
    PermissionEntry(
      Permissions.customersExport,
      'Excelga eksport',
      'Eksport v Excel',
      descUz: "Mijozlar ro'yxatini Excel faylga yuklab olish.",
      descRu: 'Выгрузка списка клиентов в файл Excel.',
    ),
  ]),
  PermissionGroup('Zakuplar', 'Zakupki', [
    PermissionEntry(
      Permissions.zakupAccess,
      "Ko'rish",
      'Prosmotr',
      descUz: "Xaridlar (zakup) bo'limini ochish va xaridlar tarixini ko'rish.",
      descRu: 'Открытие раздела закупок и просмотр истории закупок.',
    ),
    PermissionEntry(
      Permissions.zakupCreate,
      'Zakup yaratish',
      'Sozdanie zakupki',
      descUz:
          "Yangi xarid (zakup) qo'shish — bu ombordagi tovar qoldig'ini "
          "oshiradi.",
      descRu:
          'Добавление новой закупки — пополняет остаток товара на складе.',
    ),
    PermissionEntry(
      Permissions.zakupDelete,
      "O'chirish",
      'Udalenie',
      descUz:
          "Xaridni (zakupni) o'chirish — u qo'shgan ombor qoldig'i qaytariladi "
          "(kamaytiriladi). Xato kiritilgan xaridni tozalash uchun.",
      descRu:
          'Удаление закупки — добавленный ею остаток на складе возвращается '
          '(вычитается). Для очистки ошибочной закупки.',
    ),
  ]),
  PermissionGroup('Kassa', 'Kassa', [
    PermissionEntry(
      Permissions.cashRegisterAccess,
      "Ko'rish",
      'Prosmotr',
      descUz:
          "Kassa bo'limini ochish; kassadagi pul harakati va qoldiqni ko'rish.",
      descRu: 'Открытие раздела кассы; просмотр движения денег и остатка.',
    ),
    PermissionEntry(
      Permissions.cashRegisterManage,
      'Pul kiritish / chiqarish',
      'Vnesenie / snyatie',
      descUz: "Kassaga pul kiritish yoki kassadan pul chiqarish (yechib olish).",
      descRu: 'Внесение денег в кассу или снятие (изъятие) из кассы.',
    ),
  ]),
  PermissionGroup('Hisobotlar', 'Otchyoty', [
    PermissionEntry(
      Permissions.reportsAccess,
      "Ko'rish",
      'Prosmotr',
      descUz:
          "Hisobotlar bo'limini ochish; kunlik/oylik statistika va ombor "
          "hisobotini ko'rish.",
      descRu:
          'Открытие раздела отчётов; дневная/месячная статистика и отчёт по '
          'складу.',
    ),
    PermissionEntry(
      Permissions.reportsExport,
      'Eksport',
      'Eksport',
      descUz: "Hisobotlarni Excel yoki PDF faylga yuklab olish.",
      descRu: 'Выгрузка отчётов в файл Excel или PDF.',
    ),
  ]),
  PermissionGroup('Foydalanuvchilar', 'Polzovateli', [
    PermissionEntry(
      Permissions.usersAccess,
      "Ko'rish",
      'Prosmotr',
      descUz:
          "Foydalanuvchilar (xodimlar) bo'limini ochish va xodimlar ro'yxatini "
          "ko'rish.",
      descRu: 'Открытие раздела сотрудников и просмотр списка.',
    ),
    PermissionEntry(
      Permissions.usersManage,
      'Boshqarish',
      'Upravlenie',
      descUz:
          "Yangi xodim qo'shish, ma'lumotini tahrirlash, bloklash yoki "
          "o'chirish.",
      descRu:
          'Добавление сотрудника, редактирование данных, блокировка или '
          'удаление.',
    ),
    PermissionEntry(
      Permissions.usersShift,
      'Smena boshqaruvi',
      'Upravlenie smenami',
      descUz:
          "Xodimlar smenasini ochish/yopish va ish vaqti (grafik)ni belgilash.",
      descRu:
          'Открытие/закрытие смены сотрудников и настройка рабочего графика.',
    ),
  ]),
  PermissionGroup('Qarzlar', 'Dolgi', [
    PermissionEntry(
      Permissions.debtsAccess,
      "Ko'rish",
      'Prosmotr',
      descUz: "Qarzlar bo'limini ochish va qarzdor mijozlar ro'yxatini ko'rish.",
      descRu: 'Открытие раздела долгов и просмотр списка должников.',
    ),
    PermissionEntry(
      Permissions.debtsManage,
      "To'lov qabul qilish",
      'Priyom oplaty',
      descUz: "Qarz bo'yicha to'lov qabul qilish (qisman yoki to'liq).",
      descRu: 'Приём оплаты по долгу (частично или полностью).',
    ),
    PermissionEntry(
      Permissions.debtsDueDate,
      "To'lov muddatini belgilash",
      'Ustanovka sroka oplaty',
      descUz:
          "Qarz uchun to'lov muddati (sanasi)ni belgilash yoki o'zgartirish.",
      descRu: 'Установка или изменение срока (даты) оплаты по долгу.',
    ),
  ]),
  PermissionGroup('Maxfiy malumot', 'Konfidencialnye dannye', [
    PermissionEntry(
      Permissions.dataCostPrice,
      "Xarid narxini ko'rish",
      'Prosmotr tseny zakupki',
      descUz:
          "Tovarning xarid (tan) narxini ko'rish. O'chirilsa, xodim faqat sotuv "
          "narxini ko'radi. Sotuvchi rolига hech qachon berilmaydi.",
      descRu:
          'Просмотр закупочной (себестоимость) цены товара. При отключении виден '
          'только цена продажи. Роли «Продавец» никогда не выдаётся.',
    ),
    PermissionEntry(
      Permissions.dataProfit,
      "Foydani ko'rish",
      'Prosmotr pribyli',
      descUz:
          "Sof foyda ko'rsatkichlarini ko'rish (sotuv narxi minus tan narx). "
          "Sotuvchi roliga hech qachon berilmaydi.",
      descRu:
          'Просмотр показателей чистой прибыли (цена продажи минус '
          'себестоимость). Роли «Продавец» никогда не выдаётся.',
    ),
    PermissionEntry(
      Permissions.dataCashBalance,
      "Kassa qoldiqini ko'rish",
      'Prosmotr ostatka kassy',
      descUz: "Kassadagi joriy pul qoldig'ini ko'rish.",
      descRu: 'Просмотр текущего остатка денег в кассе.',
    ),
    PermissionEntry(
      Permissions.dataAllSalesView,
      "Barcha sotuvlarni ko'rish",
      'Prosmotr vsekh prodazh',
      descUz:
          "Faqat o'zining emas, barcha sotuvchilarning savdolarini ko'rish va "
          "davom ettirish.",
      descRu:
          'Просмотр и продолжение продаж всех продавцов, а не только своих.',
    ),
    PermissionEntry(
      Permissions.dataAuditLog,
      "Audit jurnalini ko'rish",
      'Prosmotr zhurnala audita',
      descUz:
          "Audit jurnalini ko'rish — tizimda kim, qachon va nima o'zgartirganini "
          "kuzatish.",
      descRu:
          'Просмотр журнала аудита — кто, когда и что изменил в системе.',
    ),
  ]),
];
