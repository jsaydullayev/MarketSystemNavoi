import 'package:flutter/material.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../data/models/profit_model.dart';

class DailySummaryCard extends StatelessWidget {
  final DailySalesListModel data;

  const DailySummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isOwner = auth.user?['role'] == 'Owner';
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    // Matn ranglari - Owner: har doim oq, Seller: tema ga qarab
    final labelColor = isOwner
        ? Colors.white70
        : isDark
            ? Colors.white54
            : Colors.grey[600]!;

    final valueColor = isOwner
        ? Colors.white
        : isDark
            ? Colors.white
            : Colors.black87;

    final dividerColor = isOwner
        ? Colors.white24
        : isDark
            ? Colors.white12
            : Colors.black12;

    final separatorColor = isOwner
        ? Colors.white24
        : isDark
            ? Colors.white12
            : Colors.grey.shade300;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOwner
              ? [primary, primary.withOpacity(0.75)]
              : isDark
                  ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFF8FAFF), const Color(0xFFEEF2FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          _buildMainRow(l10n.totalSale, data.totalSales,
              Icons.payments_outlined, labelColor, valueColor, l10n),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: dividerColor, height: 1),
          ),
          Row(
            children: [
              Expanded(
                child: _buildMiniItem(
                    l10n.paid,
                    data.totalPaidSales,
                    isOwner ? Colors.greenAccent : Colors.green,
                    labelColor,
                    l10n),
              ),
              Container(width: 1, height: 30, color: separatorColor),
              Expanded(
                child: _buildMiniItem(
                    l10n.debt,
                    data.totalDebtSales,
                    isOwner ? Colors.orangeAccent : Colors.orange,
                    labelColor,
                    l10n),
              ),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: 15),
            _buildProfitBadge(data.summaryProfit ?? 0, l10n),
          ] else ...[
            const SizedBox(height: 15),
            _buildSellerProfitHint(primary, isDark, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildMainRow(String label, double value, IconData icon,
      Color labelColor, Color valueColor, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: labelColor, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style:
                    TextStyle(color: labelColor, fontWeight: FontWeight.w500)),
          ],
        ),
        Text(
          '${value.toStringAsFixed(0)} ${l10n.currencySom}',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w900, color: valueColor),
        ),
      ],
    );
  }

  Widget _buildMiniItem(String label, double value, Color accent,
      Color labelColor, AppLocalizations l10n) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: labelColor, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)} ${l10n.currencySom}',
          style: TextStyle(fontWeight: FontWeight.bold, color: accent),
        ),
      ],
    );
  }

  Widget _buildProfitBadge(double profit, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.netProfit,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text(
            '+${profit.toStringAsFixed(0)} ${l10n.currencySom}',
            style: const TextStyle(
                color: Colors.greenAccent, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerProfitHint(
      Color primary, bool isDark, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? primary.withOpacity(0.15) : primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded,
              size: 16, color: isDark ? Colors.white : primary),
          const SizedBox(width: 8),
          Text(
            l10n.todaysReport,
            style: TextStyle(
                color: isDark ? Colors.white : primary,
                fontWeight: FontWeight.w600,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
