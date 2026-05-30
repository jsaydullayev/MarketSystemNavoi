// "Hammasi" tab for the security journal — paged audit log with
// EntityType / Action filter chips. Extracted from
// security_journal_screen.dart as a pure code-move.

import 'package:flutter/material.dart';

import '../../../../data/services/audit_log_service.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import 'security_journal_audit_log_card.dart';

/// Static catalogues for the filter chips. Kept untranslated — these are
/// canonical EntityType / Action keys the server stores verbatim, and the
/// "audit reviewer" persona is technical enough to read them.
const _entityTypes = <String>[
  'Sale',
  'Payment',
  'Zakup',
  'Debt',
  'Auth',
  'User',
  'Permission',
  'Market',
  'CashRegister',
  'Shift',
  'RegistrationRequest',
];

// G6 — must stay in lockstep with `MarketSystem.Domain/Constants/AuditEvents.cs`
// `AuditActions`. The backend will EMIT any action it lists; whatever isn't
// in this filter chip-list is still rendered as a row, just unfilterable.
// Last sync with backend Y1: added Deposit (cash AddCash), PasswordChange
// (UpdateProfile w/ new password), ShiftChange (admin sets seller shift),
// ProfileImageUpdate (avatar set/clear).
const _actions = <String>[
  'Create',
  'Update',
  'Delete',
  'Cancel',
  'Login',
  'LoginFailed',
  'Logout',
  'Activate',
  'Deactivate',
  'PermissionChange',
  'Block',
  'Unblock',
  'Withdraw',
  'Deposit',
  'Open',
  'Close',
  'PasswordChange',
  'ShiftChange',
  'ProfileImageUpdate',
];

class AllAuditLogsView extends StatefulWidget {
  const AllAuditLogsView({super.key, required this.service});

  final AuditLogService service;

  @override
  State<AllAuditLogsView> createState() => _AllAuditLogsViewState();
}

class _AllAuditLogsViewState extends State<AllAuditLogsView> {
  static const int _pageSize = 30;

  final ScrollController _scrollController = ScrollController();
  final List<AuditLogEntry> _items = [];

  int _page = 1;
  int _totalPages = 1;
  bool _isLoading = false;
  bool _initialFetchDone = false;

  String? _entityTypeFilter;
  String? _actionFilter;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirst());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isLoading || _page >= _totalPages) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadFirst() async {
    setState(() {
      _items.clear();
      _page = 1;
      _totalPages = 1;
      _isLoading = true;
    });
    final result = await widget.service.list(
      entityType: _entityTypeFilter,
      action: _actionFilter,
      page: 1,
      size: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      _isLoading = false;
      _initialFetchDone = true;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final next = _page + 1;
    final result = await widget.service.list(
      entityType: _entityTypeFilter,
      action: _actionFilter,
      page: next,
      size: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(result.items);
      _page = result.page;
      _totalPages = result.totalPages;
      _isLoading = false;
    });
  }

  Future<void> _refresh() => _loadFirst();

  void _setEntityType(String? value) {
    if (value == _entityTypeFilter) return;
    _entityTypeFilter = value;
    _loadFirst();
  }

  void _setAction(String? value) {
    if (value == _actionFilter) return;
    _actionFilter = value;
    _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        _FilterStrip(
          label: l10n.securityJournalFilterEntityType,
          options: _entityTypes,
          selected: _entityTypeFilter,
          onChanged: _setEntityType,
        ),
        _FilterStrip(
          label: l10n.securityJournalFilterAction,
          options: _actions,
          selected: _actionFilter,
          onChanged: _setAction,
        ),
        Divider(color: context.colors.borderSoft, height: 1),
        Expanded(child: _buildBody(l10n)),
      ],
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (!_initialFetchDone && _isLoading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.brand),
      );
    }
    if (_items.isEmpty) {
      return RefreshIndicator(
        color: context.colors.brand,
        onRefresh: _refresh,
        // A ListView with one item is the standard "empty state inside a
        // refresh indicator" trick — without something scrollable, the pull
        // gesture never fires.
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
                child: Text(
                  l10n.securityJournalEmptyAll,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium().copyWith(
                    color: context.colors.textMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: context.colors.brand,
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + (_page < _totalPages ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            // Loading footer for "next page in flight".
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: context.colors.brand,
                  ),
                ),
              ),
            );
          }
          return AuditLogCard(entry: _items[index]);
        },
      ),
    );
  }
}

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<String> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            child: Text(
              label,
              style: AppTextStyles.bodyMedium().copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _Chip(
                  label: l10n.securityJournalFilterAll,
                  selected: selected == null,
                  onTap: () => onChanged(null),
                ),
                for (final opt in options)
                  _Chip(
                    label: opt,
                    selected: selected == opt,
                    onTap: () => onChanged(opt),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? c.brand : c.inputFill,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: selected ? c.brand : c.border, width: 1),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.bodyMedium().copyWith(
              color: selected ? c.onBrand : c.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
