import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';

/// Bold section header used to introduce report subsections.
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.titleMedium().copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
  }
}
