// Market Registration — migrated to the new design system.
//
// Layout adapted from HTML demo page 12.2 (`#page-auth-register`):
// - Soft white → brandLight gradient background
// - Brand "S" hero tile + greeting
// - Form card containing AppTextInputs for market name, subdomain, description
// - AppPrimaryButton CTA at the bottom
//
// NOTE: The demo's `page-auth-register` also has Owner full-name and phone
// fields, but the current `MarketService.registerMarket` API only accepts
// `name`, `subdomain`, `description`, so those demo fields are not wired
// here — they'd require backend changes.

import 'package:flutter/material.dart';
import 'package:market_system_client/design/tokens/app_theme_colors.dart';
import 'package:market_system_client/design/tokens/app_tokens.dart';
import 'package:market_system_client/design/tokens/app_typography.dart';
import 'package:market_system_client/design/widgets/app_button.dart';
import 'package:market_system_client/design/widgets/app_card.dart';
import 'package:market_system_client/design/widgets/app_text_input.dart';
import 'package:market_system_client/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../data/services/market_service.dart';
import '../../../core/providers/auth_provider.dart';

class MarketRegistrationScreen extends StatefulWidget {
  const MarketRegistrationScreen({super.key});

  @override
  State<MarketRegistrationScreen> createState() =>
      _MarketRegistrationScreenState();
}

class _MarketRegistrationScreenState extends State<MarketRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subdomainController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _subdomainController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _registerMarket() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final marketService = MarketService(authProvider: authProvider);

      final response = await marketService.registerMarket(
        name: _nameController.text.trim(),
        subdomain: _subdomainController.text.trim().isEmpty
            ? null
            : _subdomainController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      // Update access token if provided by the API (Owner gets re-issued
      // a token bound to the new market scope).
      if (response.accessToken != null) {
        await authProvider.updateToken(response.accessToken!);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSuccessDialog(response);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            margin: const EdgeInsets.all(AppSpacing.xl),
          ),
        );
      }
    }
  }

  void _showSuccessDialog(dynamic response) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        icon: const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 50,
        ),
        title: Text(
          l10n.marketRegisteredSuccess,
          style: AppTextStyles.titleMedium(),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${l10n.marketName}: ${response.market.name}',
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.nowYouCanAddUsers,
              style: AppTextStyles.bodySmall().copyWith(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // dismiss dialog
              Navigator.of(context).pop(); // back to caller (dashboard)
            },
            style: TextButton.styleFrom(
              foregroundColor: context.colors.brand,
            ),
            child: Text(
              l10n.ok,
              style: AppTextStyles.labelLarge().copyWith(
                color: context.colors.brand,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.colors.bg,
      // Bare AppBar — no title, just a back button so the hero header
      // below it carries the visual weight (matches demo's auth screens).
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: context.colors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: context.colors.text,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colors.surface, context.colors.brandLight],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xl4,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero strip: brand "S" tile + headline + sub-headline
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              context.colors.brand,
                              context.colors.brandDark
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  context.colors.brand.withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.createYourMarket,
                              style: AppTextStyles.titleLarge().copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.enterMarketDetails,
                              style: AppTextStyles.bodySmall().copyWith(
                                color: context.colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // Form card
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextInput(
                          label: l10n.marketName,
                          controller: _nameController,
                          hint: l10n.exampleMyStore,
                          prefixIcon: Icons.store_rounded,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.pleaseEnterMarketName;
                            }
                            if (value.trim().length < 3) {
                              return l10n.marketNameTooShort;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextInput(
                          label: l10n.subdomainOptional,
                          controller: _subdomainController,
                          hint: l10n.exampleMyStore,
                          prefixIcon: Icons.link_rounded,
                          validator: (value) {
                            if (value != null &&
                                value.trim().isNotEmpty &&
                                !RegExp(r'^[a-z0-9-]+$')
                                    .hasMatch(value.trim())) {
                              return l10n.subdomainRules;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppSpacing.sm,
                            top: 2,
                          ),
                          child: Text(
                            l10n.canBeLeftEmpty,
                            style: AppTextStyles.caption().copyWith(
                              fontSize: 10,
                              letterSpacing: 0,
                              color: context.colors.textMuted,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppTextInput(
                          label: l10n.descriptionOptional,
                          controller: _descriptionController,
                          hint: l10n.marketShortInfo,
                          prefixIcon: Icons.description_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Info banner — brand-light card explaining what happens next
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.colors.brandLight,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border:
                          Border.all(color: AppColors.brandTint, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: context.colors.brandDark,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            l10n.afterMarketRegisterInfo,
                            style: AppTextStyles.bodySmall().copyWith(
                              fontSize: 12,
                              color: context.colors.brandDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl2),

                  // Submit CTA
                  AppPrimaryButton(
                    label: l10n.registerMarket,
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _isLoading ? null : _registerMarket,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
