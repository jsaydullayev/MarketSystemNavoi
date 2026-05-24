import '../../../core/auth/permissions.dart';

/// One toggleable permission row in the Owner permission-matrix screen.
class PermissionEntry {
  final String key;
  final String labelUz;
  final String labelRu;
  const PermissionEntry(this.key, this.labelUz, this.labelRu);

  String label(String lang) => lang == 'ru' ? labelRu : labelUz;
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
/// Uzbek/Russian labels. Mirrors the backend `PermissionKeys` catalogue —
/// keep the two in sync when keys are added.
const List<PermissionGroup> permissionGroups = [
  PermissionGroup('Boshqaruv paneli', 'Панель управления', [
    PermissionEntry(
      Permissions.dashboardAccess,
      'Panelga kirish',
      'Доступ к панели',
    ),
  ]),
  PermissionGroup('Mahsulotlar', 'Товары', [
    PermissionEntry(Permissions.productsAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(Permissions.productsCreate, "Qo'shish", 'Добавление'),
    PermissionEntry(Permissions.productsEdit, 'Tahrirlash', 'Редактирование'),
    PermissionEntry(Permissions.productsDelete, "O'chirish", 'Удаление'),
    PermissionEntry(
      Permissions.productsExport,
      'Excelga eksport',
      'Экспорт в Excel',
    ),
  ]),
  PermissionGroup('Kategoriyalar', 'Категории', [
    PermissionEntry(Permissions.categoriesAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(Permissions.categoriesManage, 'Boshqarish', 'Управление'),
  ]),
  PermissionGroup('Sotuvlar', 'Продажи', [
    PermissionEntry(Permissions.salesAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(
      Permissions.salesCreate,
      'Sotuv yaratish',
      'Создание продажи',
    ),
    PermissionEntry(
      Permissions.salesEdit,
      'Tahrirlash / qaytarish',
      'Редактирование / возврат',
    ),
    PermissionEntry(
      Permissions.salesDelete,
      "O'chirish / bekor qilish",
      'Удаление / отмена',
    ),
    PermissionEntry(
      Permissions.salesExport,
      'Excelga eksport',
      'Экспорт в Excel',
    ),
  ]),
  PermissionGroup('Mijozlar', 'Клиенты', [
    PermissionEntry(Permissions.customersAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(
      Permissions.customersManage,
      "Qo'shish / tahrirlash",
      'Добавление / редактирование',
    ),
    PermissionEntry(Permissions.customersDelete, "O'chirish", 'Удаление'),
    PermissionEntry(
      Permissions.customersExport,
      'Excelga eksport',
      'Экспорт в Excel',
    ),
  ]),
  PermissionGroup('Zakuplar', 'Закупки', [
    PermissionEntry(Permissions.zakupAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(
      Permissions.zakupCreate,
      'Zakup yaratish',
      'Создание закупки',
    ),
  ]),
  PermissionGroup('Kassa', 'Касса', [
    PermissionEntry(Permissions.cashRegisterAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(
      Permissions.cashRegisterManage,
      'Pul kiritish / chiqarish',
      'Внесение / снятие',
    ),
  ]),
  PermissionGroup('Hisobotlar', 'Отчёты', [
    PermissionEntry(Permissions.reportsAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(Permissions.reportsExport, 'Eksport', 'Экспорт'),
  ]),
  PermissionGroup('Foydalanuvchilar', 'Пользователи', [
    PermissionEntry(Permissions.usersAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(Permissions.usersManage, 'Boshqarish', 'Управление'),
    PermissionEntry(
      Permissions.usersShift,
      'Smena boshqaruvi',
      'Управление сменами',
    ),
  ]),
  PermissionGroup('Qarzlar', 'Долги', [
    PermissionEntry(Permissions.debtsAccess, "Ko'rish", 'Просмотр'),
    PermissionEntry(
      Permissions.debtsManage,
      "To'lov qabul qilish",
      'Приём оплаты',
    ),
  ]),
  PermissionGroup('Maxfiy maʼlumot', 'Конфиденциальные данные', [
    PermissionEntry(
      Permissions.dataCostPrice,
      'Xarid narxini ko‘rish',
      'Просмотр цены закупки',
    ),
    PermissionEntry(
      Permissions.dataProfit,
      'Foydani ko‘rish',
      'Просмотр прибыли',
    ),
    PermissionEntry(
      Permissions.dataCashBalance,
      'Kassa qoldig‘ini ko‘rish',
      'Просмотр остатка кассы',
    ),
    PermissionEntry(
      Permissions.dataAllSalesView,
      'Barcha sotuvlarni ko‘rish',
      'Просмотр всех продаж',
    ),
  ]),
];
