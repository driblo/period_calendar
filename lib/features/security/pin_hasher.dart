import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Pure-Dart PIN hashing with PBKDF2-HMAC-SHA256.
/// `bcrypt` would be ideal but adds native deps; PBKDF2 + 32-byte random salt
/// and 100k iterations is sufficient for a 4–6 digit local PIN since the
/// salt+hash live behind secure storage.
class PinHasher {
  const PinHasher({this.iterations = 100000});
  final int iterations;

  /// Returns `iterations.base64Salt.base64Hash`.
  String hash(String pin, Uint8List salt) {
    final derived = _pbkdf2Sha256(
      password: utf8.encode(pin),
      salt: salt,
      iterations: iterations,
      keyLengthBytes: 32,
    );
    return '$iterations.${base64UrlEncode(salt)}.${base64UrlEncode(derived)}';
  }

  bool verify(String pin, String stored) {
    final parts = stored.split('.');
    if (parts.length != 3) return false;
    final iters = int.tryParse(parts[0]);
    if (iters == null) return false;
    final salt = base64Url.decode(parts[1]);
    final expected = parts[2];
    final candidate = _pbkdf2Sha256(
      password: utf8.encode(pin),
      salt: salt,
      iterations: iters,
      keyLengthBytes: 32,
    );
    return _constantTimeEquals(base64UrlEncode(candidate), expected);
  }

  Uint8List _pbkdf2Sha256({
    required List<int> password,
    required List<int> salt,
    required int iterations,
    required int keyLengthBytes,
  }) {
    final hmac = Hmac(sha256, password);
    final blocksNeeded = (keyLengthBytes / 32).ceil();
    final out = BytesBuilder();

    for (var i = 1; i <= blocksNeeded; i++) {
      final block = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..[salt.length] = (i >> 24) & 0xff
        ..[salt.length + 1] = (i >> 16) & 0xff
        ..[salt.length + 2] = (i >> 8) & 0xff
        ..[salt.length + 3] = i & 0xff;

      var u = Uint8List.fromList(hmac.convert(block).bytes);
      final t = Uint8List.fromList(u);
      for (var j = 1; j < iterations; j++) {
        u = Uint8List.fromList(hmac.convert(u).bytes);
        for (var k = 0; k < t.length; k++) {
          t[k] ^= u[k];
        }
      }
      out.add(t);
    }
    return Uint8List.fromList(out.toBytes().sublist(0, keyLengthBytes));
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
