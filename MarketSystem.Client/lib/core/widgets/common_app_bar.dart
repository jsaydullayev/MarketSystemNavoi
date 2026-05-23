// Shared AppBar used across feature screens. Uses the new design tokens
// (AppColors, AppTextStyles) so consumers don't need to construct AppBar +
// IconButton + back-navigation logic themselves.

import 'package:flutter/material.dart';

import '../../design/tokens/app_tokens.dart';
import '../../design/tokens/app_typography.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onRefresh;
  final List<Widget>? extraActions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBackPressed;

  const CommonAppBar({
    super.key,
    required this.title,
    this.onRefresh,
    this.extraActions,
    this.bottom,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Resolve surface / foreground against the active theme so the bar is
    // dark-navy in dark mode instead of staying white.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final fg = isDark ? AppColors.darkText : AppColors.text;

    return AppBar(
      title: Text(
        title,
        style: AppTextStyles.titleMedium().copyWith(
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
      centerTitle: true,
      backgroundColor: surface,
      foregroundColor: fg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: fg,
        ),
        // maybePop respects any PopScope registered upstream (e.g. the
        // "save as draft?" prompt in Yangi sotuv). Navigator.pop bypasses
        // those guards and would silently lose in-progress work.
        onPressed: onBackPressed ?? () => Navigator.maybePop(context),
      ),
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: bottom,
      actions: [
        if (extraActions case final actions?) ...actions,
        if (onRefresh != null)
          IconButton(
            icon: Icon(Icons.refresh, color: fg),
            onPressed: onRefresh,
          ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
