import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import 'signalr_constants.dart';

enum SignalRConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class SignalRClient {
  SignalRClient._(this._connection);

  final HubConnection _connection;

  final _statusController =
      StreamController<SignalRConnectionStatus>.broadcast();
  SignalRConnectionStatus _status = SignalRConnectionStatus.disconnected;

  Stream<SignalRConnectionStatus> get statusStream => _statusController.stream;

  SignalRConnectionStatus get status => _status;

  static SignalRClient build({
    required Uri baseUri,
    required String hubPath,
    required Future<String?> Function() accessTokenProvider,
    List<Duration> reconnectDelays = SignalRConstants.reconnectDelays,
  }) {
    final url = baseUri.resolve(
      hubPath.startsWith('/') ? hubPath.substring(1) : hubPath,
    );

    final connection = HubConnectionBuilder()
        .withUrl(
          url.toString(),
          options: HttpConnectionOptions(
            accessTokenFactory: () async => (await accessTokenProvider()) ?? '',
          ),
        )
        .withAutomaticReconnect(
          retryDelays: reconnectDelays.map((d) => d.inMilliseconds).toList(),
        )
        .build();

    return SignalRClient._(connection);
  }

  Future<void> start() async {
    if (_connection.state == HubConnectionState.Connected ||
        _connection.state == HubConnectionState.Connecting) {
      return;
    }

    _setStatus(SignalRConnectionStatus.connecting);

    _connection.onreconnecting(({error}) {
      _setStatus(SignalRConnectionStatus.reconnecting);
    });
    _connection.onreconnected(({connectionId}) {
      _setStatus(SignalRConnectionStatus.connected);
    });
    _connection.onclose(({error}) {
      _setStatus(SignalRConnectionStatus.disconnected);
    });

    await _connection.start();
    _setStatus(SignalRConnectionStatus.connected);
  }

  Future<void> stop() async {
    if (_connection.state == HubConnectionState.Disconnected) return;
    await _connection.stop();
    _setStatus(SignalRConnectionStatus.disconnected);
  }

  void on(String methodName, void Function(List<Object?>? args) handler) {
    _connection.on(methodName, handler);
  }

  void off(String methodName) {
    _connection.off(methodName);
  }

  Future<void> dispose() async {
    await stop();
    await _statusController.close();
  }

  void _setStatus(SignalRConnectionStatus next) {
    if (_status == next) return;
    _status = next;
    _statusController.add(next);
  }
}
