import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/warm_palette.dart';
import 'lock_controller.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final ctrl = ref.read(lockControllerProvider.notifier);
    final state = ref.read(lockControllerProvider);
    if (state.biometricEnabled) {
      try {
        await ctrl.tryBiometric();
      } catch (_) {
        // Biometric failed; PIN still available.
      }
    }
  }

  Future<void> _submit() async {
    if (_checking) return;
    setState(() => _checking = true);
    final ok = await ref
        .read(lockControllerProvider.notifier)
        .verifyPin(_controller.text);
    setState(() {
      _checking = false;
      _error = ok ? null : 'Incorrect PIN';
      if (!ok) _controller.clear();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: WarmPalette.clay),
              const SizedBox(height: 16),
              Text(
                'Period Calendar is locked',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'PIN',
                  errorText: _error,
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _checking ? null : _submit,
                child: Text(_checking ? 'Checking…' : 'Unlock'),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _tryBiometric,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Use biometric'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
