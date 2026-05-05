import 'package:smart_guard_flutter/core/network/http_transport.dart';

class FakeHttpTransport implements HttpTransport {
  FakeHttpTransport(this._handler);

  final Future<HttpTransportResponse> Function(HttpTransportRequest request)
  _handler;

  final List<HttpTransportRequest> requests = [];

  @override
  Future<HttpTransportResponse> send(HttpTransportRequest request) async {
    requests.add(request);
    return _handler(request);
  }
}
