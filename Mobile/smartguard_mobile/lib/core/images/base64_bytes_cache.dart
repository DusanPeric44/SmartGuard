import 'dart:convert';

import 'package:flutter/foundation.dart';

Uint8List _decodeBase64(String input) {
  return base64Decode(input);
}

typedef Base64Decoder = Uint8List Function(String);

class Base64BytesCache {
  Base64BytesCache({Base64Decoder decoder = _decodeBase64}) : _decoder = decoder;

  final Base64Decoder _decoder;
  final Map<String, Uint8List> _cache = <String, Uint8List>{};

  Uint8List decodeSync(String base64) {
    final cached = _cache[base64];
    if (cached != null) {
      return cached;
    }

    final bytes = _decoder(base64);
    _cache[base64] = bytes;
    return bytes;
  }

  Future<Uint8List> decode(String base64, {bool useIsolate = false}) async {
    final cached = _cache[base64];
    if (cached != null) {
      return cached;
    }

    final bytes = useIsolate
        ? await compute(_decodeBase64, base64)
        : _decoder(base64);
    _cache[base64] = bytes;
    return bytes;
  }
}
