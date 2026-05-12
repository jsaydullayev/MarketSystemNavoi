import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';

/// Shown after a successful approval so the SuperAdmin can copy the
/// credentials they just chose and hand them to the new owner out of band
/// (SMS, phone call). The password is NOT stored anywhere — once this
/// dialog closes there is no way to recover it.
///
/// The dialog also reminds the operator that everything in here is
/// sensitive: it auto-hides the password until the operator taps the
/// reveal icon, mirroring how a manager would treat written-down secrets.
class CredentialsHandoffDialog extends StatefulWidget {
  const CredentialsHandoffDialog({
    super.key,
    required this.username,
    required this.password,
    required this.marketName,
  });

  final String username;
  final String password;
  final String marketName;

  @override
  State<CredentialsHandoffDialog> createState() =>
      _CredentialsHandoffDialogState();
}

class _CredentialsHandoffDialogState extends State<CredentialsHandoffDialog> {
  bool _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.superAdminCredentialsTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.superAdminCredentialsSubtitle(widget.marketName),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 16),
          _CredentialRow(
            label: l10n.username,
            value: widget.username,
            obscure: false,
          ),
          const SizedBox(height: 8),
          _CredentialRow(
            label: l10n.password,
            value: widget.password,
            obscure: !_passwordVisible,
            onToggleObscure: () =>
                setState(() => _passwordVisible = !_passwordVisible),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.amber.shade800, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.superAdminCredentialsWarning,
                    style: TextStyle(
                        fontSize: 12, color: Colors.amber.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: Text(l10n.superAdminCredentialsCopyBoth),
          onPressed: () async {
            final payload =
                '${widget.username}\n${widget.password}\n${widget.marketName}';
            await Clipboard.setData(ClipboardData(text: payload));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.superAdminCredentialsCopied),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.superAdminCredentialsDone),
        ),
      ],
    );
  }
}

class _CredentialRow extends StatelessWidget {
  const _CredentialRow({
    required this.label,
    required this.value,
    required this.obscure,
    this.onToggleObscure,
  });

  final String label;
  final String value;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  obscure ? '•' * value.length : value,
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          if (onToggleObscure != null)
            IconButton(
              tooltip: obscure ? 'Show' : 'Hide',
              icon: Icon(obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
              onPressed: onToggleObscure,
            ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_outlined),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
            },
          ),
        ],
      ),
    );
  }
}
