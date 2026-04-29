abstract interface class LiveStreamRepository {
  Future<void> connect();
  Future<void> disconnect();
}

class StubLiveStreamRepository implements LiveStreamRepository {
  const StubLiveStreamRepository();

  @override
  Future<void> connect() async {}

  @override
  Future<void> disconnect() async {}
}
