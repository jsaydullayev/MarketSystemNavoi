import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../data/superadmin_service.dart';
import '../../domain/models/owner_detail.dart';

/// Editable Owner+Market fields. Username/password are intentionally NOT
/// editable here — both invalidate JWTs and audit links, and live behind
/// separate operations.
class EditOwnerDialog extends StatefulWidget {
  const EditOwnerDialog({super.key, required this.detail});
  final OwnerDetail detail;

  @override
  State<EditOwnerDialog> createState() => _EditOwnerDialogState();
}

class _EditOwnerDialogState extends State<EditOwnerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullName;
  late final TextEditingController _phone;
  late final TextEditingController _marketName;
  late final TextEditingController _subdomain;
  late final TextEditingController _description;
  late bool _ownerActive;
  late bool _marketActive;
  String _language = 'uz';
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final d = widget.detail;
    _fullName = TextEditingController(text: d.fullName);
    _phone = TextEditingController(text: d.phone ?? '');
    _marketName = TextEditingController(text: d.market?.name ?? '');
    _subdomain = TextEditingController(text: d.market?.subdomain ?? '');
    _description = TextEditingController(text: d.market?.description ?? '');
    _ownerActive = d.isActive;
    _marketActive = d.market?.isActive ?? true;
    _language = d.language.startsWith('ru') ? 'ru' : 'uz';
  }

  @override
  void dispose() {
    _fullName.dispose();
    _phone.dispose();
    _marketName.dispose();
    _subdomain.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final service = SuperAdminService(context.read<AuthProvider>().httpService);
    final res = await service.updateOwner(
      userId: widget.detail.userId,
      fullName: _fullName.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      language: _language,
      marketName: _marketName.text.trim(),
      subdomain: _subdomain.text.trim().isEmpty
          ? null
          : _subdomain.text.trim().toLowerCase(),
      description: _description.text.trim(),
      ownerActive: _ownerActive,
      marketActive: _marketActive,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success && res.data != null) {
      Navigator.of(context).pop(res.data);
    } else {
      setState(() => _errorMessage = res.message ?? "Yangilashda xatolik");
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
              color: const Color(0xFFFEF7E0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.edit_outlined,
                color: Color(0xFFF57C00), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text("Ma'lumotlarni yangilash")),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.detail.fullName} · @${widget.detail.username}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5F6368),
                  ),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8E6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFD93025), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFD93025),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                _SectionTitle("👤 Owner"),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(
                    labelText: "To'liq ism *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? "Ism kerak" : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon',
                          border: OutlineInputBorder(),
                          hintText: '+998 90 ...',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _language,
                        decoration: const InputDecoration(
                          labelText: 'Til',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'uz', child: Text("O'zbek")),
                          DropdownMenuItem(value: 'ru', child: Text('Русский')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _language = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SwitchTile(
                  title: 'Owner faol',
                  value: _ownerActive,
                  onChanged: (v) => setState(() => _ownerActive = v),
                ),
                const SizedBox(height: 16),
                _SectionTitle("🏪 Do'kon"),
                TextFormField(
                  controller: _marketName,
                  decoration: const InputDecoration(
                    labelText: "Do'kon nomi *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length < 3 ? "Min. 3 belgi" : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _subdomain,
                  decoration: const InputDecoration(
                    labelText: 'Subdomain',
                    border: OutlineInputBorder(),
                    suffixText: '.strotech.uz',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _description,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Tavsif',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                _SwitchTile(
                  title: "Do'kon faol",
                  value: _marketActive,
                  onChanged: (v) => setState(() => _marketActive = v),
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
              : const Icon(Icons.save_outlined, size: 18),
          label: const Text('Saqlash'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF57C00),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5F6368),
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
