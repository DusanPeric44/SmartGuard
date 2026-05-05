import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_guard_flutter/core/images/base64_bytes_cache.dart';

void main() {
  test('Base64BytesCache caches decodeSync', () {
    var calls = 0;
    Uint8List decoder(String input) {
      calls += 1;
      return base64Decode(input);
    }

    final cache = Base64BytesCache(decoder: decoder);
    final base64 = base64Encode(Uint8List.fromList([1, 2, 3]));

    final a = cache.decodeSync(base64);
    final b = cache.decodeSync(base64);

    expect(calls, 1);
    expect(identical(a, b), isTrue);
    expect(a, Uint8List.fromList([1, 2, 3]));
  });

  test('Base64BytesCache caches decode', () async {
    var calls = 0;
    Uint8List decoder(String input) {
      calls += 1;
      return base64Decode(input);
    }

    final cache = Base64BytesCache(decoder: decoder);
    final base64 = base64Encode(Uint8List.fromList([4, 5]));

    final a = await cache.decode(base64);
    final b = await cache.decode(base64);

    expect(calls, 1);
    expect(identical(a, b), isTrue);
    expect(a, Uint8List.fromList([4, 5]));
  });
}

