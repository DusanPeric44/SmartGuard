import 'dart:convert';

enum ApiErrorType { network, timeout, http, invalidResponse }

class ApiError {
  ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.messages = const [],
    this.validation = const {},
    this.rawBody,
    this.cause,
  });

  final ApiErrorType type;
  final int? statusCode;
  final String message;
  final List<String> messages;
  final Map<String, List<String>> validation;
  final String? rawBody;
  final Object? cause;

  static ApiError network(Object error) {
    return ApiError(
      type: ApiErrorType.network,
      message: 'Network error',
      cause: error,
    );
  }

  static ApiError timeout(Object error) {
    return ApiError(
      type: ApiErrorType.timeout,
      message: 'Request timeout',
      cause: error,
    );
  }

  static ApiError invalidResponse(Object error) {
    return ApiError(
      type: ApiErrorType.invalidResponse,
      message: 'Invalid response',
      cause: error,
    );
  }

  factory ApiError.fromHttpResponse({
    required int statusCode,
    required String body,
    required Map<String, String> headers,
  }) {
    final trimmed = body.trim();
    final isJson =
        headers['content-type']?.toLowerCase().contains('application/json') ==
            true ||
        trimmed.startsWith('{') ||
        trimmed.startsWith('[');

    if (!isJson) {
      final msg = trimmed.isNotEmpty ? trimmed : 'HTTP $statusCode';
      return ApiError(
        type: ApiErrorType.http,
        statusCode: statusCode,
        message: msg,
        messages: trimmed.isNotEmpty ? [trimmed] : const [],
        rawBody: body,
      );
    }

    try {
      final decoded = jsonDecode(trimmed);

      if (decoded is Map<String, dynamic>) {
        final validation = _extractValidation(decoded);
        final messages = _extractMessages(decoded, validation);
        final msg = messages.isNotEmpty ? messages.first : 'HTTP $statusCode';

        return ApiError(
          type: ApiErrorType.http,
          statusCode: statusCode,
          message: msg,
          messages: messages,
          validation: validation,
          rawBody: body,
        );
      }

      if (decoded is List) {
        final messages = decoded.whereType<String>().toList(growable: false);
        final msg = messages.isNotEmpty ? messages.first : 'HTTP $statusCode';

        return ApiError(
          type: ApiErrorType.http,
          statusCode: statusCode,
          message: msg,
          messages: messages,
          rawBody: body,
        );
      }

      return ApiError(
        type: ApiErrorType.http,
        statusCode: statusCode,
        message: 'HTTP $statusCode',
        rawBody: body,
      );
    } catch (e) {
      final msg = trimmed.isNotEmpty ? trimmed : 'HTTP $statusCode';
      return ApiError(
        type: ApiErrorType.http,
        statusCode: statusCode,
        message: msg,
        messages: trimmed.isNotEmpty ? [trimmed] : const [],
        rawBody: body,
        cause: e,
      );
    }
  }

  static Map<String, List<String>> _extractValidation(
    Map<String, dynamic> decoded,
  ) {
    final dynamic errors = decoded['errors'] ?? decoded['validationErrors'];
    if (errors is! Map) return const {};

    final result = <String, List<String>>{};
    for (final entry in errors.entries) {
      final key = entry.key?.toString() ?? '';
      final value = entry.value;
      final messages = _stringList(value);
      if (messages.isNotEmpty) {
        result[key] = messages;
      }
    }
    return Map.unmodifiable(result);
  }

  static List<String> _extractMessages(
    Map<String, dynamic> decoded,
    Map<String, List<String>> validation,
  ) {
    final out = <String>[];

    void add(dynamic value) {
      final strings = _stringList(value);
      for (final s in strings) {
        final trimmed = s.trim();
        if (trimmed.isNotEmpty) out.add(trimmed);
      }
    }

    add(decoded['message']);
    add(decoded['detail']);
    add(decoded['error']);
    add(decoded['title']);

    final dynamic errors = decoded['errors'] ?? decoded['validationErrors'];
    if (errors is List) {
      add(errors);
    }

    for (final entry in validation.entries) {
      out.addAll(entry.value);
    }

    final deduped = <String>[];
    final seen = <String>{};
    for (final m in out) {
      if (seen.add(m)) deduped.add(m);
    }
    return List.unmodifiable(deduped);
  }

  static List<String> _stringList(dynamic value) {
    if (value == null) return const [];
    if (value is String) return [value];
    if (value is List) {
      return value.whereType<String>().toList(growable: false);
    }
    return [value.toString()];
  }
}
