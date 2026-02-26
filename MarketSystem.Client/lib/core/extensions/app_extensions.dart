import 'package:flutter/material.dart';

extension DoubleExtension on double {
  Widget get height => SizedBox(height: this);
  Widget get width => SizedBox(width: this);
}

extension IntExtension on int {
  Widget get height => SizedBox(height: this.toDouble());
  Widget get width => SizedBox(width: this.toDouble());
}
