import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'base64_bytes_cache.dart';

class Base64Image extends StatefulWidget {
  const Base64Image({
    super.key,
    required this.base64,
    required this.cache,
    this.fit,
    this.width,
    this.height,
    this.useIsolate = false,
  });

  final String base64;
  final Base64BytesCache cache;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final bool useIsolate;

  @override
  State<Base64Image> createState() => _Base64ImageState();
}

class _Base64ImageState extends State<Base64Image> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.cache.decode(widget.base64, useIsolate: widget.useIsolate);
  }

  @override
  void didUpdateWidget(covariant Base64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.base64 != widget.base64 || oldWidget.useIsolate != widget.useIsolate) {
      _bytesFuture = widget.cache.decode(widget.base64, useIsolate: widget.useIsolate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return Image.memory(
          snapshot.data!,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          gaplessPlayback: true,
        );
      },
    );
  }
}

