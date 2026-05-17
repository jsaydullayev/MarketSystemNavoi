import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../data/superadmin_service.dart';
import '../../domain/models/owner_detail.dart';

/// Destructive "soft-delete the owner + deactivate the market" dialog.
/// Requires the operator to type the EXACT market name to confirm — matches
/// the backend's typed-confirmation guard so a slip-of-the-thumb can't take
/// out the wrong tenant.
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFCE8E6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFD93025), size: 22),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text("O'chirishni tasdiqlang")),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Bu amalni qaytarib bo'lmaydi",
                  style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE8E6),
                    border: Border.all(color: const Color(0xFFD93025)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🚨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF5F1410),
                            ),
                            children: [
                              const TextSpan(
                                text: 'DIQQAT! ',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: 'Siz '),
                              TextSpan(
                                text: widget.ownerName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(text: " va uning do'koni "),
                              TextSpan(
                                text: '"${widget.marketName}"',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const TextSpan(
                                  text: "'ni o'chirmoqchisiz."),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    border: Border.all(color: const Color(0xFFF9AB00)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "⚠ Quyidagi ma'lumotlar mavjud bo'lib qoladi (faqat owner+market deaktivatsiya):",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C3D02),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _CascadeRow(
                        icon: '📦',
                        count: widget.stats.productsCount,
                        label: 'ta mahsulot',
                      ),
                      _CascadeRow(
                        icon: '💰',
                        count: widget.stats.salesCount,
                        label: 'ta sotuv',
                      ),
                      _CascadeRow(
                        icon: '👥',
                        count: widget.stats.customersCount,
                        label: 'ta mijoz',
                      ),
                      _CascadeRow(
                        icon: '🧾',
                        count: widget.stats.cashiersCount,
                        label: 'ta kassir akkaunti',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFFD93025)),
                    ),
                  ),
                TextFormField(
                  controller: _confirm,
                  decoration: InputDecoration(
                    labelText: "Do'kon nomini kiriting *",
                    border: const OutlineInputBorder(),
                    helperText: 'Aniq "${widget.marketName}" deb yozing',
                  ),
                  validator: (v) {
                    if ((v ?? '').trim() != widget.marketName.trim()) {
                      return "Do'kon nomi mos kelmadi";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reason,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: "O'chirish sababi *",
                    border: OutlineInputBorder(),
                    hintText: "Masalan: To'lov muddati o'tdi va aloqaga chiqmadi",
                  ),
                  validator: (v) => (v ?? '').trim().length < 3
                      ? "Sababini batafsil yozing"
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.delete_outline, size: 18),
          label: const Text("O'chirish"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD93025),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _CascadeRow extends StatelessWidget {
  const _CascadeRow({
    required this.icon,
    required this.count,
    required this.label,
  });
  final String icon;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            ' $count ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5C3D02),
            ),
          ),
          Text(
            label,
            style:
                const TextStyle(fontSize: 13, color: Color(0xFF5C3D02)),
          ),
        ],
      ),
    );
  }
}
