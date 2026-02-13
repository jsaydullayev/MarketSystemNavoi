import 'package:flutter/material.dart';
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

    final result = await _cashRegisterService.getCashRegister();

    if (mounted) {
      setState(() {
        _cashRegister = result;
        _isLoading = false;
      });
    }
  }

  Future<void> _showWithdrawDialog() async {
    final l10n = AppLocalizations.of(context)!;

    _amountController.clear();
    _commentController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.withdrawCash),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            onPressed: _isWithdrawing ? null : _withdrawCash,
            child: _isWithdrawing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  Future<void> _withdrawCash() async {
    final l10n = AppLocalizations.of(context)!;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidInput)),
      );
      return;
    }

    if (_cashRegister != null && amount > _cashRegister!.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.insufficientFunds)),
      );
      return;
    }

    setState(() => _isWithdrawing = true);
    Navigator.pop(context);

    final success = await _cashRegisterService.withdrawCash(
      amount,
      _commentController.text.trim(),
    );

    setState(() => _isWithdrawing = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.withdrawSuccess),
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

    // Faqat admin va owner uchun
    final isAdmin = authProvider.user?['role'] == 'Admin' ||
                    authProvider.user?['role'] == 'Owner';

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.cashRegister)),
        body: Center(
          child: Text(
            l10n.accessDenied,
            style: const TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashRegister),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadCashRegister,
          ),
        ],
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
                          Text(
                            '${_cashRegister?.currentBalance.toStringAsFixed(2) ?? '0.00'} so\'m',
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
                                backgroundColor: AppTheme.danger.withOpacity(0.1),
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
}
