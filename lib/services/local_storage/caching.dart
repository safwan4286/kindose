part of 'local_storage.dart';

class Caching {
  static Caching? _instance;

  factory Caching() {
    _instance ??= Caching._internal();
    return _instance!;
  }

  Caching._internal();

  final LocalStorage _localStorage = LocalStorage();

  // Read data from a box
  Future<T?> readData<T>({
    required String boxName,
    required String key,
  }) async {
    final storedData =
    await _localStorage.readData<T>(boxName: boxName, key: key);
    return storedData;
  }
}
