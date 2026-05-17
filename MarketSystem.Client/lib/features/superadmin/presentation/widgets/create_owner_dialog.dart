import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../data/superadmin_service.dart';

/// Manually create an owner+market without a backing registration request.
/// Used when the SuperAdmin onboards a tenant out-of-band (phone, walk-in).
/// Returns a [CreatedOwnerResult] so the console can show the credentials
/// hand-off dialog right after.
class CreatedOwnerResult {
  CreatedOwnerResult({
    required this.username,
    required this.password,
    required this.marketName,
  });
  final String username;
  final String password;
  final String marketName;
}

class CreateOwnerDialog extends StatefulWidget {
  const CreateOwnerDialog({super.key});

  @override
  State<CreateOwnerDialog> createState() => _CreateOwnerDialogState();
}

class _CreateOwnerDialogState extends State<CreateOwnerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _marketName = TextEditingController();
  final _subdomain = TextEditingController();
  String _language = 'uz';
  bool _obscurePassword = true;
  bool _submitting = false;
  String? _errorMessage;

  // Live availability state per field — mirrors the Approve dialog so the
  // SuperAdmin gets immediate feedback instead of round-tripping the form.
  Timer? _userTimer, _marketTimer, _subdomainTimer;
  static const _debounce = Duration(milliseconds: 400);
  _Check _userState = _Check.idle;
  _Check _marketState = _Check.idle;
  _Check _subdomainState = _Check.idle;
  String? _suggestedSubdomain;

  late final SuperAdminService _service;

  @override
  void initState() {
    super.initState();
    _service = SuperAdminService(context.read<AuthProvider>().httpService);
    _username.addListener(_onUsernameChanged);
    _marketName.addListener(_onMarketChanged);
    _subdomain.addListener(_onSubdomainChanged);
  }

  @override
  void dispose() {
    _userTimer?.cancel();
    _marketTimer?.cancel();
    _subdomainTimer?.cancel();
    _fullName.dispose();
    _phone.dispose();
    _username.dispose();
    _password.dispose();
    _marketName.dispose();
    _subdomain.dispose();
    super.dispose();
  }

  void _onUsernameChanged() {
    final v = _username.text.trim();
    _userTimer?.cancel();
    if (v.length < 3) {
      setState(() {
        _userState = _Check.idle;
        if (_subdomain.text.trim().isEmpty) _suggestedSubdomain = null;
      });
      return;
    }
    setState(() => _userState = _Check.checking);
    _userTimer = Timer(_debounce, () => _check(usernameQ: v));
  }

  void _onMarketChanged() {
    final v = _marketName.text.trim();
    _marketTimer?.cancel();
    if (v.length < 3) {
      setState(() => _marketState = _Check.idle);
      return;
    }
    setState(() => _marketState = _Check.checking);
    _marketTimer = Timer(_debounce, () => _check(marketQ: v));
  }

  void _onSubdomainChanged() {
    final v = _subdomain.text.trim().toLowerCase();
    _subdomainTimer?.cancel();
    if (v.isEmpty) {
      setState(() => _subdomainState = _Check.idle);
      final u = _username.text.trim();
      if (u.length >= 3) {
        _subdomainTimer = Timer(_debounce, () => _check(usernameQ: u));
      }
      return;
    }
    setState(() => _subdomainState = _Check.checking);
    _subdomainTimer = Timer(_debounce, () => _check(subdomainQ: v));
  }

  Future<void> _check({
    String? usernameQ,
    String? marketQ,
    String? subdomainQ,
  }) async {
    final res = await _service.checkAvailability(
      username: usernameQ,
      marketName: marketQ,
      subdomain: subdomainQ,
    );
    if (!mounted) return;
    final stillCurrent = (usernameQ == null ||
            _username.text.trim() == usernameQ) &&
        (marketQ == null || _marketName.text.trim() == marketQ) &&
        (subdomainQ == null ||
            _subdomain.text.trim().toLowerCase() == subdomainQ);
    if (!stillCurrent) return;
    if (res.status != SuperAdminOpStatus.success || res.data == null) return;
    setState(() {
      final d = res.data!;
      if (usernameQ != null && d['usernameAvailable'] is bool) {
        _userState = (d['usernameAvailable'] as bool) ? _Check.free : _Check.taken;
      }
      if (marketQ != null && d['marketNameAvailable'] is bool) {
        _marketState =
            (d['marketNameAvailable'] as bool) ? _Check.free : _Check.taken;
      }
      if (subdomainQ != null && d['subdomainAvailable'] is bool) {
        _subdomainState =
            (d['subdomainAvailable'] as bool) ? _Check.free : _Check.taken;
      }
      if (d['suggestedSubdomain'] is String) {
        _suggestedSubdomain = d['suggestedSubdomain'] as String;
      }
    });
  }

  void _generatePassword() {
    final r = Random.secure();
    const upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    const lower = 'abcdefghjkmnpqrstuvwxyz';
    const digits = '23456789';
    const symbols = '!@#\$%&*';
    final all = upper + lower + digits + symbols;
    final pw = StringBuffer()
      ..write(upper[r.nextInt(upper.length)])
      ..write(lower[r.nextInt(lower.length)])
      ..write(digits[r.nextInt(digits.length)])
      ..write(symbols[r.nextInt(symbols.length)]);
    for (var i = 0; i < 8; i++) {
      pw.write(all[r.nextInt(all.length)]);
    }
    setState(() {
      _password.text = pw.toString();
      _obscurePassword = false;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_userState == _Check.taken ||
        _marketState == _Check.taken ||
        _subdomainState == _Check.taken) {
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    final res = await _service.createOwner(
      fullName: _fullName.text.trim(),
      phone: _phone.text.trim(),
      username: _username.text.trim(),
      password: _password.text,
      marketName: _marketName.text.trim(),
      subdomain: _subdomain.text.trim().isEmpty
          ? null
          : _subdomain.text.trim().toLowerCase(),
      language: _language,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (res.status == SuperAdminOpStatus.success) {
      Navigator.of(context).pop(
        CreatedOwnerResult(
          username: _username.text.trim(),
          password: _password.text,
          marketName: _marketName.text.trim(),
        ),
      );
    } else {
      setState(
          () => _errorMessage = res.message ?? "Yaratishda xatolik yuz berdi");
    }
  }

  Widget? _suffix(_Check s) {
    switch (s) {
      case _Check.checking:
        return const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _Check.free:
        return const Icon(Icons.check_circle, color: Color(0xFF137333));
      case _Check.taken:
        return const Icon(Icons.error_outline, color: Color(0xFFD93025));
      case _Check.idle:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typedSubdomain = _subdomain.text.trim().toLowerCase();
    final previewSubdomain =
        typedSubdomain.isNotEmpty ? typedSubdomain : _suggestedSubdomain;
    final disabled = _submitting ||
        _userState == _Check.taken ||
        _marketState == _Check.taken ||
        _subdomainState == _Check.taken;

    return AlertDialog(
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.person_add_outlined,
                color: Color(0xFF137333), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text("Yangi Owner qo'shish")),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Bu form ro'yxatdan o'tish so'rovini chetlab o'tadi. Faqat alohida hollar uchun (telefon orqali kelgan murojaatlar) ishlatiladi.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
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
                _Section('👤 Owner'),
                TextFormField(
                  controller: _fullName,
                  decoration: const InputDecoration(
                    labelText: "To'liq ism *",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length < 2 ? 'Ism kerak' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(
                          labelText: 'Telefon *',
                          border: OutlineInputBorder(),
                          hintText: '+998 90 ...',
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Telefon kerak';
                          if (s.replaceAll(RegExp(r'\D'), '').length < 9) {
                            return "Format noto'g'ri";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _username,
                        decoration: InputDecoration(
                          labelText: 'Username *',
                          border: const OutlineInputBorder(),
                          suffixIcon: _suffix(_userState),
                          errorText: _userState == _Check.taken
                              ? "'${_username.text.trim()}' band"
                              : null,
                          helperText: 'Min. 3 belgi',
                        ),
                        validator: (v) =>
                            (v ?? '').trim().length < 3 ? 'Min. 3' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _password,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Parol *',
                          border: const OutlineInputBorder(),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                                tooltip: "Ko'rsatish",
                              ),
                              IconButton(
                                icon: const Icon(Icons.casino_outlined),
                                onPressed: _generatePassword,
                                tooltip: 'Generate',
                              ),
                            ],
                          ),
                          helperText: 'Min. 8 belgi',
                        ),
                        validator: (v) =>
                            (v ?? '').length < 8 ? 'Min. 8' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section("🏪 Do'kon"),
                TextFormField(
                  controller: _marketName,
                  decoration: InputDecoration(
                    labelText: "Do'kon nomi *",
                    border: const OutlineInputBorder(),
                    suffixIcon: _suffix(_marketState),
                    errorText: _marketState == _Check.taken
                        ? "'${_marketName.text.trim()}' band"
                        : null,
                  ),
                  validator: (v) =>
                      (v ?? '').trim().length < 3 ? 'Min. 3' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _subdomain,
                  decoration: InputDecoration(
                    labelText: 'Subdomain (ixtiyoriy)',
                    border: const OutlineInputBorder(),
                    suffixText: '.strotech.uz',
                    suffixIcon: _suffix(_subdomainState),
                    errorText: _subdomainState == _Check.taken
                        ? "'$typedSubdomain' band"
                        : null,
                  ),
                ),
                if (previewSubdomain != null && previewSubdomain.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.public,
                            size: 13, color: Color(0xFF5F6368)),
                        const SizedBox(width: 5),
                        Text(
                          typedSubdomain.isEmpty ? 'Avto: ' : 'URL: ',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF5F6368)),
                        ),
                        Text(
                          '$previewSubdomain.strotech.uz',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: Color(0xFF1A73E8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
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
          onPressed: disabled ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check, size: 18),
          label: const Text('Yaratish'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF137333),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

enum _Check { idle, checking, free, taken }

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5F6368),
            letterSpacing: 0.5,
          ),
        ),
      );
}
