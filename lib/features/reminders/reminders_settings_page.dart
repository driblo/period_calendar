import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../core/widgets/warm_card.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../calendar/calendar_providers.dart';
import 'reminder_models.dart';
import 'reminder_scheduler.dart';

final remindersListProvider = StreamProvider<List<Reminder>>(
  (ref) => ref.watch(appDatabaseProvider).remindersDao.watchAll(),
);

final reminderSchedulerProvider = Provider<ReminderScheduler>(
  (ref) => ReminderScheduler(),
);

class RemindersSettingsPage extends ConsumerWidget {
  const RemindersSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reminders) {
          final byType = {for (final r in reminders) r.type: r};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(title: 'Notifications'),
              _row(
                context,
                ref,
                title: 'Period coming soon',
                subtitle: '2 days before predicted start',
                type: ReminderType.periodSoon,
                hour: 9,
                minute: 0,
                daysBefore: 2,
                existing: byType[ReminderType.periodSoon.name],
              ),
              const SizedBox(height: 12),
              _row(
                context,
                ref,
                title: 'Log today',
                subtitle: 'Daily nudge at 20:30',
                type: ReminderType.logToday,
                hour: 20,
                minute: 30,
                existing: byType[ReminderType.logToday.name],
              ),
              const SizedBox(height: 12),
              _row(
                context,
                ref,
                title: 'Pill reminder',
                subtitle: 'Daily at 08:00',
                type: ReminderType.pill,
                hour: 8,
                minute: 0,
                existing: byType[ReminderType.pill.name],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String subtitle,
    required ReminderType type,
    required int hour,
    required int minute,
    int daysBefore = 0,
    Reminder? existing,
  }) {
    final enabled = existing?.enabled ?? false;
    return WarmCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (v) async {
              final dao = ref.read(appDatabaseProvider).remindersDao;
              if (existing == null) {
                await dao.upsert(
                  RemindersCompanion.insert(
                    type: type.name,
                    hour: hour,
                    minute: minute,
                    daysBefore: Value(daysBefore),
                    enabled: Value(v),
                  ),
                );
              } else {
                await dao.upsert(
                  RemindersCompanion(
                    id: Value(existing.id),
                    type: Value(existing.type),
                    hour: Value(existing.hour),
                    minute: Value(existing.minute),
                    daysBefore: Value(existing.daysBefore),
                    enabled: Value(v),
                  ),
                );
              }
              await _reschedule(ref);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _reschedule(WidgetRef ref) async {
    final scheduler = ref.read(reminderSchedulerProvider);
    final prediction = ref.read(cyclePredictionProvider);
    final reminders = await ref.read(appDatabaseProvider).remindersDao.getAll();
    final specs = reminders
        .map(
          (r) => ReminderSpec(
            type: ReminderType.fromName(r.type),
            hour: r.hour,
            minute: r.minute,
            daysBefore: r.daysBefore,
            enabled: r.enabled,
          ),
        )
        .toList();
    await scheduler.reschedule(reminders: specs, prediction: prediction);
  }
}
