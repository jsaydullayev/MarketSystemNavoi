import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

extension AppL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

extension DoubleExtension on double {
  Widget get height => SizedBox(height: this);
  Widget get width => SizedBox(width: this);
}

extension IntExtension on int {
  Widget get height => SizedBox(height: toDouble());
  Widget get width => SizedBox(width: toDouble());
}
