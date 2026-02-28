import 'package:flutter/material.dart';
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOwner
              ? [primary, primary.withOpacity(0.8)]
              : [Colors.white, Colors.white],
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
          _buildMainRow(
              'Jami savdo', data.totalSales, isOwner, Icons.payments_outlined),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(color: Colors.white24, height: 1),
          ),
          Row(
            children: [
              Expanded(
                  child: _buildMiniItem('To\'langan', data.totalPaidSales,
                      isOwner, Colors.greenAccent)),
              Container(width: 1, height: 30, color: Colors.white24),
              Expanded(
                  child: _buildMiniItem('Qarz', data.totalDebtSales, isOwner,
                      Colors.orangeAccent)),
            ],
          ),
          if (isOwner) ...[
            const SizedBox(height: 15),
            _buildProfitBadge(data.summaryProfit ?? 0),
          ]
        ],
      ),
    );
  }

  Widget _buildMainRow(
      String label, double value, bool isOwner, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: isOwner ? Colors.white70 : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: isOwner ? Colors.white70 : Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ],
        ),
        Text(
          '${value.toStringAsFixed(0)} so\'m',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isOwner ? Colors.white : Colors.black),
        ),
      ],
    );
  }

  Widget _buildMiniItem(
      String label, double value, bool isOwner, Color accent) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: isOwner ? Colors.white60 : Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(0)}',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isOwner ? Colors.white : Colors.black87),
        ),
      ],
    );
  }

  Widget _buildProfitBadge(double profit) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Sof foyda',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(
            '+${profit.toStringAsFixed(0)} so\'m',
            style: const TextStyle(
                color: Colors.greenAccent, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
