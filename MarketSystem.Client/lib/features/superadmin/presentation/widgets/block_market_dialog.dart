import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../data/superadmin_service.dart';

/// Block / unblock a market. Block requires a reason (subscription expired,
/// ToS violation, etc.) — the reason is shown to staff on their next login
/// attempt and goes into the audit log.
class BlockMarketDialog extends StatefulWidget {
  const BlockMarketDialog({
    super.key,
    required this.marketId,
    required this.marketName,
    required this.currentlyBlocked,
    this.currentReason,
  });
  final int marketId;
  final String marketName;
  final bool currentlyBlocked;
  final String? currentReason;

  @override
  State<BlockMarketDialog> createState() => _BlockMarketDialogState();
}

class _BlockMarketDialogState extends State<BlockMarketDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.currentReason != null) {
      _reason.text = widget.currentReason!;
    }
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _doBlock() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final service = SuperAdminService(context.read<AuthProvider>().httpService);
    final res = await service.blockMarket(
      marketId: widget.marketId,
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() =>
          _errorMessage = res.message ?? "Bloklashda xatolik yuz berdi");
    }
  }

  Future<void> _doUnblock() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final service = SuperAdminService(context.read<AuthProvider>().httpService);
    final res = await service.unblockMarket(marketId: widget.marketId);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage =
          res.message ?? "Blokdan chiqarishda xatolik yuz berdi");
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocking = !widget.currentlyBlocked;
    final color = blocking ? const Color(0xFFF57C00) : const Color(0xFF137333);
    final icon = blocking ? Icons.block_outlined : Icons.lock_open_outlined;
    final title = blocking ? "Do'konni bloklash" : 'Blokdan chiqarish';

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5F6368),
                  ),
                  children: [
                    TextSpan(text: blocking ? 'Bloklanadi: ' : 'Blokdan chiqariladi: '),
                    TextSpan(
                      text: widget.marketName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF202124),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (blocking) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF7E0),
                    border: Border.all(color: const Color(0xFFF9AB00)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('⚠️ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          "Bloklash darhol kuchga kiradi: Owner va do'kondagi barcha xodimlar (Admin/Seller) tizimga kira olmaydi. Eski JWT tokenlar ham 423 qaytaradi.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF5C3D02),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _reason,
                  maxLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Bloklash sababi *',
                    border: OutlineInputBorder(),
                    hintText: "Masalan: Obuna to'lovi 30 kun kechiktirilgan",
                  ),
                  validator: (v) => (v ?? '').trim().length < 3
                      ? 'Sababini batafsil yozing'
                      : null,
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    border: Border.all(color: const Color(0xFF137333)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('✅ ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          "Blokdan chiqarilgach Owner va xodimlar yana login qila olishadi.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF0D5C29),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.currentReason != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Bloklash sababi (avval):',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.currentReason!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE8E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFD93025),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton.icon(
          onPressed: _submitting ? null : (blocking ? _doBlock : _doUnblock),
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Icon(icon, size: 18),
          label: Text(blocking ? 'Bloklash' : 'Blokdan chiqarish'),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
