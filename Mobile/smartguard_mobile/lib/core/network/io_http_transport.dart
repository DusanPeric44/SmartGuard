import 'dart:async';
import 'dart:io';

import 'http_transport.dart';

class IoHttpTransport implements HttpTransport {
  IoHttpTransport({
    HttpClient? httpClient,
    this.connectionTimeout = const Duration(seconds: 10),
  }) : _httpClient = httpClient ?? HttpClient();

  final HttpClient _httpClient;
  final Duration connectionTimeout;

  @override
  Future<HttpTransportResponse> send(HttpTransportRequest request) async {
    _httpClient.connectionTimeout = connectionTimeout;

    final httpRequest = await _httpClient
        .openUrl(request.method, request.uri)
        .timeout(request.timeout);

    request.headers.forEach(httpRequest.headers.set);

    if (request.bodyBytes != null) {
      httpRequest.add(request.bodyBytes!);
    }

    final httpResponse = await httpRequest.close().timeout(request.timeout);

    final headers = <String, String>{};
    httpResponse.headers.forEach((name, values) {
      headers[name.toLowerCase()] = values.join(', ');
    });

    final bodyBytes = await _collectBytes(
      httpResponse,
    ).timeout(request.timeout);

    return HttpTransportResponse(
      statusCode: httpResponse.statusCode,
      headers: Map.unmodifiable(headers),
      bodyBytes: bodyBytes,
    );
  }

  Future<List<int>> _collectBytes(HttpClientResponse response) {
    final completer = Completer<List<int>>();
    final bytes = <int>[];

    response.listen(
      bytes.addAll,
      onDone: () => completer.complete(List.unmodifiable(bytes)),
      onError: completer.completeError,
      cancelOnError: true,
    );

    return completer.future;
  }
}
