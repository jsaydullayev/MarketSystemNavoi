import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../data/superadmin_service.dart';
import '../domain/models/owner_detail.dart';
import 'widgets/block_market_dialog.dart';
import 'widgets/delete_owner_dialog.dart';
import 'widgets/edit_owner_dialog.dart';

/// Owner profile — Hero card (avatar + identity + market + Tahrirlash/O'chirish),
/// stat tiles (Mahsulotlar / Sotuvlar / Mijozlar / Aylanma), Owner info,
/// Market info, and Block/Unblock control.
class OwnerDetailScreen extends StatefulWidget {
  const OwnerDetailScreen({super.key, required this.userId});
  final String userId;

  @override
  State<OwnerDetailScreen> createState() => _OwnerDetailScreenState();
}

class _OwnerDetailScreenState extends State<OwnerDetailScreen> {
  late final SuperAdminService _service;
  OwnerDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = SuperAdminService(context.read<AuthProvider>().httpService);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _service.getOwnerDetail(widget.userId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.status == SuperAdminOpStatus.success) {
        _detail = res.data;
      } else {
        _error = res.message ?? 'failure';
      }
    });
  }

  Future<void> _onEdit() async {
    if (_detail == null) return;
    final updated = await showDialog<OwnerDetail>(
      context: context,
      builder: (_) => EditOwnerDialog(detail: _detail!),
    );
    if (updated != null && mounted) {
      setState(() => _detail = updated);
      _snack('Ma\'lumotlar yangilandi', isError: false);
    }
  }

  Future<void> _onDelete() async {
    if (_detail?.market == null) return;
    final deleted = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteOwnerDialog(
        ownerName: _detail!.fullName,
        marketName: _detail!.market!.name,
        userId: _detail!.userId,
        stats: _detail!.stats,
      ),
    );
    if (deleted == true && mounted) {
      Navigator.of(context).pop(true); // signal list to refresh
    }
  }

  Future<void> _onBlock() async {
    if (_detail?.market == null) return;
    final blocked = await showDialog<bool>(
      context: context,
      builder: (_) => BlockMarketDialog(
        marketId: _detail!.market!.id,
        marketName: _detail!.market!.name,
        currentlyBlocked: _detail!.market!.isBlocked,
        currentReason: _detail!.market!.blockedReason,
      ),
    );
    if (blocked == true && mounted) {
      await _load(); // pull fresh block state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F9),
      appBar: AppBar(
        title: const Text("Owner ma'lumotlari"),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _load)
              : _detail == null
                  ? const Center(child: Text('Owner topilmadi'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroCard(
                              detail: _detail!,
                              onEdit: _onEdit,
                              onDelete: _onDelete,
                              onBlock: _onBlock,
                            ),
                            const SizedBox(height: 12),
                            _StatsGrid(stats: _detail!.stats),
                            const SizedBox(height: 12),
                            _OwnerInfoCard(detail: _detail!),
                            const SizedBox(height: 12),
                            if (_detail!.market != null)
                              _MarketInfoCard(market: _detail!.market!),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
    );
  }

  void _snack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.detail,
    required this.onEdit,
    required this.onDelete,
    required this.onBlock,
  });
  final OwnerDetail detail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final market = detail.market;
    final blocked = market?.isBlocked ?? false;
    final initial = detail.fullName.isNotEmpty
        ? detail.fullName[0].toUpperCase()
        : '?';
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final narrow = constraints.maxWidth < 520;
            final identity = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF1A73E8),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              detail.fullName,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusChip(
                            label: blocked
                                ? 'Bloklangan'
                                : (detail.isActive ? 'Faol' : 'Faolsiz'),
                            color: blocked
                                ? const Color(0xFFD93025)
                                : (detail.isActive
                                    ? const Color(0xFF137333)
                                    : const Color(0xFF9AA0A6)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${detail.username} · Owner · '
                        '${_formatDate(detail.createdAt, withTime: false)} dan beri',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          if (detail.phone != null)
                            _MetaItem(
                              icon: Icons.phone_outlined,
                              text: detail.phone!,
                            ),
                          if (market != null)
                            _MetaItem(
                              icon: Icons.storefront_outlined,
                              text: market.name,
                            ),
                          if (market?.subdomain != null)
                            _MetaItem(
                              icon: Icons.language_outlined,
                              text: '${market!.subdomain}.strotech.uz',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
            final actions = Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: narrow ? WrapAlignment.start : WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Tahrirlash'),
                ),
                OutlinedButton.icon(
                  onPressed: onBlock,
                  icon: Icon(
                    blocked ? Icons.lock_open_outlined : Icons.block_outlined,
                    size: 16,
                  ),
                  label: Text(blocked ? 'Blokdan chiqarish' : 'Bloklash'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: blocked
                        ? const Color(0xFF137333)
                        : const Color(0xFFF57C00),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text("O'chirish"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD93025),
                  ),
                ),
              ],
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [identity, const SizedBox(height: 16), actions],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identity),
                const SizedBox(width: 16),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final OwnerDetailStats stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, c) {
        final cross = c.maxWidth < 600 ? 2 : 4;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cross,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: cross == 2 ? 1.8 : 1.4,
          children: [
            _StatTile(
              label: 'MAHSULOTLAR',
              value: _fmtNum(stats.productsCount),
              subtitle: 'Faol turlari',
              color: AppTheme.textPrimary,
              icon: '📦',
            ),
            _StatTile(
              label: 'SOTUVLAR',
              value: _fmtNum(stats.salesCount),
              subtitle: 'Jami chek',
              color: const Color(0xFF137333),
              icon: '💰',
            ),
            _StatTile(
              label: 'MIJOZLAR',
              value: _fmtNum(stats.customersCount),
              subtitle: 'Faol mijozlar',
              color: AppTheme.textPrimary,
              icon: '👥',
            ),
            _StatTile(
              label: 'QARZ',
              value: _fmtMoney(stats.outstandingDebt),
              subtitle: 'UZS jami',
              color: stats.outstandingDebt > 0
                  ? const Color(0xFFF57C00)
                  : AppTheme.textPrimary,
              icon: '💸',
            ),
          ],
        );
      },
    );
  }

  String _fmtNum(int n) => n.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  String _fmtMoney(double d) {
    if (d >= 1000000) return '${(d / 1000000).toStringAsFixed(1)}M';
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(0)}K';
    return d.toStringAsFixed(0);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDADCE0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OwnerInfoCard extends StatelessWidget {
  const _OwnerInfoCard({required this.detail});
  final OwnerDetail detail;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "👤 OWNER MA'LUMOTLARI",
      children: [
        _InfoRow(label: "TO'LIQ ISM", value: detail.fullName),
        _InfoRow(label: 'USERNAME', value: '@${detail.username}', mono: true),
        _InfoRow(label: 'TELEFON', value: detail.phone ?? '—'),
        _InfoRow(
          label: 'TIL',
          value: detail.language == 'russian' ? '🇷🇺 Русский' : "🇺🇿 O'zbek",
        ),
        _InfoRow(
          label: "RO'YXATDAN O'TGAN",
          value: _formatDate(detail.createdAt),
        ),
        _InfoRow(
          label: 'HOLAT',
          value: detail.isActive ? '● Faol' : '● Faolsiz',
          valueColor: detail.isActive
              ? const Color(0xFF137333)
              : const Color(0xFF9AA0A6),
        ),
      ],
    );
  }
}

class _MarketInfoCard extends StatelessWidget {
  const _MarketInfoCard({required this.market});
  final OwnerDetailMarket market;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "🏪 DO'KON MA'LUMOTLARI",
      children: [
        _InfoRow(label: 'NOMI', value: market.name),
        _InfoRow(
          label: 'SUBDOMAIN',
          value: market.subdomain != null
              ? '${market.subdomain}.strotech.uz'
              : '—',
          mono: true,
        ),
        _InfoRow(label: 'MARKET ID', value: '#${market.id}', mono: true),
        _InfoRow(
          label: 'HOLAT',
          value: market.isBlocked
              ? '🔒 Bloklangan'
              : (market.isActive ? '● Faol' : '● Faolsiz'),
          valueColor: market.isBlocked
              ? const Color(0xFFD93025)
              : (market.isActive
                  ? const Color(0xFF137333)
                  : const Color(0xFF9AA0A6)),
        ),
        if (market.isBlocked && market.blockedReason != null)
          _InfoRow(
            label: 'BLOKLASH SABABI',
            value: market.blockedReason!,
            valueColor: const Color(0xFFD93025),
          ),
        if (market.isBlocked && market.blockedAt != null)
          _InfoRow(
            label: 'BLOKLANGAN',
            value: _formatDate(market.blockedAt!),
          ),
        if (market.expiresAt != null)
          _InfoRow(
            label: 'OBUNA TUGASHI',
            value: _formatDate(market.expiresAt!, withTime: false),
          ),
        _InfoRow(label: 'YARATILGAN', value: _formatDate(market.createdAt)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (ctx, c) {
                final cross = c.maxWidth < 480 ? 1 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: cross,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 24,
                  childAspectRatio: cross == 1 ? 6 : 4,
                  children: children,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.mono = false,
    this.valueColor,
  });
  final String label;
  final String value;
  final bool mono;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: valueColor ?? AppTheme.textPrimary,
            fontFamily: mono ? 'monospace' : null,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime utc, {bool withTime = true}) {
  final local = utc.toLocal();
  String two(int n) => n < 10 ? '0$n' : '$n';
  final date = '${local.year}-${two(local.month)}-${two(local.day)}';
  if (!withTime) return date;
  return '$date ${two(local.hour)}:${two(local.minute)}';
}
