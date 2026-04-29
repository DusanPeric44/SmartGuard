class HttpTransportRequest {
  HttpTransportRequest({
    required this.method,
    required this.uri,
    required this.headers,
    required this.timeout,
    this.bodyBytes,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final Duration timeout;
  final List<int>? bodyBytes;
}

class HttpTransportResponse {
  HttpTransportResponse({
    required this.statusCode,
    required this.headers,
    required this.bodyBytes,
  });

  final int statusCode;
  final Map<String, String> headers;
  final List<int> bodyBytes;
}

abstract interface class HttpTransport {
  Future<HttpTransportResponse> send(HttpTransportRequest request);
}
