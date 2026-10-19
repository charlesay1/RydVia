import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth credentials use platform secure storage. Ordinary appearance settings
/// may use shared preferences; auth sessions never fall back to plaintext.
class SecureSessionStore extends LocalStorage {
  const SecureSessionStore(this.key);
  final String key;
  static const _storage = FlutterSecureStorage();
  @override
  Future<void> initialize() async {}
  @override
  Future<String?> accessToken() => _storage.read(key: key);
  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => _storage.delete(key: key);
}
