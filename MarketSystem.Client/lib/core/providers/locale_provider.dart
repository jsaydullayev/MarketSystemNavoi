import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const String _localeKey = 'app_locale';

  Locale _locale = const Locale('uz'); // Default to Uzbek

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_localeKey) ?? 'uz';

    // Validate and fix invalid language codes
    final validLanguageCode = (languageCode == 'uz' || languageCode == 'ru' || languageCode == 'en')
        ? languageCode
        : 'uz';

    _locale = Locale(validLanguageCode);
    notifyListeners();
  }

  Future<void> setLocale(String languageCode) async {
    // Validate and fix invalid language codes
    if (languageCode.isEmpty || (languageCode != 'uz' && languageCode != 'ru' && languageCode != 'en')) {
      languageCode = 'uz'; // Default to Uzbek if invalid
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, languageCode);
    _locale = Locale(languageCode);
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('uz');
    notifyListeners();
  }
}
