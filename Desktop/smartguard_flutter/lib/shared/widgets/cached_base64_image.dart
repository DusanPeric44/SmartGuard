import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class CachedBase64Image extends StatefulWidget {
  const CachedBase64Image({
    super.key,
    required this.base64Value,
    this.width = 56,
    this.height = 56,
    this.borderRadius = 12,
  });

  final String base64Value;
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<CachedBase64Image> createState() => _CachedBase64ImageState();
}

class _CachedBase64ImageState extends State<CachedBase64Image> {
  Uint8List? _cachedBytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant CachedBase64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64Value != widget.base64Value) {
      _decode();
    }
  }

  void _decode() {
    final normalized = widget.base64Value.trim();
    final payload = normalized.contains(',')
        ? normalized.substring(normalized.indexOf(',') + 1)
        : normalized;
    try {
      _cachedBytes = base64Decode(payload);
    } catch (_) {
      _cachedBytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _cachedBytes;
    if (bytes == null) {
      return _FallbackBox(
        width: widget.width,
        height: widget.height,
        borderRadius: widget.borderRadius,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
    );
  }
}

class _FallbackBox extends StatelessWidget {
  const _FallbackBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person_outline),
    );
  }
}
