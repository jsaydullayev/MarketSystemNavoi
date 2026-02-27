import 'package:flutter/material.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/extensions/app_extensions.dart';

class ProfileSectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const ProfileSectionTitle(
      {super.key, required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: AppStyles.subtitle.copyWith(
          letterSpacing: 1.5,
          color: isDark ? Colors.white54 : Colors.black45,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class ProfileGlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const ProfileGlassCard(
      {super.key, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 20,
                offset: const Offset(0, 10)),
        ],
      ),
      child: child,
    );
  }
}

class ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const ProfileInfoRow(
      {super.key,
      required this.icon,
      required this.label,
      required this.value,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.white38 : Colors.black38),
        16.width,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppStyles.subtitle
                    .copyWith(fontSize: 10, color: Colors.grey)),
            Text(value, style: AppStyles.cardTitle.copyWith(fontSize: 15)),
          ],
        ),
      ],
    );
  }
}
