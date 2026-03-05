import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
import 'package:market_system_client/features/cash_register/widgets/balance_card.dart';
import 'package:market_system_client/features/cash_register/widgets/payment_breakdown_card.dart';
import 'package:market_system_client/features/cash_register/widgets/today_sales_card.dart';
import 'package:market_system_client/features/cash_register/widgets/withdraw_bottom_sheet.dart';
import 'package:market_system_client/features/cash_register/widgets/withdraw_button.dart';
import 'package:market_system_client/features/cash_register/widgets/withdrawal_history_list.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
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
  String? _selectedWithdrawType;

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
    _selectedWithdrawType = null;

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
        backgroundColor: isError ? AppTheme.danger : AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final role = authProvider.user?['role'];
    final isAdmin = role == 'Admin' || role == 'Owner';

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(title: l10n.cashRegister),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                l10n.accessDenied,
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      appBar: CommonAppBar(
        title: l10n.cashRegister,
        onRefresh: _isLoading ? null : _loadCashRegister,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCashRegister,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BalanceCard(
                      cashBalance: _cashRegister?.currentBalance ?? 0,
                      clickBalance: _todaySales?.clickPaid ?? 0,
                      lastUpdated: _cashRegister?.lastUpdated,
                    ),
                    const SizedBox(height: 16),
                    if (_todaySales != null) ...[
                      TodaySalesCard(todaySales: _todaySales!),
                      const SizedBox(height: 16),
                    ],
                    if (_todaySales != null &&
                        (_todaySales!.cashPaid > 0 ||
                            _todaySales!.cardPaid > 0 ||
                            _todaySales!.clickPaid > 0)) ...[
                      PaymentBreakdownCard(todaySales: _todaySales!),
                      const SizedBox(height: 20),
                    ],
                    WithdrawButton(
                      isWithdrawing: _isWithdrawing,
                      onTap: _showWithdrawDialog,
                      label: l10n.withdrawCash,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      l10n.withdrawalHistory,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    WithdrawalHistoryList(
                      withdrawals: _cashRegister?.withdrawals ?? [],
                      l10n: l10n,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
