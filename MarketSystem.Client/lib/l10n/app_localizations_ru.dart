// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Маркет Система';

  @override
  String get welcome => 'Добро пожаловать';

  @override
  String get login => 'Войти';

  @override
  String get register => 'Регистрация';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get fullName => 'Полное имя';

  @override
  String get role => 'Роль';

  @override
  String get language => 'Язык';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get uzbek => 'Узбекский';

  @override
  String get russian => 'Русский';

  @override
  String get logout => 'Выйти';

  @override
  String get logoutConfirm => 'Вы уверены, что хотите выйти?';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get dashboard => 'Панель управления';

  @override
  String get profile => 'Профиль';

  @override
  String get products => 'Товары';

  @override
  String get sales => 'Продажи';

  @override
  String get customers => 'Клиенты';

  @override
  String get zakup => 'Закупки';

  @override
  String get reports => 'Отчеты';

  @override
  String get debts => 'Долги';

  @override
  String get users => 'Пользователи';

  @override
  String get adminProducts => 'Админ: Товары';

  @override
  String get productList => 'Список товаров';

  @override
  String get productManagement => 'Управление товарами';

  @override
  String get salesHistory => 'История продаж';

  @override
  String get customerList => 'Список клиентов';

  @override
  String get purchaseHistory => 'История закупок';

  @override
  String get productPurchases => 'Закупки товаров';

  @override
  String get systemReports => 'Системные отчеты';

  @override
  String get customerDebts => 'Долги клиентов';

  @override
  String get userManagement => 'Управление пользователями';

  @override
  String get priceManagement => 'Управление ценами';

  @override
  String get profileSaved => 'Профиль сохранен';

  @override
  String get add => 'Добавить';

  @override
  String get edit => 'Редактировать';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get search => 'Поиск';

  @override
  String get filter => 'Фильтр';

  @override
  String get name => 'Название';

  @override
  String get quantity => 'Количество';

  @override
  String get costPrice => 'Закупочная цена';

  @override
  String get salePrice => 'Цена продажи';

  @override
  String get minSalePrice => 'Мин. цена продажи';

  @override
  String get minThreshold => 'Мин. порог';

  @override
  String get productBasicInfoSection => 'Основная информация';

  @override
  String get productNameHint => 'Например: Coca-Cola 1.5L';

  @override
  String get forDiscountHint => '(для скидки)';

  @override
  String get currentStockLabel => 'Текущий остаток';

  @override
  String get minStockLabel => 'Мин. остаток';

  @override
  String get forWarningHint => '(для предупр.)';

  @override
  String minSalePriceTip(String amount) {
    return 'Продавец может снизить цену для клиента до $amount UZS. Для более низкой цены нужно разрешение владельца.';
  }

  @override
  String get temporary => 'Временный';

  @override
  String get actions => 'Действия';

  @override
  String get loading => 'Загрузка...';

  @override
  String get error => 'Ошибка';

  @override
  String get success => 'Успешно';

  @override
  String get noData => 'Нет данных';

  @override
  String get confirmDelete => 'Вы уверены, что хотите удалить этот элемент?';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get total => 'Итого';

  @override
  String get from => 'С';

  @override
  String get to => 'По';

  @override
  String get paid => 'Оплачено';

  @override
  String get date => 'Дата';

  @override
  String get seller => 'Продавец';

  @override
  String get customer => 'Клиент';

  @override
  String get phone => 'Телефон';

  @override
  String get comment => 'Комментарий';

  @override
  String get status => 'Статус';

  @override
  String get draft => 'Черновик';

  @override
  String get completed => 'Завершено';

  @override
  String get cancelled => 'Отменено';

  @override
  String get active => 'Активный';

  @override
  String get inactive => 'Неактивный';

  @override
  String get owner => 'Владелец';

  @override
  String get admin => 'Администратор';

  @override
  String get loginSuccess => 'Вход выполнен успешно!';

  @override
  String get loginError => 'Ошибка входа. Проверьте свои данные.';

  @override
  String get registerSuccess => 'Регистрация прошла успешно!';

  @override
  String get registerError => 'Ошибка регистрации. Попробуйте еще раз.';

  @override
  String get updateError => 'Ошибка обновления.';

  @override
  String get deleteSuccess => 'Успешно удалено!';

  @override
  String get deleteError => 'Ошибка удаления.';

  @override
  String get enterUsername => 'Введите имя пользователя';

  @override
  String get enterPassword => 'Введите пароль';

  @override
  String get enterFullName => 'Введите полное имя';

  @override
  String get enterName => 'Введите имя';

  @override
  String get enterPhone => 'Введите номер телефона';

  @override
  String get quantityMustBePositive => 'Количество должно быть положительным';

  @override
  String get fieldRequired => 'Это поле обязательно';

  @override
  String get invalidInput => 'Неверный ввод';

  @override
  String get serverError => 'Ошибка сервера. Попробуйте позже.';

  @override
  String get networkError => 'Ошибка сети. Проверьте подключение.';

  @override
  String get updateProfile => 'Обновить профиль';

  @override
  String get changePassword => 'Изменить пароль';

  @override
  String get currentPassword => 'Текущий пароль';

  @override
  String get newPassword => 'Новый пароль';

  @override
  String get changePasswordHint => 'Введите текущий пароль для изменения';

  @override
  String get uploadImage => 'Загрузить изображение';

  @override
  String get uploadProfileImage => 'Загрузить фото профиля';

  @override
  String get imageUploadSuccess => 'Изображение успешно загружено!';

  @override
  String get imageUploadError => 'Не удалось загрузить изображение.';

  @override
  String get imageTooLarge =>
      'Размер изображения слишком большой. Максимальный размер 5МБ.';

  @override
  String get addProduct => 'Добавить товар';

  @override
  String get editProduct => 'Редактировать товар';

  @override
  String get addCustomer => 'Добавить клиента';

  @override
  String get editCustomer => 'Редактировать клиента';

  @override
  String get addSale => 'Добавить продажу';

  @override
  String get addPayment => 'Добавить платеж';

  @override
  String get cash => 'Наличные';

  @override
  String get card => 'Карта';

  @override
  String get noProducts => 'Нет товаров';

  @override
  String get noCustomers => 'Нет клиентов';

  @override
  String get createSale => 'Создать продажу';

  @override
  String get saleItems => 'Элементы продажи';

  @override
  String get payments => 'Платежи';

  @override
  String get addSaleItem => 'Добавить элемент';

  @override
  String get completeSale => 'Завершить продажу';

  @override
  String get cancelSale => 'Отменить продажу';

  @override
  String get saleCreated => 'Продажа успешно создана!';

  @override
  String get saleCompleted => 'Продажа успешно завершена!';

  @override
  String get saleCancelled => 'Продажа успешно отменена!';

  @override
  String get zakupCreated => 'Закупка успешно добавлена!';

  @override
  String get productUpdated => 'Товар успешно обновлен!';

  @override
  String get customerUpdated => 'Клиент успешно обновлен!';

  @override
  String get adminCanEditPrices =>
      'Примечание: Администраторы могут редактировать только цены, а не название или количество.';

  @override
  String get quantityUpdatedViaZakup =>
      'Количество обновляется только через Закупки.';

  @override
  String get createZakup => 'Создать закупку';

  @override
  String get zakupInfo => 'Информация о закупке';

  @override
  String get selectProductToAdd => 'Выберите товар для добавления на склад';

  @override
  String get quantityToAdd => 'Количество для добавления';

  @override
  String get purchasePrice => 'Цена закупки';

  @override
  String get totalCost => 'Общая стоимость';

  @override
  String get addToStock => 'Добавить на склад';

  @override
  String get dailyReport => 'Ежедневный отчет';

  @override
  String get periodReport => 'Периодический отчет';

  @override
  String get startDate => 'Дата начала';

  @override
  String get endDate => 'Дата окончания';

  @override
  String get generate => 'Сформировать';

  @override
  String get exportToExcel => 'Экспорт в Excel';

  @override
  String get totalSales => 'Общие продажи';

  @override
  String get totalPurchases => 'Общие закупки';

  @override
  String get profit => 'Прибыль';

  @override
  String get netIncome => 'Чистый доход';

  @override
  String get transactionCount => 'Количество транзакций';

  @override
  String get sellerName => 'Имя продавца';

  @override
  String get totalProfit => 'Общая прибыль';

  @override
  String get productName => 'Название товара';

  @override
  String get totalCostValue => 'Общая стоимость';

  @override
  String get totalSaleValue => 'Общая стоимость продажи';

  @override
  String get potentialProfit => 'Потенциальная прибыль';

  @override
  String get payDebt => 'Оплатить долг';

  @override
  String get debtPaid => 'Долг успешно оплачен!';

  @override
  String get amount => 'Сумма';

  @override
  String get paymentType => 'Тип платежа';

  @override
  String get remainingDebt => 'Остаток долга';

  @override
  String get totalDebt => 'Общий долг';

  @override
  String get userInformation => 'Информация о пользователе';

  @override
  String get readOnly => 'Только чтение';

  @override
  String get loginScreenTitle => 'Добро пожаловать!';

  @override
  String get loginScreenSubtitle => 'Войдите, чтобы продолжить';

  @override
  String get registerScreenSubtitle =>
      'Оставьте заявку — администратор скоро свяжется с вами';

  @override
  String get welcomeScreenTitle => 'Маркет Система';

  @override
  String get welcomeScreenSubtitle =>
      'Ваше комплексное решение для управления бизнесом';

  @override
  String get lightMode => 'Светлая';

  @override
  String get usernameMinLength => 'Имя пользователя минимум 3 символа';

  @override
  String get passwordMinLength => 'Пароль минимум 6 символов';

  @override
  String get passwordConfirm => 'Подтвердите пароль';

  @override
  String get passwordConfirmRequired => 'Подтверждение пароля обязательно';

  @override
  String get passwordMismatch => 'Пароли не совпадают';

  @override
  String get registerScreenTitle => 'Регистрация';

  @override
  String get createNewAccount => 'Создать новый аккаунт';

  @override
  String get fullNameTooShort => 'Слишком короткое имя';

  @override
  String get invalidPhoneFormat => 'Неверный формат номера телефона';

  @override
  String get submitRegistrationRequest => 'Отправить заявку';

  @override
  String get registrationSent =>
      'Заявка отправлена администратору. Скоро с вами свяжутся.';

  @override
  String registrationRateLimited(int seconds) {
    return 'Слишком много попыток. Повторите через $seconds секунд.';
  }

  @override
  String get registrationFailedRetry =>
      'Сейчас сервер недоступен. Пожалуйста, попробуйте позже.';

  @override
  String get backToLogin => 'Вернуться на страницу входа';

  @override
  String get saving => 'Сохранение...';

  @override
  String get cashRegister => 'Касса';

  @override
  String get currentBalance => 'Текущий баланс';

  @override
  String get lastUpdated => 'Последнее обновление';

  @override
  String get withdrawCash => 'Вывести деньги';

  @override
  String get withdrawalHistory => 'История выводов';

  @override
  String get noWithdrawals => 'История выводов пуста';

  @override
  String get insufficientFunds => 'Недостаточно средств';

  @override
  String get withdrawSuccess => 'Деньги успешно выведены';

  @override
  String get accessDenied => 'У вас нет доступа к этому разделу';

  @override
  String get info => 'Информация';

  @override
  String get registrationPendingInfo =>
      'Ваш запрос на регистрацию отправлен администратору. Скоро администратор разрешит регистрацию.';

  @override
  String get understand => 'Понятно';

  @override
  String get categories => 'Категории';

  @override
  String get dailySales => 'Ежедневные продажи';

  @override
  String get drafts => 'Драфты';

  @override
  String get darkMode => 'Темный режим';

  @override
  String get user => 'Пользователь';

  @override
  String get security => 'Безопасность';

  @override
  String get updateSuccess => 'Данные успешно обновлены';

  @override
  String get category => 'Категория';

  @override
  String get unit => 'Ед. изм.';

  @override
  String get minPrice => 'Мин. цена';

  @override
  String get temporaryProduct => 'Временный';

  @override
  String get none => 'Нет';

  @override
  String get stock => 'Запас';

  @override
  String get zakupSuccess => 'Закуп успешно добавлен!';

  @override
  String get number => 'Номер';

  @override
  String get addCategory => 'Добавить категорию';

  @override
  String get editCategory => 'Редактировать категорию';

  @override
  String get categoryName => 'Название категории';

  @override
  String get description => 'Описание';

  @override
  String get isActive => 'Активен';

  @override
  String get newSale => 'Новая продажа';

  @override
  String get totalAmount => 'Общая сумма';

  @override
  String get all => 'Все';

  @override
  String get debt => 'Долг';

  @override
  String get noCustomer => 'Без клиента';

  @override
  String get exportExcel => 'Экспорт в Excel';

  @override
  String get saleDetails => 'Детали продажи';

  @override
  String get soldProducts => 'Проданные товары';

  @override
  String get returnAmount => 'Сумма возврата';

  @override
  String get maxQuantity => 'Макс. количество';

  @override
  String get returnSuccess => 'Успешно возвращено';

  @override
  String get errorOccurred => 'Произошла ошибка';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get totalSum => 'Общая сумма';

  @override
  String get returnAction => 'Возврат';

  @override
  String get unknownProduct => 'Неизвестный товар';

  @override
  String get processReturn => 'Оформить возврат';

  @override
  String get maxReturn => 'Максимальный возврат';

  @override
  String get piece => 'шт';

  @override
  String get reasonOptional => 'Причина (опционально)';

  @override
  String get defect => 'Брак';

  @override
  String get finishReturn => 'Завершить возврат';

  @override
  String get price => 'Цена';

  @override
  String get saleAsDebt => 'Записано в долг';

  @override
  String get saleSuccess => 'Продано';

  @override
  String get cartEmptyWarning => 'Корзина пуста! Сначала добавьте товар';

  @override
  String get draftSaved => 'Продажа сохранена как черновик!';

  @override
  String get returnText => 'Возврат';

  @override
  String get saleText => 'Продажа';

  @override
  String get takeAsDebt => 'Взять в долг';

  @override
  String get terminal => 'Терминал';

  @override
  String get transfer => 'Перечисление';

  @override
  String get click => 'Click';

  @override
  String get enterCorrectAmount => 'Пожалуйста, введите правильную сумму';

  @override
  String get changeAmount => 'Сдача';

  @override
  String get youEntered => 'Вы ввели';

  @override
  String get totalAmountLabel => 'Общая сумма:';

  @override
  String get tooMuchAmount => 'Введена слишком большая сумма!';

  @override
  String get fullAmountWarning =>
      'Пожалуйста, введите полную сумму или выберите \"Записать в долг\".';

  @override
  String get newDebt => 'Новый долг';

  @override
  String get onDebt => 'В долг:';

  @override
  String get remaining => 'Остаток';

  @override
  String get selectCustomerForDebt =>
      'Для продажи в долг сначала выберите клиента';

  @override
  String get selectCustomer => 'Выберите клиента';

  @override
  String get clickPayment => 'Оплата через Click';

  @override
  String get transferAmount => 'Сумма перечисления (сум)';

  @override
  String get accountNumber => 'Номер счета';

  @override
  String get cardAmount => 'Сумма по карте';

  @override
  String get currencySom => 'сум';

  @override
  String get bankCard => 'Банковская карта';

  @override
  String get cashAmount => 'Сумма наличными';

  @override
  String get paymentMethods => 'Способы оплаты';

  @override
  String get invalidPriceOrQty => 'Ошибка количества или цены!';

  @override
  String get customerNotSelected => 'Клиент не выбран';

  @override
  String get searchProduct => 'Поиск товара...';

  @override
  String get warehouse => 'Склад';

  @override
  String get saveDraft => 'Да, сохранить';

  @override
  String get discardSale => 'Нет, выйти';

  @override
  String draftSavePrompt(Object count) {
    return 'В корзине $count товаров. Хотите сохранить как черновик?';
  }

  @override
  String get enterAmount => 'Введите сумму';

  @override
  String get saveSaleTitle => 'Сохранить продажу?';

  @override
  String get selectCustomerTitle => 'Выберите клиента';

  @override
  String get noCustomersFound => 'Клиенты не найдены';

  @override
  String get itemUpdated => 'изменено';

  @override
  String get draftSales => 'Продолжающиеся продажи';

  @override
  String get newUser => 'Новый пользователь';

  @override
  String get debtDetails => 'Детали долга';

  @override
  String get draftSale => 'Черновик продажи';

  @override
  String get debtors => 'Должники';

  @override
  String get noDebts => 'Долгов нет';

  @override
  String get debtHistory => 'История долгов';

  @override
  String get retry => 'Повторить попытку';

  @override
  String get customerDeleted => 'Клиент успешно удален';

  @override
  String get customerAdded => 'Клиент успешно добавлен';

  @override
  String get addNewCustomer => 'Добавить клиента';

  @override
  String get addCustomerForDebtHint => 'Добавить клиента';

  @override
  String get searchCustomer => 'Поиск клиента...';

  @override
  String get customerNotFound => 'Клиент не найден';

  @override
  String get phoneNumber => 'Номер телефона';

  @override
  String get fullNameOptional => 'Полное имя (необязательно)';

  @override
  String get commentOptional => 'Примечание (необязательно)';

  @override
  String get debtStatus => 'Статус долга';

  @override
  String get debtAmountSom => 'Сумма долга (сум)';

  @override
  String get debtAmountRequired => 'Необходимо ввести сумму долга';

  @override
  String get debtAmountPositive =>
      'Сумма долга должна быть положительным числом';

  @override
  String get debtRecordWillBeCreated =>
      'Для этого клиента будет создана запись о долге';

  @override
  String get noDebt => 'Без долга';

  @override
  String get yesDelete => 'Да, удалить';

  @override
  String deleteCustomerConfirm(Object name) {
    return 'Удалить $name?';
  }

  @override
  String get deleteCustomer => 'Удалить клиента';

  @override
  String get noProductsFound => 'Товары отсутствуют';

  @override
  String get inDebt => 'В долгу';

  @override
  String get debtor => 'Должник';

  @override
  String get phoneRequired => 'Необходимо ввести номер телефона';

  @override
  String get phoneFormatHint => 'Формат: 998XXXXXXXXX (12 цифр)';

  @override
  String get productNotFound => 'Товар не найден';

  @override
  String priceSom(Object price) {
    return 'Цена: $price сум';
  }

  @override
  String get selectProduct => 'Выберите товар';

  @override
  String addedBy(Object user) {
    return 'Добавил: $user';
  }

  @override
  String costPriceSom(Object price) {
    return 'Цена покупки: $price сум';
  }

  @override
  String get addPurchase => 'Добавить закуп';

  @override
  String get noPurchases => 'Закупок нет';

  @override
  String get errorLoadingData => 'Ошибка при загрузке данных';

  @override
  String get fileSaved => 'Файл сохранен';

  @override
  String get fileSaveError => 'Ошибка при сохранении файла';

  @override
  String get costPriceField => 'Цена покупки (сум)';

  @override
  String get noProductsAddFirst => 'Товаров нет. Сначала добавьте товар';

  @override
  String get onlyAdminOwnerCanAdd =>
      'Только Админ и Владелец могут добавлять закуп';

  @override
  String get fillAmountAndPrice => 'Заполните количество и цену';

  @override
  String get activated => 'Активировано';

  @override
  String get deactivated => 'Деактивировано';

  @override
  String get cannotDeleteSelf => 'Вы не можете удалить самого себя';

  @override
  String get deleteUser => 'Удалить пользователя';

  @override
  String deleteUserConfirm(Object name) {
    return 'Вы действительно хотите удалить $name?';
  }

  @override
  String get searchUser => 'Поиск пользователя...';

  @override
  String get userNotFound => 'Пользователь не найден';

  @override
  String get noUsersFound => 'Пользователи не найдены';

  @override
  String get nameRequired => 'Имя обязательно';

  @override
  String get usernameRequired => 'Username обязателен';

  @override
  String get minThreeChars => 'Минимум 3 символа';

  @override
  String get noSpacesAllowed => 'Пробелы не допускаются';

  @override
  String get passwordRequired => 'Пароль обязателен';

  @override
  String get confirmPasswordRequired => 'Подтверждение обязательно';

  @override
  String get userCreatedSuccess => 'Успешно создано!';

  @override
  String get giveCredentialsToUser =>
      'Передайте имя пользователя и пароль новому пользователю';

  @override
  String get noPermissionToEditdd =>
      'Нет прав для редактирования закрытого долга (только Owner/Admin)';

  @override
  String get priceUpdatedSuccess => 'Цена успешно обновлена';

  @override
  String get allDebtsPaid => 'Все долги оплачены';

  @override
  String debtCount(Object count) {
    return '$count долгов';
  }

  @override
  String get pay => 'Оплатить';

  @override
  String get cls => 'Закрыто';

  @override
  String get open => 'Открыто';

  @override
  String get ddDebtAudit =>
      'Этот долг закрыт. Изменение будет записано в аудит-лог.';

  @override
  String get exampleComment => 'Например: Была указана неверная цена';

  @override
  String get commentRequiredLabel => 'Комментарий (обязательно)';

  @override
  String get priceWithCurrency => 'Цена (сум)';

  @override
  String get newPriceLabel => 'Новая цена';

  @override
  String productQuantityAndOldPrice(Object price, Object quantity) {
    return '$quantity шт  ·  Старая цена: $price сум';
  }

  @override
  String get editPriceTitle => 'Редактировать цену';

  @override
  String get product => 'Продукт';

  @override
  String get yesConfirm => 'Да, подтверждаю';

  @override
  String confirmPriceChangeDesc(Object price) {
    return 'Вы хотите изменить цену на $price сум?';
  }

  @override
  String get commentRequiredError => 'Введите комментарий';

  @override
  String get priceMustBePositive => 'Цена должна быть больше 0';

  @override
  String get paymentSuccess => 'Оплата успешно произведена!';

  @override
  String get paymentAmountLabel => 'Сумма оплаты';

  @override
  String payingTooMuchWarning(Object amount) {
    return 'Вы платите на $amount сум больше суммы долга';
  }

  @override
  String get processPayment => 'Произвести оплату';

  @override
  String salesCount(Object count) {
    return '$count продаж';
  }

  @override
  String get netProfit => 'Чистая прибыль';

  @override
  String get noSalesToday => 'В этот день продаж нет';

  @override
  String get downloadExcel => 'Скачать Excel';

  @override
  String get reportDownloaded => 'Отчет загружен';

  @override
  String get downloadError => 'Ошибка при загрузке';

  @override
  String get reportDownloadSuccess => 'Отчет успешно загружен!';

  @override
  String get byPaymentType => 'По видам оплаты';

  @override
  String get select => 'Выбрать';

  @override
  String get noReports => 'Отчетов нет';

  @override
  String get totalValue => 'Общая стоимость';

  @override
  String get sellingPrice => 'Цена продажи';

  @override
  String get productCount => 'Количество товаров';

  @override
  String get incomingPrice => 'Приходная цена';

  @override
  String andMoreProducts(Object count) {
    return 'И еще $count товаров...';
  }

  @override
  String get totalSale => 'Общие продажи';

  @override
  String get saleCount => 'Количество продаж';

  @override
  String get averageSale => 'Средний чек';

  @override
  String get averageTransactionValue => 'Средняя сумма каждой продажи';

  @override
  String transactionStats(Object count, Object percentage) {
    return '$count транзакций  •  $percentage%';
  }

  @override
  String get daily => 'Ежедневно';

  @override
  String get monthly => 'Ежемесячно';

  @override
  String insufficientFundsWithBalance(Object balance) {
    return 'Недостаточно средств! В наличии: $balance сум';
  }

  @override
  String withdrawalSuccessType(Object type) {
    return '$type успешно выведены';
  }

  @override
  String get totalBalance => 'Общий баланс';

  @override
  String updatedAt(Object time) {
    return 'Обновлено: $time';
  }

  @override
  String get todaysIncomes => 'Сегодняшние поступления';

  @override
  String get cashMoney => 'Наличные деньги';

  @override
  String get todaysSales => 'Сегодняшние продажи';

  @override
  String itemsCount(Object count) {
    return '$count шт.';
  }

  @override
  String get selectPaymentTypeAndAmount => 'Выберите тип и сумму оплаты';

  @override
  String get paymentTypeLabel => 'Тип оплаты';

  @override
  String get waiting => 'Ожидание...';

  @override
  String get productRemoved => 'Товар удален';

  @override
  String get priceUpdated => 'Цена обновлена';

  @override
  String get productReturned => 'Товар возвращен';

  @override
  String get saleNotFound => 'Продажа не найдена';

  @override
  String get productsNotFound => 'Товары не найдены';

  @override
  String productAddedToCart(Object name) {
    return '$name добавлен в корзину';
  }

  @override
  String get changePrice => 'Изменить цену';

  @override
  String get currentPrice => 'Текущая цена';

  @override
  String quantityCount(Object quantity) {
    return 'Количество: $quantity шт.';
  }

  @override
  String priceChangedFor(Object name) {
    return 'Цена изменена для $name';
  }

  @override
  String get noSales => 'Продаж нет';

  @override
  String debtAmount(Object amount) {
    return 'Долг: $amount';
  }

  @override
  String get noDebtors => 'Должников нет';

  @override
  String get debtorsWillBeShownHere =>
      'Клиенты с долгами будут отображаться здесь';

  @override
  String get today => 'Сегодня';

  @override
  String get period7Days => '7 дней';

  @override
  String get period30Days => '30 дней';

  @override
  String get periodYear => 'Год';

  @override
  String get shiftSection => 'Рабочая смена';

  @override
  String get shiftStateActive => 'Смена активна';

  @override
  String get shiftStateBlocked => 'Заблокирована';

  @override
  String get shiftStateScheduled => 'По расписанию';

  @override
  String get shiftActivate => 'Активировать';

  @override
  String get shiftBlock => 'Заблокировать';

  @override
  String get shiftOpen24h => '24 часа';

  @override
  String get shiftSetWindow => 'Период';

  @override
  String get shiftUpdated => 'Смена обновлена';

  @override
  String get shiftActiveNow => 'Может работать';

  @override
  String get shiftInactiveNow => 'Не может работать';

  @override
  String get shiftInvalidWindow =>
      'Время окончания должно быть позже времени начала';

  @override
  String get yesterday => 'Вчера';

  @override
  String daysAgo(Object count) {
    return '$count дн. назад';
  }

  @override
  String monthsAgo(Object count) {
    return '$count мес. назад';
  }

  @override
  String yearsAgo(Object count) {
    return '$count г. назад';
  }

  @override
  String get deleteSale => 'Удалить продажу';

  @override
  String get deleteSaleConfirm =>
      'Вы действительно хотите удалить эту продажу?';

  @override
  String get noDebtSalesFound => 'Долговые продажи не найдены';

  @override
  String get debtorCustomers => 'Клиенты-должники';

  @override
  String get ongoing => 'В процессе';

  @override
  String get debtSales => 'Долговые продажи';

  @override
  String get paidSales => 'Оплаченные продажи';

  @override
  String get saleDeleted => 'Продажа удалена';

  @override
  String get saleInDebtUseDebtorsSection =>
      'Эта продажа в долг. Для оплаты используйте раздел \"Должники\".';

  @override
  String get saleAlreadyPaid =>
      'Эта продажа полностью оплачена. Изменения невозможны.';

  @override
  String get hourlySales => 'Почасовые продажи';

  @override
  String get draftSaveError => 'Ошибка при сохранении черновика';

  @override
  String get enterQuantityHint => 'Введите количество...';

  @override
  String get selectCustomerForDebtWarning =>
      'Для продажи в долг выберите клиента!';

  @override
  String get makePayment => 'ОПЛАТИТЬ';

  @override
  String get closed => 'Закрыто';

  @override
  String get customerRemoved => 'Клиент удален';

  @override
  String get removeCustomer => 'Удалить клиента';

  @override
  String get paymentMethod => 'Способ оплаты';

  @override
  String get paymentAmount => 'Сумма оплаты';

  @override
  String get selectPaymentMethod => 'Выберите способ оплаты';

  @override
  String get enterValidAmount => 'Введите корректную сумму';

  @override
  String get continueAction => 'Продолжить';

  @override
  String saleIdTitle(Object id) {
    return 'Продажа #$id';
  }

  @override
  String get noOngoingSales => 'Нет незавершенных продаж';

  @override
  String get initialSalesWillBeShownHere =>
      'Начатые продажи будут отображаться здесь';

  @override
  String get returnProduct => 'Возврат товара';

  @override
  String get availableQuantity => 'Доступное количество';

  @override
  String get returnQuantity => 'Количество возврата';

  @override
  String get invalidQuantity => 'Некорректное количество';

  @override
  String get paymentHistory => 'История платежей';

  @override
  String get hasDebt => 'Есть долг';

  @override
  String get noPayments => 'Платежей нет';

  @override
  String get noPermissionToEditClosed =>
      'Нет прав для редактирования закрытого долга (только Owner/Admin)';

  @override
  String get closedDebtAudit =>
      'Этот долг закрыт. Изменение будет записано в аудит-лог.';

  @override
  String get requestSentToAdmin => 'Запрос отправлен админу';

  @override
  String get requestSentDescription =>
      'Ваш запрос отправлен администратору. Мы свяжемся с вами после подтверждения.';

  @override
  String get back => 'Назад';

  @override
  String get marketName => 'Название маркета';

  @override
  String get enterMarketName => 'Введите название маркета';

  @override
  String get marketNameTooShort =>
      'Название маркета должно содержать минимум 3 символа';

  @override
  String get newCategory => 'Новая категория';

  @override
  String get fillIn => 'Заполните';

  @override
  String get addFirstCategory => 'Добавьте свою первую категорию';

  @override
  String get todaysReport => 'Сегодняшний отчёт';

  @override
  String get anonymousCustomer => 'Анонимный клиент';

  @override
  String get saleDetail => 'Детали продажи';

  @override
  String get registerMarket => 'Регистрация маркета';

  @override
  String get afterMarketRegisterInfo =>
      'После регистрации маркета вы сможете добавить пользователей Admin и Seller';

  @override
  String get descriptionOptional => 'Описание (опционально)';

  @override
  String get marketShortInfo => 'Краткая информация о маркете';

  @override
  String get subdomainRules =>
      'Можно использовать только строчные буквы, цифры и тире (-)';

  @override
  String get canBeLeftEmpty => 'Можно оставить пустым';

  @override
  String get exampleMyShop => 'Например: myshop';

  @override
  String get subdomainOptional => 'Субдомен (опционально)';

  @override
  String get pleaseEnterMarketName => 'Пожалуйста, введите название маркета';

  @override
  String get exampleMyStore => 'Например: Мой магазин';

  @override
  String get enterMarketDetails => 'Введите данные маркета';

  @override
  String get createYourMarket => 'Создайте свой собственный маркет';

  @override
  String get marketRegistration => 'Регистрация Маркета';

  @override
  String get nowYouCanAddUsers =>
      'Теперь вы можете добавлять пользователей Admin и Seller.';

  @override
  String get marketRegisteredSuccess => 'Маркет успешно зарегистрирован!';

  @override
  String get productUsedInSales =>
      'Этот товар использовался в продажах, его нельзя удалить';

  @override
  String get downloadPdf => 'Скачать PDF';

  @override
  String get pdfDownloaded => 'PDF успешно загружен';

  @override
  String get addExternalProduct => 'Добавить внешний продукт';

  @override
  String get externalProductName => 'Название внешнего продукта';

  @override
  String get externalCostPrice => 'Цена внешнего продукта';

  @override
  String get externalProductNameRequired =>
      'Введите название внешнего продукта';

  @override
  String get externalCostPriceRequired => 'Введите цену внешнего продукта';

  @override
  String get externalCostPriceGreaterThanSalePrice =>
      'Цена внешнего продукта не должна быть больше цены продажи';

  @override
  String get superAdminConsoleTitle => 'Панель SuperAdmin';

  @override
  String get superAdminTabRequests => 'Заявки';

  @override
  String get superAdminTabOwners => 'Активные владельцы';

  @override
  String get superAdminNoPendingRequests => 'Пока нет ожидающих заявок';

  @override
  String get superAdminNoActiveOwners => 'Нет активных владельцев';

  @override
  String get superAdminApprove => 'Одобрить';

  @override
  String get superAdminReject => 'Отклонить';

  @override
  String get superAdminApproveTitle => 'Одобрить заявку';

  @override
  String get superAdminRejectTitle => 'Отклонить заявку';

  @override
  String get superAdminRejectReason => 'Причина отклонения';

  @override
  String get superAdminRejectReasonHint =>
      'Не сообщается заявителю — только для аудита';

  @override
  String get superAdminRejectReasonRequired => 'Укажите причину';

  @override
  String get superAdminSubdomainOptional => 'Поддомен (необязательно)';

  @override
  String get superAdminSubdomainHint =>
      'Оставьте пустым — будет сгенерирован автоматически';

  @override
  String get superAdminPasswordMinLength => 'Пароль минимум 8 символов';

  @override
  String superAdminApproveSuccess(String username) {
    return 'Владелец $username создан. Передайте логин и пароль владельцу безопасным каналом.';
  }

  @override
  String get superAdminApproveFailed => 'Не удалось одобрить';

  @override
  String get superAdminRejectSuccess => 'Заявка отклонена';

  @override
  String get superAdminRejectFailed => 'Не удалось отклонить';

  @override
  String get superAdminLoadFailed => 'Не удалось загрузить данные';

  @override
  String get superAdminConsoleNotConfigured => 'Консоль не настроена';

  @override
  String get superAdminRebuildWithDartDefine =>
      'Соберите приложение с --dart-define=SUPERADMIN_CONSOLE_SEGMENT';

  @override
  String get superAdminCredentialsTitle => 'Сохраните учётные данные';

  @override
  String superAdminCredentialsSubtitle(String marketName) {
    return 'Скопируйте пароль для владельца магазина «$marketName» сейчас — позже восстановить не получится.';
  }

  @override
  String get superAdminCredentialsCopyBoth => 'Скопировать всё';

  @override
  String get superAdminCredentialsCopied => 'Скопировано';

  @override
  String get superAdminCredentialsDone => 'Готово';

  @override
  String get superAdminCredentialsWarning =>
      'Пароль нигде не хранится. После закрытия его уже не увидеть.';

  @override
  String get cartTitle => 'Корзина';

  @override
  String get viewEditCart => 'Просмотр / редактирование';

  @override
  String get productsInCartSuffix => 'товаров в корзине';

  @override
  String get greetingHello => 'Привет';

  @override
  String get todaysSale => 'Продажи за сегодня';

  @override
  String get checkLabel => 'Чек';

  @override
  String get mijozLabel => 'Клиент';

  @override
  String get profitLabel => 'Прибыль';

  @override
  String get statisticsSectionLabel => 'Статистика';

  @override
  String get alertsSectionLabel => 'Уведомления';

  @override
  String get weekProfit => 'Прибыль за неделю';

  @override
  String get monthRevenue => 'Оборот за месяц';

  @override
  String get topProduct => 'Топ товар';

  @override
  String get analysisSectionLabel => 'Анализ';

  @override
  String get reportsActionLabel => 'Отчёты';

  @override
  String get thisWeekLabel => 'Эта неделя';

  @override
  String get thisMonthLabel => 'Этот месяц';

  @override
  String get todayLabel => 'Сегодня';

  @override
  String get viewAll => 'Показать всё';

  @override
  String get bestSellersTitle => 'Самые продаваемые';

  @override
  String get oneSaleInProgress => '1 продажа в процессе';

  @override
  String get revenueLabel => 'Выручка';

  @override
  String get shiftLabel => 'Смена';

  @override
  String get refundLabel => 'Возврат';

  @override
  String get refundActionDesc => 'Возврат продажи';

  @override
  String get cashRegisterShort => 'Касса';

  @override
  String get defaultUserName => 'Пользователь';

  @override
  String get adminSectionLabel => 'Админ';

  @override
  String get reportLabel => 'Отчёт';

  @override
  String get tapToSelectProduct => 'Нажмите для выбора товара';

  @override
  String get hour => 'час';

  @override
  String get unitPiece => 'шт';

  @override
  String get thisWeek => 'Эта неделя';

  @override
  String get topSellersFallbackHint => 'Сегодня продаж не было — за неделю:';

  @override
  String get chartVsLastWeek => 'к прошлой неделе';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get notificationsEmptyTitle => 'Нет новых уведомлений';

  @override
  String get notificationsEmptyDescription =>
      'Всё в порядке. Нет товаров на исходе, новых долговых продаж или просроченных должников.';

  @override
  String get alertsOverdueTitle => 'Время оплаты подошло';

  @override
  String get alertsLowStockTitle => 'Товары на исходе';

  @override
  String get alertsRecentDebtTitle => 'Новые долговые продажи';

  @override
  String alertDescOverdue(int days, String amount) {
    return 'Долг $days дн. · $amount UZS';
  }

  @override
  String alertDescRecent(String amount) {
    return 'Сегодня · $amount UZS';
  }

  @override
  String alertDescLowStock(String qty, String unit, String threshold) {
    return 'Остаток: $qty $unit · мин $threshold $unit';
  }

  @override
  String alertDescLowStockNoMin(String qty, String unit) {
    return 'Остаток: $qty $unit';
  }

  @override
  String get fallbackCustomerName => 'Клиент';

  @override
  String get settingsSection => 'НАСТРОЙКИ';

  @override
  String get languageLabel => 'Язык';

  @override
  String get themeLabel => 'Тема';

  @override
  String get themeDark => 'Тёмная';

  @override
  String get themeLight => 'Светлая';

  @override
  String get lowStockShort => 'МАЛО';

  @override
  String get outOfStockShort => 'НЕТ';

  @override
  String get totalShort => 'ВСЕГО';

  @override
  String get stockShort => 'Остаток';

  @override
  String get popularChip => 'Популярный';

  @override
  String get editAction => 'Изменить';

  @override
  String get filterLowStock => 'Мало';

  @override
  String get filterOutOfStock => 'Нет в наличии';

  @override
  String get serverUnreachable => 'Не удалось подключиться к серверу';

  @override
  String get sessionExpired => 'Сессия истекла, войдите снова';

  @override
  String get noPermission => 'У вас нет прав';

  @override
  String get customEmojiHint => 'Введите свой эмодзи';

  @override
  String get filterOldDebt => 'Старый долг';

  @override
  String get filterRecent => 'Новые';

  @override
  String get pricesSection => 'Цены';

  @override
  String get shortCostPrice => 'Себестоимость';

  @override
  String get temporaryProductDesc => 'Временный товар';

  @override
  String get usersOnShiftShort => 'В СМЕНЕ';

  @override
  String get usersTodayRevenueShort => 'ВЫРУЧКА';

  @override
  String get shiftOpenLabel => 'Смена открыта';

  @override
  String get shiftClosedLabel => 'Смена закрыта';

  @override
  String get roleOwnerDesc => 'Полный доступ';

  @override
  String get roleAdminDesc => 'Продажи + товары';

  @override
  String get roleSellerDesc => 'Только продажи';

  @override
  String alertPreviewActiveDebts(int count) {
    return '$count активных долгов';
  }

  @override
  String alertPreviewActiveDebtsDesc(String amount) {
    return 'Всего: $amount UZS';
  }

  @override
  String alertPreviewOverdueDebts(int count) {
    return '$count просроченных платежей';
  }

  @override
  String get alertPreviewOverdueDebtsDesc => 'Свяжитесь с клиентом';

  @override
  String alertPreviewLowStock(int count) {
    return '$count товаров на исходе';
  }

  @override
  String get alertPreviewLowStockDesc => 'Нужно пополнить склад';

  @override
  String get alertPreviewEmpty => 'Уведомлений нет';

  @override
  String get alertPreviewEmptyDesc => 'Всё в порядке';

  @override
  String get quickActions => 'Быстрые действия';

  @override
  String get debtPayments => 'Принять оплату долга';

  @override
  String get pullToRefresh =>
      'Не удалось загрузить данные. Потяните вниз, чтобы повторить.';

  @override
  String get adminProductsManagement => 'Админ: Управление товарами';

  @override
  String get adminPriceTemporaryThresholdInfo =>
      'Админ может обновлять только цены, временный статус и минимальный порог. Название и количество товара изменить нельзя.';

  @override
  String get deleteProductTitle => 'Удалить товар';

  @override
  String deleteProductConfirm(String name) {
    return 'Вы действительно хотите удалить товар $name?';
  }

  @override
  String get productDeletedSuccess => 'Товар успешно удалён';

  @override
  String salePriceLabel(Object price) {
    return 'Цена продажи: $price сум';
  }

  @override
  String costPriceLabel(Object price) {
    return 'Себестоимость: $price сум';
  }

  @override
  String quantityImmutable(Object quantity, String unit) {
    return 'Количество: $quantity $unit (неизменяемое)';
  }

  @override
  String lowStockWarning(Object min) {
    return 'Мало! Мин: $min';
  }

  @override
  String get adminEditProductTitle => 'Админ: Редактирование товара';

  @override
  String get adminNewProductTitle => 'Админ: Новый товар';

  @override
  String get adminCanEditPriceAndSettings =>
      'Админ может изменять только цены и настройки';

  @override
  String get selectCategory => 'Выберите категорию';

  @override
  String get categoryNotSelected => 'Категория не выбрана';

  @override
  String get measureUnit => 'Единица измерения';

  @override
  String get selectUnit => 'Выберите единицу';

  @override
  String get temporaryProductTitle => 'Временный товар';

  @override
  String get temporaryProductDescription =>
      'Товар, временно хранимый на складе';

  @override
  String get salePriceField => 'Цена продажи (сум)';

  @override
  String get enterSalePrice => 'Введите цену продажи';

  @override
  String get enterValidPrice => 'Введите корректную цену';

  @override
  String get pricePositive => 'Цена должна быть положительной';

  @override
  String get minSalePriceField => 'Минимальная цена продажи (сум)';

  @override
  String get enterMinSalePrice => 'Введите минимальную цену продажи';

  @override
  String get priceNonNegative => 'Цена не может быть отрицательной';

  @override
  String get minThresholdField => 'Минимальный порог (для предупреждений)';

  @override
  String get enterMinThreshold => 'Введите минимальный порог';

  @override
  String get enterValidNumber => 'Введите корректное число';

  @override
  String get numberNonNegative => 'Число не может быть отрицательным';

  @override
  String productQuantityImmutable(Object quantity) {
    return 'Количество товара: $quantity (неизменяемое)';
  }

  @override
  String get productCreatedWithZeroInfo =>
      'Товар создаётся с количеством 0, затем увеличивается через Закупки';

  @override
  String errorWithMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get superAdminConsoleTitleShort => 'SuperAdmin Console';

  @override
  String get superAdminPending => 'В ожидании';

  @override
  String get superAdminNewRequests => 'Новые заявки';

  @override
  String get superAdminApproved => 'ОДОБРЕНО';

  @override
  String get superAdminRejected => 'ОТКЛОНЕНО';

  @override
  String get superAdminServerStatsNeeded => 'Требуется статистика сервера';

  @override
  String get superAdminPendingRequestsHeader => 'ОЖИДАЮЩИЕ ЗАЯВКИ';

  @override
  String get refresh => 'Обновить';

  @override
  String superAdminActiveOwnersHeader(Object count) {
    return 'АКТИВНЫЕ ВЛАДЕЛЬЦЫ ($count)';
  }

  @override
  String get addNew => 'Добавить';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String get newOwner => 'Новый Владелец';

  @override
  String newOwnerCreated(String username) {
    return 'Новый владелец создан: $username';
  }

  @override
  String get ownerSearchHint => 'Имя, username или название магазина…';

  @override
  String get statusBlocked => 'Заблокирован';

  @override
  String get statusActive => 'Активен';

  @override
  String get statusInactive => 'Неактивен';

  @override
  String get ownerInfoTitle => 'Информация о владельце';

  @override
  String get ownerNotFound => 'Владелец не найден';

  @override
  String get block => 'Заблокировать';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get infoUpdated => 'Информация обновлена';

  @override
  String get ownerSectionHeader => 'ИНФОРМАЦИЯ О ВЛАДЕЛЬЦЕ';

  @override
  String get shopSectionHeader => 'ИНФОРМАЦИЯ О МАГАЗИНЕ';

  @override
  String get fullNameUpper => 'ПОЛНОЕ ИМЯ';

  @override
  String get usernameUpper => 'USERNAME';

  @override
  String get phoneUpper => 'ТЕЛЕФОН';

  @override
  String get languageUpper => 'ЯЗЫК';

  @override
  String get registeredUpper => 'ЗАРЕГИСТРИРОВАН';

  @override
  String get statusUpper => 'СТАТУС';

  @override
  String get nameUpper => 'НАЗВАНИЕ';

  @override
  String get subdomainUpper => 'ПОДДОМЕН';

  @override
  String get marketIdUpper => 'MARKET ID';

  @override
  String get blockReasonUpper => 'ПРИЧИНА БЛОКИРОВКИ';

  @override
  String get blockedAtUpper => 'ЗАБЛОКИРОВАН';

  @override
  String get subscriptionExpiresUpper => 'ИСТЕЧЕНИЕ ПОДПИСКИ';

  @override
  String get createdUpper => 'СОЗДАНО';

  @override
  String registeredSince(String date) {
    return 'с $date';
  }

  @override
  String get updateInfoTitle => 'Обновить информацию';

  @override
  String get ownerSection => 'Владелец';

  @override
  String get shopSection => 'Магазин';

  @override
  String get fullNameLabel => 'Полное имя';

  @override
  String get nameRequiredShort => 'Имя обязательно';

  @override
  String get phoneLabel => 'Телефон';

  @override
  String get ownerActive => 'Владелец активен';

  @override
  String get shopName => 'Название магазина';

  @override
  String get minCharsShort => 'Мин. 3 символа';

  @override
  String get subdomainLabel => 'Поддомен';

  @override
  String get subdomainHintExample => 'subdomain.strotech.uz';

  @override
  String get descriptionLabel => 'Описание';

  @override
  String get shopActive => 'Магазин активен';

  @override
  String get updateFailed => 'Ошибка обновления';

  @override
  String get addNewOwner => 'Добавить нового владельца';

  @override
  String get createOwnerSubtitle =>
      'Эта форма обходит запрос на регистрацию. Используется только для особых случаев (звонки, индивидуальные обращения).';

  @override
  String get fullNameRequired => 'Полное имя *';

  @override
  String get phoneRequiredShort => 'Телефон обязателен';

  @override
  String get phoneFormatInvalid => 'Неверный формат';

  @override
  String get phoneHintExample => '+998 90 ...';

  @override
  String get usernameRequiredShort => 'username *';

  @override
  String get passwordRequiredShort => 'Пароль *';

  @override
  String get minThreeCharsShort => 'Мин. 3';

  @override
  String get minEightChars => 'Мин. 8';

  @override
  String get minEightCharsHelper => 'Мин. 8 символов';

  @override
  String get show => 'Показать';

  @override
  String get generatePassword => 'Сгенерировать';

  @override
  String get shopNameRequired => 'Название магазина *';

  @override
  String get subdomainOptionalShort => 'поддомен (опционально)';

  @override
  String get autoLabel => 'Авто: ';

  @override
  String get urlLabel => 'URL: ';

  @override
  String get create => 'Создать';

  @override
  String get createOwnerFailed => 'Ошибка при создании';

  @override
  String usernameTaken(String username) {
    return '\'$username\' занят';
  }

  @override
  String marketNameTaken(String name) {
    return '\'$name\' занято';
  }

  @override
  String subdomainTaken(String subdomain) {
    return '\'$subdomain\' занят';
  }

  @override
  String get confirmDeleteTitle => 'Подтвердите удаление';

  @override
  String get cannotUndoAction => 'Это действие нельзя отменить';

  @override
  String get warning => 'ВНИМАНИЕ!';

  @override
  String get deleteOwnerPart1 => 'Вы ';

  @override
  String get deleteOwnerPart2 => ' и его магазин ';

  @override
  String get deleteOwnerPart3 => ' собираетесь удалить.';

  @override
  String get dataWillBeKept =>
      'Следующие данные сохранятся (только деактивация владельца+магазина):';

  @override
  String get countProducts => 'товаров';

  @override
  String get countSales => 'продаж';

  @override
  String get countCustomers => 'клиентов';

  @override
  String get countCashiers => 'аккаунтов кассиров';

  @override
  String get enterShopNameUpper => 'ВВЕДИТЕ НАЗВАНИЕ МАГАЗИНА *';

  @override
  String typeShopNameExact(String name) {
    return 'Введите точно \"$name\"';
  }

  @override
  String get shopNameMismatch => 'Название магазина не совпадает';

  @override
  String get deleteReasonUpper => 'ПРИЧИНА УДАЛЕНИЯ *';

  @override
  String get deleteReasonHint => 'Например: Просрочка оплаты и нет связи';

  @override
  String get reasonRequiredDetailed => 'Опишите причину подробно';

  @override
  String get deleteFailed => 'Ошибка при удалении';

  @override
  String get blockShopTitle => 'Заблокировать магазин';

  @override
  String get blocking => 'Блокируется: ';

  @override
  String get unblocking => 'Разблокируется: ';

  @override
  String get blockImmediateInfo =>
      'Блокировка вступает в силу немедленно: Владелец и все сотрудники магазина (Admin/Seller) не смогут войти. Старые JWT токены также вернут 423.';

  @override
  String get blockReasonRequired => 'ПРИЧИНА БЛОКИРОВКИ *';

  @override
  String get blockReasonHint =>
      'Например: Просрочка оплаты подписки на 30 дней';

  @override
  String get unblockInfo =>
      'После разблокировки Владелец и сотрудники снова смогут войти.';

  @override
  String get previousBlockReason => 'ПРИЧИНА БЛОКИРОВКИ (РАНЕЕ):';

  @override
  String get blockFailed => 'Ошибка при блокировке';

  @override
  String get unblockFailed => 'Ошибка при разблокировке';

  @override
  String get ok => 'OK';

  @override
  String get privacyPolicyTitle => 'Политика конфиденциальности';

  @override
  String get privacyIntroTitle => 'Введение';

  @override
  String get privacyDataCollectionTitle => 'Сбор данных';

  @override
  String get privacyDataUsageTitle => 'Использование данных';

  @override
  String get privacyDataSecurityTitle => 'Безопасность данных';

  @override
  String get privacyYourRightsTitle => 'Ваши права';

  @override
  String get privacyContactTitle => 'Контактная информация';

  @override
  String get privacyContactPrompt =>
      'Если у вас есть вопросы о настоящей Политике конфиденциальности или ваших данных, свяжитесь с нами:';

  @override
  String get emailLabel => 'Email: ';

  @override
  String get noAccount => 'Нет аккаунта? ';

  @override
  String get loginLabel => 'Логин';

  @override
  String get loginHint => 'Введите логин';

  @override
  String get passwordHint => 'Введите пароль';

  @override
  String get loginButton => 'Войти';

  @override
  String get loginAction => 'Войти в систему';

  @override
  String get loginFormSubtitle => 'Введите ваш логин и пароль';

  @override
  String get appTagline => 'Торговая система для малого бизнеса';

  @override
  String get welcomeSubtitle => 'Система продаж и учёта для малых магазинов';

  @override
  String get registerShop => 'Новый магазин — регистрация';

  @override
  String get agreePrefix => 'Продолжая, вы соглашаетесь с ';

  @override
  String get agreeSuffix => '';

  @override
  String get rememberMe => 'Запомнить';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get dateTimeLabel => 'Дата / время';

  @override
  String get statusLabel => 'Статус';

  @override
  String get externalTag => 'внешний';

  @override
  String get printAction => 'Распечатать';

  @override
  String get sendSms => 'Отправить SMS';

  @override
  String get comingSoon => 'Скоро...';

  @override
  String get returnWarning =>
      'Возврат уведомит владельца и вернёт товар на склад';

  @override
  String get whichProductReturning => 'КАКОЙ ТОВАР ВОЗВРАЩАЕТСЯ?';

  @override
  String soldQtyFormat(Object qty, String price) {
    return 'Продано: $qty × $price';
  }

  @override
  String get reasonLabel => 'ПРИЧИНА';

  @override
  String get returnReasonBad => 'Бракованный';

  @override
  String get returnReasonExpired => 'Просроченный';

  @override
  String get returnReasonDisliked => 'Не понравился';

  @override
  String get returnReasonOther => 'Другое';

  @override
  String get additionalCommentHint =>
      'Дополнительный комментарий (необязательно)';

  @override
  String get returnMethodLabel => 'МЕТОД ВОЗВРАТА';

  @override
  String get cashReturn => 'Возврат наличными';

  @override
  String get toCustomerHere => 'Клиенту на месте';

  @override
  String get toBalance => 'На баланс';

  @override
  String get forNextSale => 'В счёт следующей покупки';

  @override
  String get toReturnLabel => 'ВОЗВРАЩАЕТСЯ';

  @override
  String get confirmAndReturn => 'Подтвердить и вернуть';

  @override
  String get orDivider => 'ИЛИ';

  @override
  String get createNewShop => 'Создать новый магазин';

  @override
  String get statProducts => 'Товары';

  @override
  String get statSales => 'Продажи';

  @override
  String get statCustomers => 'Клиенты';

  @override
  String get statActiveTypes => 'Активных видов';

  @override
  String get statTotalReceipts => 'Всего чеков';

  @override
  String get statActiveCustomers => 'Активных клиентов';

  @override
  String get statTotalUZS => 'Итого UZS';

  @override
  String get paymentCash => 'Наличные';

  @override
  String get paymentRefund => 'Возврат';

  @override
  String get forgotPasswordContactAdmin =>
      'Для восстановления пароля обратитесь к администратору.';

  @override
  String get loginFailed => 'Неверный логин или пароль.';

  @override
  String get rateLimited =>
      'Слишком много попыток. Пожалуйста, подождите и попробуйте снова.';

  @override
  String get loginGenericError => 'Произошла ошибка.';

  @override
  String get shopBlocked => 'Магазин заблокирован';

  @override
  String get shopBlockedBody =>
      'Ваш магазин заблокирован администратором. Пожалуйста, свяжитесь с администратором.';

  @override
  String blockedAtLabel(String time) {
    return 'Заблокирован: $time';
  }

  @override
  String get dismiss => 'Понятно';

  @override
  String get permissionsTitle => 'Права доступа';

  @override
  String get permissionsNextLoginNote =>
      'Изменения вступят в силу при следующем входе пользователя.';

  @override
  String get resetToDefault => 'Сбросить к стандартным';

  @override
  String get permissionsSaved => 'Права сохранены';

  @override
  String get permissionsUsingRoleDefaults => 'Стандартные права по роли';

  @override
  String get permissionsCustomized => 'Настроено вручную';

  @override
  String get managePermissions => 'Управление правами';

  @override
  String get shiftOpen => 'Смена открыта';

  @override
  String get shiftClosed => 'Смена закрыта';

  @override
  String get openShift => 'Открыть смену';

  @override
  String get closeShift => 'Закрыть смену';

  @override
  String shiftStartedAt(String time) {
    return 'Начата: $time';
  }
}
