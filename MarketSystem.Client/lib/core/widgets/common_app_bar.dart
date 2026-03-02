import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      centerTitle: true,
      backgroundColor: AppColors.getCard(isDark),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      elevation: 0,
      bottom: bottom,
      actions: [
        if (extraActions != null) ...extraActions!,
        if (onRefresh != null)
          IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
      ],
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}
