import 'package:flutter/material.dart';
import 'package:market_system_client/core/widgets/network_wrapper.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/features/cash_register/widgets/balance_card.dart';
import 'package:market_system_client/features/cash_register/widgets/payment_breakdown_card.dart';
import 'package:market_system_client/features/cash_register/widgets/today_sales_card.dart';
import 'package:market_system_client/features/cash_register/widgets/withdraw_bottom_sheet.dart';
import 'package:market_system_client/features/cash_register/widgets/withdraw_button.dart';
import 'package:market_system_client/features/cash_register/widgets/withdrawal_history_list.dart';
import 'package:provider/provider.dart';
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

    final success = await _cashRegisterService.withdrawCash(
      amount,
      _commentController.text.trim(),
      withdrawType,
    );

    setState(() => _isWithdrawing = false);
    if (!mounted) return;

    if (success) {
      _showSnack(
        l10n.withdrawalSuccessType(
            withdrawType == 'cash' ? l10n.cash : l10n.click),
        isError: false,
      );
      _loadCashRegister();
    } else {
      _showSnack(l10n.error, isError: true);
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
    final role = authProvider.user?['role'];
    final isAdmin = role == 'Admin' || role == 'Owner';

    return NetworkWrapper(
      onRetry: _loadCashRegister,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        // Bare AppBar (no CommonAppBar dependency) so the surface stays
        // crisp white and the title sits on the demo's brand-tinted hero
        // immediately below it.
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: AppColors.text,
            ),
            onPressed: () => Navigator.maybePop(context),
          ),
          title: Text(
            l10n.cashRegister,
            style: AppTextStyles.titleMedium().copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
              onPressed: _isLoading ? null : _loadCashRegister,
            ),
          ],
        ),
        body: !isAdmin
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      l10n.accessDenied,
                      style: AppTextStyles.titleMedium().copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadCashRegister,
                    color: AppColors.brand,
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
                          if (_todaySales != null) ...[
                            TodaySalesCard(todaySales: _todaySales!),
                            const SizedBox(height: AppSpacing.xl),
                          ],
                          if (_todaySales != null &&
                              (_todaySales!.cashPaid > 0 ||
                                  _todaySales!.cardPaid > 0 ||
                                  _todaySales!.clickPaid > 0)) ...[
                            PaymentBreakdownCard(todaySales: _todaySales!),
                            const SizedBox(height: AppSpacing.xl2),
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
