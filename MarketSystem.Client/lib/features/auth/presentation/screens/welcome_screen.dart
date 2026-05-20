// Welcome screen — first-time entry point. Uses the new design system tokens
// while preserving the existing orangeLogo.png asset, language switcher, theme
// toggle, and Privacy Policy access from the original implementation.

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/providers/locale_provider.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../design/tokens/app_theme_colors.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AdaptiveTheme.of(context).mode.isDark;

    return Scaffold(
      // Subtle gradient bg from white to brand-tint (orange light).
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              context.colors.brandLight,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl3, // 24 horizontal
              AppSpacing.xl4, // 32 top
              AppSpacing.xl3,
              AppSpacing.xl3,
            ),
            child: Column(
              children: [
                _buildTopBar(context, isDark),
                const Spacer(flex: 2),
                _buildBrandSection(context),
                const Spacer(flex: 3),
                _buildActions(context),
                const SizedBox(height: AppSpacing.lg),
                _buildPrivacyCaption(context, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top row: language switcher (left) + theme toggle (right).
  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Consumer<LocaleProvider>(
          builder: (context, localeProvider, _) =>
              _LanguageChip(provider: localeProvider),
        ),
        _ThemeToggleButton(isDark: isDark),
      ],
    );
  }

  /// Brand: existing orangeLogo.png asset (120x120) + "Strotech" title + subtitle.
  Widget _buildBrandSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/orangeLogo.png',
          width: 120,
          height: 120,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Strotech',
          style: AppTextStyles.displayLarge().copyWith(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: context.colors.text,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          "Kichik do'konlar uchun savdo va hisob tizimi",
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium().copyWith(
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// CTA buttons: "Tizimga kirish" (primary) + "Yangi do'kon" (secondary).
  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        AppPrimaryButton(
          label: 'Tizimga kirish',
          onPressed: () => _onLoginPressed(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSecondaryButton(
          label: "Yangi do'kon — ro'yxatdan o'tish",
          onPressed: () => Navigator.of(context).pushNamed(AppRoutes.register),
        ),
      ],
    );
  }

  /// Footer caption with Privacy Policy link.
  Widget _buildPrivacyCaption(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => _showPrivacyDialog(context, isDark),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTextStyles.caption().copyWith(
              color: context.colors.textMuted,
            ),
            children: [
              const TextSpan(text: 'Davom etish orqali '),
              TextSpan(
                text: 'Maxfiylik siyosati',
                style: AppTextStyles.caption().copyWith(
                  color: context.colors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(text: 'ga rozisiz'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLoginPressed(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  void _showPrivacyDialog(BuildContext context, bool isDark) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl2),
                decoration: BoxDecoration(
                  color: context.colors.brand,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Maxfiylik siyosati',
                      style: AppTextStyles.titleMedium().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              // Content
              const Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppSpacing.xl2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PrivacySection(
                        title: 'Kirish',
                        body:
                            'Ushbu Maxfiylik siyosati MarketSystem sizning shaxsiy maʼlumotlaringizni qanday yigʻishini, ishlatishini va himoya qilishini tushuntiradi.',
                      ),
                      _PrivacySection(
                        title: 'Maʼlumot yigʻish',
                        body:
                            'Quyidagi maʼlumotlar yigʻiladi:\n\n• Ism, telefon raqami, email\n• Doʻkon maʼlumotlari (mahsulot, sotuv, mijoz)\n• Qurilma maʼlumotlari va foydalanish statistikasi',
                      ),
                      _PrivacySection(
                        title: 'Maʼlumot ishlatilishi',
                        body:
                            'Maʼlumotlar quyidagilar uchun ishlatiladi:\n\n• Xizmat koʻrsatish va yaxshilash\n• Tranzaksiyalarni qayta ishlash\n• Muhim yangilanishlar haqida xabar berish',
                      ),
                      _PrivacySection(
                        title: 'Maʼlumot xavfsizligi',
                        body:
                            'Maʼlumotlar shifrlangan va himoyalangan serverlarda saqlanadi. Muntazam xavfsizlik tekshiruvlari oʻtkaziladi.',
                      ),
                      _PrivacySection(
                        title: 'Sizning huquqlaringiz',
                        body:
                            '• Maʼlumotlaringizni koʻrish\n• Notoʻgʻri maʼlumotlarni tuzatish\n• Hisobni oʻchirish\n• Maʼlumotlarni eksport qilish',
                      ),
                      _PrivacySection(
                        title: 'Bogʻlanish',
                        body:
                            'Savollar boʻlsa:\n\nEmail: support@strotech.uz\nWebsite: https://strotech.uz',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Language switcher chip — opens a modal bottom sheet with locale options.
class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.provider});
  final LocaleProvider provider;

  static const _options = [
    {'code': 'uz', 'label': "🇺🇿 O'zbekcha"},
    {'code': 'ru', 'label': '🇷🇺 Русский'},
  ];

  @override
  Widget build(BuildContext context) {
    final current = _options.firstWhere(
      (o) => o['code'] == provider.locale.languageCode,
      orElse: () => _options.first,
    );

    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: context.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌐', style: TextStyle(fontSize: 13)),
            const SizedBox(width: AppSpacing.sm),
            Text(
              current['label']!,
              style: AppTextStyles.bodySmall().copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: context.colors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Tilni tanlang', style: AppTextStyles.titleMedium()),
              const SizedBox(height: AppSpacing.lg),
              for (final option in _options)
                ListTile(
                  onTap: () {
                    provider.setLocale(option['code']!);
                    Navigator.pop(ctx);
                  },
                  title: Text(
                    option['label']!,
                    style: AppTextStyles.bodyLarge(),
                  ),
                  trailing: option['code'] == provider.locale.languageCode
                      ? Icon(Icons.check_rounded, color: context.colors.brand)
                      : null,
                ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}

/// Sun/moon icon button — toggles between light/dark themes.
class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: context.colors.border),
      ),
      child: IconButton(
        onPressed: () => isDark
            ? AdaptiveTheme.of(context).setLight()
            : AdaptiveTheme.of(context).setDark(),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Icon(
            isDark
                ? Icons.wb_sunny_outlined
                : Icons.nightlight_round_outlined,
            key: ValueKey(isDark),
            color: isDark ? Colors.amber : context.colors.text,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium().copyWith(
              color: context.colors.brand,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: AppTextStyles.bodyMedium().copyWith(
              color: context.colors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
