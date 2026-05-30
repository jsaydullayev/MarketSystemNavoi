// Owner / SuperAdmin "Xavfsizlik jurnali" screen — Plan 07 Bosqich 4.
//
// Two tabs:
//   • "Hammasi"   — paged audit log with EntityType / Action filter chips.
//   • "Shubhali"  — flagged groups from GET /audit-logs/suspicious, with a
//                   red accent so they pop out from the routine entries.
//
// Tenant scoping happens server-side (data.auditLog + role check). The
// Drawer entry on the dashboard is gated by `context.can('data.auditLog')`,
// which is true for Owner, SuperAdmin and any Admin the Owner granted.

import 'package:flutter/material.dart';

import '../../../data/services/audit_log_service.dart';
import '../../../design/tokens/app_theme_colors.dart';
import '../../../design/tokens/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import 'widgets/security_journal_all_view.dart';
import 'widgets/security_journal_suspicious_view.dart';

class SecurityJournalScreen extends StatefulWidget {
  const SecurityJournalScreen({super.key});

  @override
  State<SecurityJournalScreen> createState() => _SecurityJournalScreenState();
}

class _SecurityJournalScreenState extends State<SecurityJournalScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final AuditLogService _service = AuditLogService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: context.colors.bg,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        title: Text(l10n.securityJournal, style: AppTextStyles.titleMedium()),
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.brand,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: context.colors.brand,
          labelStyle: AppTextStyles.bodyLarge(),
          tabs: [
            Tab(text: l10n.securityJournalAllTab),
            Tab(text: l10n.securityJournalSuspiciousTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AllAuditLogsView(service: _service),
          SuspiciousView(service: _service),
        ],
      ),
    );
  }
}
