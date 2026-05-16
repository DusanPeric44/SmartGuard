import 'package:flutter/foundation.dart';

@immutable
class PagedResult<T> {
  const PagedResult({
    required this.count,
    required this.result,
  });

  final int count;
  final List<T> result;
}

