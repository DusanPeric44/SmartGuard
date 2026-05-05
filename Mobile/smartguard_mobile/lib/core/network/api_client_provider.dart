import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import 'api_client.dart';
import 'auth_http_transport.dart';
import 'io_http_transport.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.read(sessionControllerProvider.notifier);
  return ApiClient(
    transport: AuthHttpTransport(inner: IoHttpTransport(), session: session),
  );
});
