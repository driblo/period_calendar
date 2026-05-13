import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../predictions/cycle_predictor.dart';
import 'reminder_models.dart';
import 'reminder_scheduling.dart';

const _channelId = 'period_calendar_reminders';
const _channelName = 'Reminders';

class ReminderScheduler {
  ReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<void> reschedule({
    required List<ReminderSpec> reminders,
    required CyclePrediction prediction,
    DateTime? now,
  }) async {
    await init();
    await _plugin.cancelAll();
    const sched = ReminderScheduling();
    final reference = now ?? DateTime.now();

    for (var i = 0; i < reminders.length; i++) {
      final spec = reminders[i];
      final fire = sched.nextFire(
        spec: spec,
        prediction: prediction,
        now: reference,
      );
      if (fire == null) continue;
      await _plugin.zonedSchedule(
        i,
        _titleFor(spec.type),
        _bodyFor(spec.type),
        tz.TZDateTime.from(fire, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  String _titleFor(ReminderType t) {
    switch (t) {
      case ReminderType.periodSoon:
        return 'Your period is coming up';
      case ReminderType.logToday:
        return 'Log today';
      case ReminderType.pill:
        return 'Time for your pill';
    }
  }

  String _bodyFor(ReminderType t) {
    switch (t) {
      case ReminderType.periodSoon:
        return 'Based on your last cycles, your next period is on the way.';
      case ReminderType.logToday:
        return 'Quick tap — flow, mood, symptoms.';
      case ReminderType.pill:
        return 'Daily reminder.';
    }
  }
}
