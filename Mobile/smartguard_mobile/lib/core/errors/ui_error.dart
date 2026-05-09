import 'package:flutter/foundation.dart';

enum UiErrorType { network, timeout, unauthorized, validation, server, unknown }

@immutable
class UiError {
  const UiError({required this.type, required this.message});

  final UiErrorType type;
  final String message;
}

