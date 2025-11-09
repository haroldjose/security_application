import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveSession(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getSession(String key) async {
    return await _storage.read(key: key);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
