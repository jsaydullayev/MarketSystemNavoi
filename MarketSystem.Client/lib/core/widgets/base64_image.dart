import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Renders a base64-encoded image, decoding the string ONCE (in initState and
/// again only when [data] actually changes) and caching the resulting bytes.
///
/// The anti-pattern this replaces: calling `Image.memory(base64Decode(str))`
/// directly inside a widget's build(). base64Decode of a ~200KB avatar is
/// ~10ms of synchronous CPU on a mid-range phone, and build() runs on every
/// rebuild (e.g. a listening Provider firing on token refresh) — so the decode
/// was paid over and over for an image that never changed.
///
/// [cacheWidth]/[cacheHeight] additionally tell the engine to decode the
/// bitmap at the display size rather than full resolution.
class Base64Image extends StatefulWidget {
  const Base64Image({
    super.key,
    required this.data,
    required this.errorWidget,
    this.width,
    this.height,
    this.cacheWidth,
    this.cacheHeight,
    this.fit = BoxFit.cover,
  });

  /// Raw base64 payload (any leading `data:image/...;base64,` prefix should be
  /// stripped by the caller).
  final String data;

  /// Shown when the payload can't be decoded or the bitmap fails to render.
  final Widget errorWidget;

  final double? width;
  final double? height;
  final int? cacheWidth;
  final int? cacheHeight;
  final BoxFit fit;

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) _decode();
  }

  void _decode() {
    try {
      _bytes = base64Decode(widget.data);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return widget.errorWidget;
    return Image.memory(
      bytes,
      width: widget.width,
      height: widget.height,
      cacheWidth: widget.cacheWidth,
      cacheHeight: widget.cacheHeight,
      fit: widget.fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => widget.errorWidget,
    );
  }
}
