import 'package:market_system_client/l10n/app_localizations.dart';

class PhoneValidator {
  static final RegExp _uzPhoneRegex = RegExp(r'^998[0-9]{9}$');

  static bool isValid(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\s|-'), '');
    return _uzPhoneRegex.hasMatch(cleaned);
  }

  static String? validate(String? phone, {required AppLocalizations l10n}) {
    if (phone == null || phone.trim().isEmpty) {
      return l10n.phoneRequired;
    }
    if (!isValid(phone.trim())) {
      return l10n.phoneFormatHint;
    }
    return null;
  }
}
