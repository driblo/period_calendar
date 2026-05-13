import '../predictions/cycle_predictor.dart';
import 'reminder_models.dart';

/// Pure-Dart: given a prediction and a set of reminders, compute the next
/// fire time for each. No I/O.
class ReminderScheduling {
  const ReminderScheduling();

  /// Next fire time for [spec] relative to [now].
  ///
  /// Returns `null` when the reminder is disabled or there is no upcoming
  /// trigger (e.g. period-soon for a prediction already in the past).
  DateTime? nextFire({
    required ReminderSpec spec,
    required CyclePrediction prediction,
    required DateTime now,
  }) {
    if (!spec.enabled) return null;

    switch (spec.type) {
      case ReminderType.periodSoon:
        final target = prediction.nextPeriodStart.subtract(
          Duration(days: spec.daysBefore),
        );
        final at = DateTime(
          target.year,
          target.month,
          target.day,
          spec.hour,
          spec.minute,
        );
        return at.isAfter(now) ? at : null;

      case ReminderType.logToday:
      case ReminderType.pill:
        // Fire today at hour:minute if still in the future, otherwise tomorrow.
        final today = DateTime(
          now.year,
          now.month,
          now.day,
          spec.hour,
          spec.minute,
        );
        return today.isAfter(now) ? today : today.add(const Duration(days: 1));
    }
  }
}
