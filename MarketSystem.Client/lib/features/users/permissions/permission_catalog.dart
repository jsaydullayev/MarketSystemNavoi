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
  PermissionGroup('Boshqaruv paneli', 'Panel upravleniya', [
    PermissionEntry(
      Permissions.dashboardAccess,
      'Panelga kirish',
      'Dostup k paneli',
    ),
  ]),
  PermissionGroup('Mahsulotlar', 'Tovary', [
    PermissionEntry(Permissions.productsAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(Permissions.productsCreate, "Qo'shish", 'Dobavlenie'),
    PermissionEntry(Permissions.productsEdit, 'Tahrirlash', 'Redaktirovanie'),
    PermissionEntry(Permissions.productsDelete, "O'chirish", 'Udalenie'),
    PermissionEntry(
      Permissions.productsExport,
      'Excelga eksport',
      'Eksport v Excel',
    ),
    PermissionEntry(
      Permissions.productsImport,
      'Exceldan import',
      'Import iz Excel',
    ),
  ]),
  PermissionGroup('Kategoriyalar', 'Kategorii', [
    PermissionEntry(Permissions.categoriesAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(Permissions.categoriesManage, 'Boshqarish', 'Upravlenie'),
  ]),
  PermissionGroup('Sotuvlar', 'Prodazhi', [
    PermissionEntry(Permissions.salesAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(
      Permissions.salesCreate,
      'Sotuv yaratish',
      'Sozdanie prodazhi',
    ),
    PermissionEntry(
      Permissions.salesEdit,
      'Tahrirlash / qaytarish',
      'Redaktirovanie / vozvrat',
    ),
    PermissionEntry(
      Permissions.salesDelete,
      "O'chirish / bekor qilish",
      'Udalenie / otmena',
    ),
    PermissionEntry(
      Permissions.salesExport,
      'Excelga eksport',
      'Eksport v Excel',
    ),
  ]),
  PermissionGroup('Mijozlar', 'Klienty', [
    PermissionEntry(Permissions.customersAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(
      Permissions.customersManage,
      "Qo'shish / tahrirlash",
      'Dobavlenie / redaktirovanie',
    ),
    PermissionEntry(Permissions.customersDelete, "O'chirish", 'Udalenie'),
    PermissionEntry(
      Permissions.customersExport,
      'Excelga eksport',
      'Eksport v Excel',
    ),
  ]),
  PermissionGroup('Zakuplar', 'Zakupki', [
    PermissionEntry(Permissions.zakupAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(
      Permissions.zakupCreate,
      'Zakup yaratish',
      'Sozdanie zakupki',
    ),
  ]),
  PermissionGroup('Kassa', 'Kassa', [
    PermissionEntry(Permissions.cashRegisterAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(
      Permissions.cashRegisterManage,
      'Pul kiritish / chiqarish',
      'Vnesenie / snyatie',
    ),
  ]),
  PermissionGroup('Hisobotlar', 'Otchyoty', [
    PermissionEntry(Permissions.reportsAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(Permissions.reportsExport, 'Eksport', 'Eksport'),
  ]),
  PermissionGroup('Foydalanuvchilar', 'Polzovateli', [
    PermissionEntry(Permissions.usersAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(Permissions.usersManage, 'Boshqarish', 'Upravlenie'),
    PermissionEntry(
      Permissions.usersShift,
      'Smena boshqaruvi',
      'Upravlenie smenami',
    ),
  ]),
  PermissionGroup('Qarzlar', 'Dolgi', [
    PermissionEntry(Permissions.debtsAccess, "Ko'rish", 'Prosmotr'),
    PermissionEntry(
      Permissions.debtsManage,
      "To'lov qabul qilish",
      'Priyom oplaty',
    ),
  ]),
  PermissionGroup('Maxfiy malumot', 'Konfidencialnye dannye', [
    PermissionEntry(
      Permissions.dataCostPrice,
      "Xarid narxini ko'rish",
      'Prosmotr tseny zakupki',
    ),
    PermissionEntry(
      Permissions.dataProfit,
      "Foydani ko'rish",
      'Prosmotr pribyli',
    ),
    PermissionEntry(
      Permissions.dataCashBalance,
      "Kassa qoldiqini ko'rish",
      'Prosmotr ostatka kassy',
    ),
    PermissionEntry(
      Permissions.dataAllSalesView,
      "Barcha sotuvlarni ko'rish",
      'Prosmotr vsekh prodazh',
    ),
    PermissionEntry(
      Permissions.dataAuditLog,
      "Audit jurnalini ko'rish",
      'Prosmotr zhurnala audita',
    ),
  ]),
];
