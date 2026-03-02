import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/core/widgets/common_app_bar.dart';
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

  // Withdraw type
  String? _selectedWithdrawType; // 'cash' or 'click'

  Future<void> _showWithdrawDialog() async {
    final l10n = AppLocalizations.of(context)!;

    _amountController.clear();
    _commentController.clear();
    _selectedWithdrawType = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.withdrawCash),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pul turi tanlash
                const Text('Pul turi:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Naqd'),
                        value: 'cash',
                        groupValue: _selectedWithdrawType,
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedWithdrawType = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Click'),
                        value: 'click',
                        groupValue: _selectedWithdrawType,
                        onChanged: (value) {
                          setDialogState(() {
                            _selectedWithdrawType = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    labelText: l10n.comment,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: (_selectedWithdrawType == null || _isWithdrawing)
                    ? null
                    : () {
                        Navigator.pop(context);
                        _withdrawCash(_selectedWithdrawType!);
                      },
                child: _isWithdrawing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.confirm),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _withdrawCash(String withdrawType) async {
    final l10n = AppLocalizations.of(context)!;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidInput)),
      );
      return;
    }

    // Balansni tekshirish
    final cashBalance = _cashRegister?.currentBalance ?? 0;
    final clickBalance = _todaySales?.clickPaid ?? 0;
    final availableBalance =
        withdrawType == 'cash' ? cashBalance : clickBalance;

    if (amount > availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Yetarli pul yo\'q! Mavjud: ${availableBalance.toStringAsFixed(2)} so\'m'),
          backgroundColor: AppTheme.danger,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${withdrawType == 'cash' ? 'Naqd pul' : 'Click'} muvaffaqiyatli olindi'),
          backgroundColor: AppTheme.success,
        ),
      );
      _loadCashRegister();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.error),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Faqat admin va owner uchun
    final isAdmin = authProvider.user?['role'] == 'Admin' ||
        authProvider.user?['role'] == 'Owner';

    if (!isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.getBg(isDark),
        appBar: CommonAppBar(
          title: l10n.cashRegister,
        ),
        body: Center(
          child: Text(
            l10n.accessDenied,
            style: const TextStyle(fontSize: 18),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primary,
                            AppTheme.primary.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.currentBalance,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Jami balans (naqd + click)
                          Text(
                            '${(_cashRegister?.currentBalance ?? 0) + (_todaySales?.clickPaid ?? 0)} so\'m',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.lastUpdated}: ${_formatDate(_cashRegister?.lastUpdated)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          // Naqd pul va Click tushumlari
                          if (_cashRegister != null && _todaySales != null) ...[
                            const SizedBox(height: 16),
                            Divider(color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            // Naqd pul
                            if (_cashRegister!.currentBalance > 0)
                              Row(
                                children: [
                                  const Icon(Icons.money,
                                      size: 16, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Naqd: ',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white70),
                                  ),
                                  Text(
                                    '${_cashRegister!.currentBalance.toStringAsFixed(2)} so\'m',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            // Click
                            if (_todaySales!.clickPaid > 0) ...[
                              if (_cashRegister!.currentBalance > 0)
                                const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.phone_android,
                                      size: 16, color: Colors.white70),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Click: ',
                                    style: const TextStyle(
                                        fontSize: 13, color: Colors.white70),
                                  ),
                                  Text(
                                    '${_todaySales!.clickPaid.toStringAsFixed(2)} so\'m',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Today's Sales Card
                    if (_todaySales != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2)),
                          ],
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.today,
                                  color: Colors.green,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bugungi savdolar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow(
                                'Soni:', '${_todaySales!.totalSales} ta'),
                            const SizedBox(height: 12),
                            _buildStatRow('Jami summa:',
                                '${_todaySales!.totalAmount.toStringAsFixed(2)} so\'m'),
                            const SizedBox(height: 12),
                            _buildStatRow('To\'langan:',
                                '${_todaySales!.totalPaid.toStringAsFixed(2)} so\'m',
                                color: Colors.green),
                            if (_todaySales!.debtAmount > 0) ...[
                              const SizedBox(height: 12),
                              _buildStatRow('Qarzga:',
                                  '${_todaySales!.debtAmount.toStringAsFixed(2)} so\'m',
                                  color: Colors.orange),
                            ],
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Bugungi tushumlar (Cash va Card)
                    if (_todaySales != null &&
                        (_todaySales!.cashPaid > 0 ||
                            _todaySales!.cardPaid > 0 ||
                            _todaySales!.clickPaid > 0))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.cyan.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.payments_outlined,
                                  color: Colors.blue,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bugungi tushumlar',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_todaySales!.cashPaid > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.money,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Naqd pul',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_todaySales!.cashPaid.toStringAsFixed(2)} so\'m',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_todaySales!.cardPaid > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.credit_card,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Plastik karta',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_todaySales!.cardPaid.toStringAsFixed(2)} so\'m',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_todaySales!.clickPaid > 0)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.phone_android,
                                        color: Colors.purple,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Click',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_todaySales!.clickPaid.toStringAsFixed(2)} so\'m',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.purple,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Withdraw Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isWithdrawing ? null : _showWithdrawDialog,
                        icon: const Icon(Icons.money_off),
                        label: Text(l10n.withdrawCash),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.danger,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Withdrawals History
                    Text(
                      l10n.withdrawalHistory,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_cashRegister?.withdrawals.isEmpty ?? true)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Hali pul olish tarixi yo'q",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _cashRegister?.withdrawals.length ?? 0,
                        itemBuilder: (context, index) {
                          final withdrawal = _cashRegister!.withdrawals[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppTheme.danger.withOpacity(0.1),
                                child: Icon(
                                  Icons.arrow_back,
                                  color: AppTheme.danger,
                                ),
                              ),
                              title: Text(
                                '${withdrawal.amount.toStringAsFixed(2)} so\'m',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (withdrawal.comment.isNotEmpty)
                                    Text(withdrawal.comment),
                                  Text(
                                    '${l10n.date}: ${_formatDate(withdrawal.withdrawalDate)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (withdrawal.userName != null)
                                    Text(
                                      '${l10n.seller}: ${withdrawal.userName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
