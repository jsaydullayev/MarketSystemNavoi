// Tappable — karta / list element uchun umumiy press wrapper.
//
// Ikkita rejim:
//   1. onTap berilsa     — ZoomTapAnimation onTap + haptic handle qiladi
//   2. onTap berilmasa  — faqat scale animation (Listener orqali).
//                          InkWell ichida ishlatayin: InkWell ripple + Tappable scale.
//
// Misol (raqam 2):
//   Tappable(
//     child: Material(
//       child: InkWell(onTap: _openDetail, child: AppCard(...)),
//     ),
//   )

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class Tappable extends StatefulWidget {
  const Tappable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.scaleDown = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final double scaleDown;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // onTap berilsa — ZoomTapAnimation barcha hodisalarni boshqaradi
    if (widget.onTap != null || widget.onLongPress != null) {
      return ZoomTapAnimation(
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongTap: widget.onLongPress,
        begin: 1.0,
        end: widget.scaleDown,
        beginDuration: const Duration(milliseconds: 20),
        endDuration: const Duration(milliseconds: 180),
        beginCurve: Curves.easeIn,
        endCurve: Curves.easeOutBack,
        child: widget.child,
      );
    }

    // onTap yo'q — Listener + AnimatedScale bilan faqat scale animatsiyasi.
    // InkWell tap event'ini o'z ichida to'liq qabul qiladi (Listener arenaга
    // kirmaydi), scale child ustida qo'shimcha vizual layer sifatida ishlaydi.
    return Listener(
      onPointerDown: (_) {
        if (widget.haptic) HapticFeedback.selectionClick();
        setState(() => _pressed = true);
      },
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scaleDown : 1.0,
        duration: Duration(milliseconds: _pressed ? 20 : 180),
        curve: _pressed ? Curves.easeIn : Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
