import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lock_controller.dart';

class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({super.key});

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final _first = TextEditingController();
  final _second = TextEditingController();
  String? _error;
  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_first.text.length < 4) {
      setState(() => _error = 'PIN must be 4–6 digits');
      return;
    }
    if (_first.text != _second.text) {
      setState(() => _error = "PINs don't match");
      return;
    }
    setState(() => _saving = true);
    await ref.read(lockControllerProvider.notifier).setPin(_first.text);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _pinField('New PIN', _first),
            const SizedBox(height: 12),
            _pinField('Confirm PIN', _second),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(_saving ? 'Saving…' : 'Save PIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinField(String label, TextEditingController c) {
    return TextField(
      controller: c,
      obscureText: true,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
