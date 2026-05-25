# State Management Guide

## Current reality

Three patterns coexist in the client. This is intentional — each covers a
distinct scope. The problem is that without a written rule, new developers
cannot predict which pattern to reach for.

| Pattern | Files | Callsites | Purpose |
|---|---|---|---|
| `ChangeNotifier` / Provider | 53 | — | App-wide shared state |
| `flutter_bloc` (BLoC) | 11 | — | Feature domain state (Clean-Arch features) |
| `setState` | 51 files | 260 | Ephemeral widget-local UI state |

---

## The rule

> **BLoC for Clean-Architecture features. Provider for app-wide shared state.
> setState for anything that lives and dies with one widget.**

Neither pattern is "better". They answer different questions:

- **Will another widget or screen ever need to read this state?**  
  → If yes and the feature has a domain layer → **BLoC**  
  → If yes and the state is global/cross-feature → **Provider**  
  → If no → **setState**

---

## Decision tree

```
New state needed?
│
├─ Is it ephemeral UI state?
│  (loading spinner, text field focus, accordion open/closed,
│   "is exporting" flag, selected tab index)
│  └─ YES → setState inside a StatefulWidget. Done.
│
├─ Is it shared across multiple widgets/screens?
│  ├─ Does it belong to a feature that already has a BLoC?
│  │  (sales, customers, zakup)
│  │  └─ YES → add an Event + State to the existing BLoC.
│  │
│  ├─ Is it truly app-wide / cross-feature?
│  │  (auth token, user profile, theme, locale, notifications)
│  │  └─ YES → ChangeNotifier registered in main_app.dart MultiProvider.
│  │
│  └─ New feature, no BLoC yet:
│     Does it have business logic that needs unit-testing
│     (use cases, repository calls, error states)?
│     ├─ YES → create a BLoC following the Clean Architecture pattern.
│     └─ NO  → ChangeNotifier is sufficient.
```

---

## When to introduce a new BLoC

Create a BLoC **only** when the feature has its own domain layer:

```
lib/features/<name>/
  domain/
    entities/         — pure data classes
    repositories/     — abstract interface
    use_cases/        — business logic
  data/
    repositories/     — concrete impl
  presentation/
    bloc/             — <name>_bloc.dart, <name>_event.dart, <name>_state.dart
    screens/
    widgets/
```

If the feature does **not** have this structure (flat
`lib/features/<name>/screens/` + one provider), keep it as Provider.
Do not bolt a BLoC onto a flat feature — that creates the worst of both worlds.

---

## File placement

### Clean-Architecture feature (BLoC)

```
lib/features/sales/
  domain/
    entities/sale_entity.dart
    repositories/sale_repository.dart
    use_cases/get_sales_use_case.dart
  data/
    repositories/sale_repository_impl.dart
  presentation/
    bloc/
      sales_bloc.dart      ← BLoC class (extends Bloc<Event, State>)
      sales_event.dart     ← sealed Event hierarchy
      sales_state.dart     ← sealed State hierarchy
    screens/
      sales_screen.dart    ← thin: BlocProvider + BlocBuilder/BlocConsumer
    widgets/               ← extracted sub-widgets (no BLoC awareness)
```

### Provider / ChangeNotifier feature

```
lib/features/products/
  providers/
    products_provider.dart   ← extends ChangeNotifier
  screens/
    products_screen.dart     ← context.watch<ProductsProvider>()
  widgets/
    product_tile.dart
```

Global providers are registered once in `lib/core/app/main_app.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    // ...
  ],
)
```

---

## Code examples

### Adding a new BLoC event (sales feature)

```dart
// 1. Add the event
class RefreshSalesEvent extends SalesEvent {
  const RefreshSalesEvent();
}

// 2. Handle it in the bloc
on<RefreshSalesEvent>((event, emit) async {
  emit(SalesLoading());
  final result = await getSales(NoParams());
  result.fold(
    (failure) => emit(SalesError(failure.message)),
    (sales)   => emit(SalesLoaded(sales)),
  );
});

// 3. Dispatch from the screen
context.read<SalesBloc>().add(const RefreshSalesEvent());
```

### Adding a new ChangeNotifier feature

```dart
// lib/features/notifications/providers/notification_provider.dart
class NotificationProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => _notifications;

  Future<void> load() async {
    _notifications = await _service.getAll();
    notifyListeners();
  }
}

// lib/features/notifications/screens/notifications_screen.dart
class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    return ListView.builder(
      itemCount: provider.notifications.length,
      itemBuilder: (_, i) => NotificationTile(provider.notifications[i]),
    );
  }
}
```

### Legitimate setState usage

`setState` is correct for state that is local to a single widget and would
not benefit from being in a BLoC or Provider:

```dart
class _SalesScreenState extends State<SalesScreen> {
  bool _isExporting = false;       // loading flag for a one-off action
  String? _selectedStatus;         // currently active filter chip

  Future<void> _exportPdf() async {
    setState(() => _isExporting = true);
    try {
      await _pdfService.export();
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }
}
```

Neither `_isExporting` nor `_selectedStatus` needs to survive navigation or
be read by another widget, so pulling them into BLoC would be over-engineering.

---

## Mixing rules

| Combination | Verdict | Notes |
|---|---|---|
| BLoC + `setState` | **OK** | setState for local UI toggles is fine even inside a BLoC screen. |
| BLoC + `Provider.of<AuthProvider>` | **OK** | Auth is app-wide; reading it from a BLoC screen is correct. |
| BLoC + a *feature-specific* ChangeNotifier in the same screen | **Violation** | Pick one pattern per feature's business state. |
| Two BLoCs for the same screen's domain | **Violation** | Merge them or extract a sub-feature. |

---

## Known violations (flag — do not refactor in this session)

The following screens currently mix patterns beyond the rules above.
Each should be addressed in a dedicated refactor commit, not as part of
an unrelated change.

| File | Violation | Suggested fix |
|---|---|---|
| `features/sales/presentation/screens/sales_screen.dart` | BLoC + `Provider.of<AuthProvider>` + `setState` for filter/export flags | The `Provider.of<AuthProvider>` read is legitimate (auth is global). `setState` for `_isExporting` / `_selectedStatus` is legitimate. No fix needed — this screen is actually following the rules correctly. |
| `features/customers/presentation/screens/customers_screen.dart` | `BlocBuilder` + `setState(() {})` on search listener | Move the search query into a `SearchCustomersEvent` so the BLoC owns the filter state; remove the `setState`. |
| `features/customers/presentation/screens/customer_detail_screen.dart` | BLoC consumer + `Provider.of<AuthProvider>` | Legitimate — auth is global. No fix needed. |
| `features/sales/presentation/screens/sale_detail_screen.dart` | `BlocBuilder` + direct `Provider.of<SalesProvider>` reads | `SalesProvider` should not exist alongside `SalesBloc` for the same feature. Determine which is authoritative and remove the other. |
| `features/zakup/presentation/screens/zakup_screen.dart` | `ZakupBloc` + `setState` for search / local filter | Same fix as customers_screen: push filter into a `FilterZakupEvent`. |
| `features/zakup/presentation/widgets/add_zakup_sheet.dart` | `ZakupBloc` dispatch + `setState` for local form state | `setState` for form validation state is legitimate. Keep it. |

> **Note:** `sales_screen.dart` was flagged as the "worst offender" in prior
> sessions because it has BLoC + Provider + setState. On closer inspection the
> three patterns serve three distinct scopes (domain state / global auth /
> ephemeral UI), which is correct. The real violations are `customers_screen`
> and `sale_detail_screen`.

---

## build_runner reminder

After converting any entity to `@JsonSerializable`, re-run:

```bash
dart run build_runner build
```

The `.g.dart` files are committed to git (not in `.gitignore`) so CI does
not need to run build_runner — but every developer changing an annotated
class must regenerate before committing.
