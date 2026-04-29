enum ApiErrorKind {
  network,
  timeout,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  invalidResponse,
  unknown,
}

class ApiError {
  const ApiError({
    required this.kind,
    this.statusCode,
    this.message,
    this.details,
    this.uri,
  });

  final ApiErrorKind kind;
  final int? statusCode;
  final String? message;
  final Object? details;
  final Uri? uri;
}

class ApiException implements Exception {
  const ApiException(this.error);

  final ApiError error;

  @override
  String toString() {
    final status = error.statusCode == null ? '' : ' (${error.statusCode})';
    final msg = error.message == null ? '' : ': ${error.message}';
    return 'ApiException: ${error.kind}$status$msg';
  }
}

