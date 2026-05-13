import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../core/widgets/warm_card.dart';
import '../../data/providers.dart';
import 'lock_controller.dart';
import 'pin_setup_page.dart';

class SecuritySettingsPage extends ConsumerWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lockControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(title: 'App lock'),
          WarmCard(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PinSetupPage()),
            ),
            child: Row(
              children: [
                const Icon(Icons.password),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.hasPin ? 'Change PIN' : 'Set PIN',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.hasPin
                            ? 'PIN is set. App will lock on background.'
                            : '4–6 digits, stored securely on this device.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: 12),
          WarmCard(
            child: Row(
              children: [
                const Icon(Icons.fingerprint),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Use biometric',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Switch(
                  value: state.biometricEnabled,
                  onChanged: state.hasPin
                      ? (v) => ref
                          .read(lockControllerProvider.notifier)
                          .setBiometric(v)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Your data'),
          WarmCard(
            onTap: () => _exportData(context, ref),
            child: _row(
              context,
              icon: Icons.ios_share,
              title: 'Export data (JSON)',
              subtitle: 'Copy your cycle, daily log, and symptom data',
            ),
          ),
          const SizedBox(height: 12),
          WarmCard(
            onTap: () => _confirmDelete(context, ref),
            child: _row(
              context,
              icon: Icons.delete_outline,
              title: 'Delete all data',
              subtitle: 'Wipes the encrypted DB, PIN, and biometric setting',
              destructive: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool destructive = false,
  }) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: color),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const Icon(Icons.chevron_right),
      ],
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(appDatabaseProvider);
    final cycles = await db.cycleDao.getAll();
    final logs = await db.select(db.dailyLogs).get();
    final symptoms = await db.select(db.symptoms).get();

    final dump = {
      'exportedAt': DateTime.now().toIso8601String(),
      'cycles': [
        for (final c in cycles)
          {
            'id': c.id,
            'startDate': c.startDate.toIso8601String(),
            'endDate': c.endDate?.toIso8601String(),
            'notes': c.notes,
          },
      ],
      'dailyLogs': [
        for (final l in logs)
          {
            'id': l.id,
            'date': l.date.toIso8601String(),
            'mood': l.mood,
            'energy': l.energy,
            'flow': l.flow,
            'notes': l.notes,
          },
      ],
      'symptoms': [
        for (final s in symptoms)
          {
            'id': s.id,
            'dailyLogId': s.dailyLogId,
            'type': s.type,
            'severity': s.severity,
          },
      ],
    };

    final json = const JsonEncoder.withIndent('  ').convert(dump);
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data copied to clipboard')),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete everything?'),
        content: const Text(
          'This permanently erases all logged cycles, daily logs, symptoms, '
          'reminders, and your PIN. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text('Last chance to keep your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep my data'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            ),
            child: const Text('Delete forever'),
          ),
        ],
      ),
    );
    if (second != true || !context.mounted) return;

    final db = ref.read(appDatabaseProvider);
    await db.batch((b) {
      b.deleteAll(db.symptoms);
      b.deleteAll(db.dailyLogs);
      b.deleteAll(db.cycles);
      b.deleteAll(db.appSettings);
      b.deleteAll(db.reminders);
    });
    await ref.read(lockControllerProvider.notifier).wipe();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All data deleted')),
    );
  }
}
