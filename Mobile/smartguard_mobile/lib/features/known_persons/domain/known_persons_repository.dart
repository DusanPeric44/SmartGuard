abstract interface class KnownPersonsRepository {
  Future<List<String>> loadKnownPersonNames();
}

class StubKnownPersonsRepository implements KnownPersonsRepository {
  const StubKnownPersonsRepository();

  @override
  Future<List<String>> loadKnownPersonNames() async {
    return const [];
  }
}
