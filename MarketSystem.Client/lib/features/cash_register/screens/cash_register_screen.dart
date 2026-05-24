import 'package:flutter/material.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/cash_register/widgets/balance_card.dart';
import 'package:market_system_client/features/cash_register/widgets/payment_breakdown_card.dart';
import 'package:market_system_client/features/cash_register/widgets/today_sales_card.dart';
import 'package:market_system_client/features/cash_register/widgets/withdraw_bottom_sheet.dart';
import 'package:market_system_client/features/cash_register/widgets/withdraw_button.dart';
import 'package:market_system_client/features/cash_register/widgets/withdrawal_history_list.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/api_exception.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/cash_register_model.dart';
import '../../../data/services/cash_register_service.dart';
import '../../../data/services/http_service.dart';
import '../../../l10n/app_localizations.dart';

class CashRegisterScreen extends StatefulWidget {
  const CashRegisterScreen({super.key});

  @override
  State<CashRegisterScreen> createState() => _CashRegisterScreenState();
}

class _CashRegisterScreenState extends State<CashRegisterScreen> {
  final CashRegisterService _cashRegisterService = CashRegisterService(
    httpService: HttpService(),
  );

  CashRegisterModel? _cashRegister;
  TodaySalesSummaryModel? _todaySales;
  bool _isLoading = true;
  bool _isWithdrawing = false;

  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCashRegister();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadCashRegister() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _cashRegisterService.getCashRegister(),
      _cashRegisterService.getTodaySales(),
    ]);
    if (mounted) {
      setState(() {
        _cashRegister = results[0] as CashRegisterModel?;
        _todaySales = results[1] as TodaySalesSummaryModel?;
        _isLoading = false;
      });
    }
  }

  Future<void> _showWithdrawDialog() async {
    _amountController.clear();
    _commentController.clear();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WithdrawBottomSheet(
        amountController: _amountController,
        commentController: _commentController,
        cashBalance: _cashRegister?.currentBalance ?? 0,
        clickBalance: _todaySales?.clickPaid ?? 0,
        isWithdrawing: _isWithdrawing,
        onConfirm: (type) {
          Navigator.pop(context);
          _withdrawCash(type);
        },
      ),
    );
  }

  Future<void> _withdrawCash(String withdrawType) async {
    final l10n = AppLocalizations.of(context)!;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));

    if (amount == null || amount <= 0) {
      _showSnack(l10n.invalidInput, isError: true);
      return;
    }

    final availableBalance = withdrawType == 'cash'
        ? (_cashRegister?.currentBalance ?? 0)
        : (_todaySales?.clickPaid ?? 0);

    if (amount > availableBalance) {
      _showSnack(
        l10n.insufficientFundsWithBalance(availableBalance.toStringAsFixed(2)),
        isError: true,
      );
      return;
    }

    setState(() => _isWithdrawing = true);

    try {
      await _cashRegisterService.withdrawCash(
        amount,
        _commentController.text.trim(),
        withdrawType,
      );

      if (!mounted) return;
      _showSnack(
        l10n.withdrawalSuccessType(
          withdrawType == 'cash' ? l10n.cash : l10n.click,
        ),
        isError: false,
      );
      _loadCashRegister();
    } on ApiException catch (e) {
      if (!mounted) return;
      // G5 — K2 added Xmin on CashRegister.CurrentBalance, so two parallel
      // withdrawals will now surface the loser as 409. Show a refresh-and-
      // retry hint AND reload the till so the user sees the current balance
      // before they try again. Falls back to the server message (already
      // localised) for non-409 errors.
      if (e.isConflict) {
        _showSnack(l10n.concurrentChangeError, isError: true);
        _loadCashRegister();
      } else {
        _showSnack(
          e.message.isNotEmpty ? e.message : l10n.error,
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.error, isError: true);
    } finally {
      if (mounted) setState(() => _isWithdrawing = false);
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.xl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isAdmin = authProvider.can(Permissions.cashRegisterAccess);

    return NetworkWrapper(
      onRetry: _loadCashRegister,
      child: Scaffold(
        backgroundColor: context.colors.bg,
        // Bare AppBar (no CommonAppBar dependency) so the surface stays
        // crisp white and the title sits on the demo's brand-tinted hero
        // immediately below it.
        appBar: AppBar(
          backgroundColor: context.colors.surface,
          foregroundColor: context.colors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: context.colors.text,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            l10n.cashRegister,
            style: AppTextStyles.titleMedium().copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.text,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: context.colors.text),
              onPressed: _isLoading ? null : _loadCashRegister,
            ),
          ],
        ),
        body: !isAdmin
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: context.colors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.accessDenied,
                      style: AppTextStyles.titleMedium().copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadCashRegister,
                color: context.colors.brand,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.xl4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BalanceCard(
                        cashBalance: _cashRegister?.currentBalance ?? 0,
                        clickBalance: _todaySales?.clickPaid ?? 0,
                        lastUpdated: _cashRegister?.lastUpdated,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      // Dart-3 non-null pattern: matches when _todaySales
                      // is non-null and binds it as a non-nullable `s` so
                      // the cards below use it without `!` round-trips.
                      if (_todaySales case final s?) ...[
                        TodaySalesCard(todaySales: s),
                        const SizedBox(height: AppSpacing.xl),
                        if (s.cashPaid > 0 ||
                            s.cardPaid > 0 ||
                            s.clickPaid > 0) ...[
                          PaymentBreakdownCard(todaySales: s),
                          const SizedBox(height: AppSpacing.xl2),
                        ],
                      ],
                      WithdrawButton(
                        isWithdrawing: _isWithdrawing,
                        onTap: _showWithdrawDialog,
                        label: l10n.withdrawCash,
                      ),
                      const SizedBox(height: AppSpacing.xl3 + AppSpacing.xs),
                      Text(
                        l10n.withdrawalHistory.toUpperCase(),
                        style: AppTextStyles.labelSmall().copyWith(
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      WithdrawalHistoryList(
                        withdrawals: _cashRegister?.withdrawals ?? [],
                        l10n: l10n,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
