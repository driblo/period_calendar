import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/features/security/pin_hasher.dart';

void main() {
  // Low iteration count to keep tests fast.
  const hasher = PinHasher(iterations: 1000);
  final salt = Uint8List.fromList(List<int>.filled(16, 7));

  test('verify accepts the original pin', () {
    final stored = hasher.hash('1234', salt);
    expect(hasher.verify('1234', stored), isTrue);
  });

  test('verify rejects a wrong pin', () {
    final stored = hasher.hash('1234', salt);
    expect(hasher.verify('1235', stored), isFalse);
  });

  test('different salts produce different hashes', () {
    final saltA = Uint8List.fromList(List<int>.filled(16, 1));
    final saltB = Uint8List.fromList(List<int>.filled(16, 2));
    final a = hasher.hash('1234', saltA);
    final b = hasher.hash('1234', saltB);
    expect(a, isNot(b));
  });

  test('verify rejects a malformed stored value', () {
    expect(hasher.verify('1234', 'garbage'), isFalse);
    expect(hasher.verify('1234', 'a.b'), isFalse);
  });
}
