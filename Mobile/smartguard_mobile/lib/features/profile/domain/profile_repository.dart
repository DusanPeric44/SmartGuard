abstract interface class ProfileRepository {
  Future<String?> loadDisplayName();
}

class StubProfileRepository implements ProfileRepository {
  const StubProfileRepository();

  @override
  Future<String?> loadDisplayName() async {
    return null;
  }
}
