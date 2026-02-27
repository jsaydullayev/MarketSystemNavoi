import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../../core/extensions/app_extensions.dart';
import '../../../core/providers/locale_provider.dart';
import '../features/profile/screens/profile_screen.dart';

Widget buildCustomThemeSwitch(BuildContext context, bool isDark) {
  return GestureDetector(
    onTap: () {
      isDark
          ? AdaptiveTheme.of(context).setLight()
          : AdaptiveTheme.of(context).setDark();
    },
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 32,
      width: 55,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color:
            isDark ? const Color(0xFF334155) : Colors.orange.withOpacity(0.2),
        border: Border.all(
          color: isDark ? Colors.blueAccent.withOpacity(0.5) : Colors.orange,
          width: 1.5,
        ),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 300),
        alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.blueAccent : Colors.orange,
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.blueAccent : Colors.orange)
                    .withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget buildMobileProfileHeader(
    BuildContext context, dynamic user, String role, Color primary, var l10n) {
  return Column(
    children: [
      Stack(
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primary, width: 2)),
            child: ClipOval(
              child: user?['profileImage'] != null
                  ? Image.network(user?['profileImage'], fit: BoxFit.cover)
                  : Icon(Icons.person_rounded, size: 45, color: primary),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              child: const Icon(Icons.edit, size: 12, color: Colors.white),
            ),
          ),
        ],
      ),
      10.height,
      Text(user?['fullName'] ?? l10n.user, style: AppStyles.cardTitle),
      Text(role, style: AppStyles.subtitle.copyWith(color: primary)),
    ],
  );
}

void showLanguageDialog(BuildContext context, LocaleProvider provider) {
  final isDark = AdaptiveTheme.of(context).mode.isDark;
  final primaryColor = AppColors.getPrimary(context);

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color:
                  isDark ? primaryColor.withOpacity(0.3) : Colors.transparent,
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Tilni tanlang / Выберите язык",
                textAlign: TextAlign.center,
                style: AppStyles.cardTitle.copyWith(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87)),
            25.height,
            _langOption(ctx, "O'zbekcha", "🇺🇿",
                provider.locale.languageCode == 'uz', primaryColor, isDark, () {
              provider.setLocale('uz');
              Navigator.pop(ctx);
            }),
            12.height,
            _langOption(ctx, "Русский", "🇷🇺",
                provider.locale.languageCode == 'ru', primaryColor, isDark, () {
              provider.setLocale('ru');
              Navigator.pop(ctx);
            }),
          ],
        ),
      ),
    ),
  );
}

Widget _langOption(BuildContext context, String title, String flag,
    bool isSelected, Color primary, bool isDark, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: isSelected
            ? primary.withOpacity(0.1)
            : (isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.grey.withOpacity(0.05)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isSelected ? primary : Colors.transparent, width: 1.5),
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 22)),
          15.width,
          Text(title,
              style: AppStyles.cardTitle.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isDark ? Colors.white : Colors.black87)),
          const Spacer(),
          if (isSelected)
            Icon(Icons.check_circle_rounded, color: primary, size: 20),
        ],
      ),
    ),
  );
}
