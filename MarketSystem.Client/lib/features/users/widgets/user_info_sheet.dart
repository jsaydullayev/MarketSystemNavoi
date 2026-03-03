import 'package:flutter/material.dart';
import 'package:market_system_client/core/constants/app_colors.dart';
import 'package:market_system_client/l10n/app_localizations.dart';

class UserInfoSheet extends StatelessWidget {
  final dynamic user;
  const UserInfoSheet({super.key, required this.user});

  static void show(BuildContext context, {required dynamic user}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UserInfoSheet(user: user),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case "owner":
        return const Color(0xFF7C3AED);
      case "admin":
        return const Color(0xFF2563EB);
      case "seller":
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = user["isActive"] ?? false;
    final role = user["role"] ?? "";
    final fullName = user["fullName"] ?? l10n.unknown;
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : "?";
    final color = _roleColor(role);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151515) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Center(
                child: Text(initial,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: color))),
          ),
          const SizedBox(height: 12),
          Text(fullName,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111111))),
          const SizedBox(height: 4),
          Text("@" + (user["username"] ?? ""),
              style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white38 : Colors.grey.shade500)),
          const SizedBox(height: 20),
          _InfoTile(
              icon: Icons.badge_rounded,
              label: l10n.role,
              value: role,
              valueColor: color,
              isDark: isDark),
          _InfoTile(
              icon: Icons.circle,
              label: l10n.status,
              value: isActive ? l10n.active : l10n.inactive,
              valueColor: isActive ? const Color(0xFF10B981) : Colors.red,
              isDark: isDark),
          const SizedBox(height: 8),
          SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.close,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              )),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _InfoTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.isDark,
      this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon,
            size: 16, color: isDark ? Colors.white38 : Colors.grey.shade400),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade500)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (isDark ? Colors.white : const Color(0xFF111111)))),
      ]),
    );
  }
}
