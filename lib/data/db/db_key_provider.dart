import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kDbKeyAlias = 'period_calendar_db_key_v1';

class DbKeyProvider {
  DbKeyProvider({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  /// Returns the persisted DB encryption key, generating one on first call.
  Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _kDbKeyAlias);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = _generateKey();
    await _storage.write(key: _kDbKeyAlias, value: generated);
    return generated;
  }

  Future<void> wipe() => _storage.delete(key: _kDbKeyAlias);

  static String _generateKey() {
    final rand = Random.secure();
    final bytes = List<int>.generate(32, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
