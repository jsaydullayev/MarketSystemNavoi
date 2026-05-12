import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/registration_request.dart';

/// Returns the reason text, or null if the operator cancelled.
class RejectRequestDialog extends StatefulWidget {
  const RejectRequestDialog({super.key, required this.request});
  final RegistrationRequest request;

  @override
  State<RejectRequestDialog> createState() => _RejectRequestDialogState();
}

class _RejectRequestDialogState extends State<RejectRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _reasonController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.superAdminRejectTitle),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.request.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(widget.request.phone,
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                minLines: 2,
                maxLength: 500,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.superAdminRejectReason,
                  hintText: l10n.superAdminRejectReasonHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final t = v?.trim() ?? '';
                  if (t.isEmpty) return l10n.superAdminRejectReasonRequired;
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.close),
          label: Text(l10n.superAdminReject),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
