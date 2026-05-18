// Destructive "soft-delete the owner + deactivate the market" dialog —
// migrated to the new design system. Requires the operator to type the
// EXACT market name to confirm; matches the backend's typed-confirmation
// guard so a slip-of-the-thumb can't take out the wrong tenant.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../design/tokens/app_tokens.dart';
import '../../../../design/tokens/app_typography.dart';
import '../../../../design/widgets/app_button.dart';
import '../../data/superadmin_service.dart';
import '../../domain/models/owner_detail.dart';

class DeleteOwnerDialog extends StatefulWidget {
  const DeleteOwnerDialog({
    super.key,
    required this.ownerName,
    required this.marketName,
    required this.userId,
    required this.stats,
  });
  final String ownerName;
  final String marketName;
  final String userId;
  final OwnerDetailStats stats;

  @override
  State<DeleteOwnerDialog> createState() => _DeleteOwnerDialogState();
}

class _DeleteOwnerDialogState extends State<DeleteOwnerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _confirm = TextEditingController();
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _confirm.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final service = SuperAdminService(context.read<AuthProvider>().httpService);
    final res = await service.deleteOwner(
      userId: widget.userId,
      confirmMarketName: _confirm.text.trim(),
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() =>
          _errorMessage = res.message ?? "O'chirishda xatolik yuz berdi");
    }
  }

  InputDecoration _decoration({
    required String hint,
    String? helper,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMedium().copyWith(
        color: AppColors.textMuted,
        fontSize: 15,
      ),
      helperText: helper,
      helperStyle: AppTextStyles.bodySmall().copyWith(fontSize: 12),
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: const BorderSide(color: AppColors.brand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          "O'chirishni tasdiqlang",
                          style: AppTextStyles.titleMedium(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: AppColors.textSecondary,
                        onPressed: _submitting
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    "Bu amalni qaytarib bo'lmaydi",
                    style: AppTextStyles.bodySmall(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.dangerLight,
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.danger,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.bodySmall().copyWith(
                                color: AppColors.text,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'DIQQAT! ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.danger,
                                  ),
                                ),
                                const TextSpan(text: 'Siz '),
                                TextSpan(
                                  text: widget.ownerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: " va uning do'koni "),
                                TextSpan(
                                  text: '"${widget.marketName}"',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: "'ni o'chirmoqchisiz."),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Quyidagi ma'lumotlar saqlanib qoladi (faqat owner+market deaktivatsiya):",
                          style: AppTextStyles.bodySmall().copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _CascadeRow(
                          icon: Icons.inventory_2_outlined,
                          count: widget.stats.productsCount,
                          label: 'ta mahsulot',
                        ),
                        _CascadeRow(
                          icon: Icons.receipt_long_outlined,
                          count: widget.stats.salesCount,
                          label: 'ta sotuv',
                        ),
                        _CascadeRow(
                          icon: Icons.people_outline,
                          count: widget.stats.customersCount,
                          label: 'ta mijoz',
                        ),
                        _CascadeRow(
                          icon: Icons.badge_outlined,
                          count: widget.stats.cashiersCount,
                          label: 'ta kassir akkaunti',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md + 2),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall().copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  Text(
                    "DO'KON NOMINI KIRITING *",
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _confirm,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      hint: widget.marketName,
                      helper: 'Aniq "${widget.marketName}" deb yozing',
                    ),
                    validator: (v) {
                      if ((v ?? '').trim() != widget.marketName.trim()) {
                        return "Do'kon nomi mos kelmadi";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    "O'CHIRISH SABABI *",
                    style: AppTextStyles.caption().copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _reason,
                    maxLines: 2,
                    style: AppTextStyles.bodyMedium().copyWith(fontSize: 15),
                    decoration: _decoration(
                      hint: "Masalan: To'lov muddati o'tdi va aloqaga chiqmadi",
                    ),
                    validator: (v) => (v ?? '').trim().length < 3
                        ? 'Sababini batafsil yozing'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Bekor qilish',
                          onPressed: _submitting
                              ? null
                              : () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: AppDangerButton(
                          label: "O'chirish",
                          icon: Icons.delete_outline,
                          isLoading: _submitting,
                          onPressed: _submitting ? null : _submit,
                        ),
                      ),
                    ],
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

class _CascadeRow extends StatelessWidget {
  const _CascadeRow({
    required this.icon,
    required this.count,
    required this.label,
  });
  final IconData icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.warning),
          const SizedBox(width: AppSpacing.md),
          Text(
            '$count ',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}
