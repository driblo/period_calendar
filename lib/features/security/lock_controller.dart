import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'pin_hasher.dart';

const _kPinKey = 'app_lock_pin_v1';
const _kBiometricKey = 'app_lock_biometric_v1';

class LockState {
  const LockState({
    required this.hasPin,
    required this.biometricEnabled,
    required this.locked,
  });

  final bool hasPin;
  final bool biometricEnabled;
  final bool locked;

  LockState copyWith({bool? hasPin, bool? biometricEnabled, bool? locked}) =>
      LockState(
        hasPin: hasPin ?? this.hasPin,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        locked: locked ?? this.locked,
      );

  static const initial = LockState(
    hasPin: false,
    biometricEnabled: false,
    locked: false,
  );
}

class LockController extends StateNotifier<LockState> {
  LockController({
    FlutterSecureStorage? storage,
    LocalAuthentication? localAuth,
    PinHasher? hasher,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            ),
        _localAuth = localAuth ?? LocalAuthentication(),
        _hasher = hasher ?? const PinHasher(),
        super(LockState.initial);

  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;
  final PinHasher _hasher;

  Future<void> load() async {
    final pin = await _storage.read(key: _kPinKey);
    final bio = await _storage.read(key: _kBiometricKey);
    state = LockState(
      hasPin: pin != null,
      biometricEnabled: bio == 'true',
      locked: pin != null,
    );
  }

  Future<void> setPin(String pin) async {
    final rand = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => rand.nextInt(256)),
    );
    final stored = _hasher.hash(pin, salt);
    await _storage.write(key: _kPinKey, value: stored);
    state = state.copyWith(hasPin: true, locked: false);
  }

  Future<bool> verifyPin(String pin) async {
    final stored = await _storage.read(key: _kPinKey);
    if (stored == null) return false;
    final ok = _hasher.verify(pin, stored);
    if (ok) state = state.copyWith(locked: false);
    return ok;
  }

  Future<bool> tryBiometric() async {
    if (!state.biometricEnabled) return false;
    final supported = await _localAuth.isDeviceSupported();
    if (!supported) return false;
    final ok = await _localAuth.authenticate(
      localizedReason: 'Unlock Period Calendar',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
    if (ok) state = state.copyWith(locked: false);
    return ok;
  }

  Future<void> setBiometric(bool enabled) async {
    await _storage.write(key: _kBiometricKey, value: enabled.toString());
    state = state.copyWith(biometricEnabled: enabled);
  }

  void lock() => state = state.copyWith(locked: true);

  Future<void> wipe() async {
    await _storage.delete(key: _kPinKey);
    await _storage.delete(key: _kBiometricKey);
    state = LockState.initial;
  }
}

final lockControllerProvider = StateNotifierProvider<LockController, LockState>(
  (ref) => LockController(),
);

/// Re-lock the app after [timeout] in background.
class LockOnBackground extends ConsumerStatefulWidget {
  const LockOnBackground({
    super.key,
    required this.child,
    this.timeout = const Duration(seconds: 30),
  });

  final Widget child;
  final Duration timeout;

  @override
  ConsumerState<LockOnBackground> createState() => _LockOnBackgroundState();
}

class _LockOnBackgroundState extends ConsumerState<LockOnBackground>
    with WidgetsBindingObserver {
  DateTime? _backgroundedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = ref.read(lockControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final bg = _backgroundedAt;
      if (bg != null &&
          DateTime.now().difference(bg) > widget.timeout &&
          ref.read(lockControllerProvider).hasPin) {
        ctrl.lock();
      }
      _backgroundedAt = null;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
