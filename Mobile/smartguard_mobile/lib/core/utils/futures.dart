Future<List<T>> waitAll<T>(Iterable<Future<T>> futures) {
  return Future.wait<T>(futures);
}

