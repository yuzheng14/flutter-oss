class AsyncPool {
  final int limit;
  int _handlings = 0;

  AsyncPool({required this.limit});

  Future<R> runInPool<R>(Future<R> Function() handler) async {
    while (_handlings > limit) await Future.delayed(Duration.zero);
    _handlings++;
    try {
      final res = await handler();
      return res;
    } catch (error) {
      throw error;
    } finally {
      _handlings--;
    }
  }
}
