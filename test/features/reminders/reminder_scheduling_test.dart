import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/features/predictions/cycle_predictor.dart';
import 'package:period_calendar/features/reminders/reminder_models.dart';
import 'package:period_calendar/features/reminders/reminder_scheduling.dart';

CyclePrediction _futurePrediction() => const CyclePredictor().predict(
      cycleStartDates: [DateTime(2099, 1, 1)],
    );

void main() {
  const s = ReminderScheduling();

  test('disabled reminder returns null', () {
    final spec = ReminderSpec(
      type: ReminderType.logToday,
      hour: 9,
      minute: 0,
      enabled: false,
    );
    final fire = s.nextFire(
      spec: spec,
      prediction: _futurePrediction(),
      now: DateTime(2026, 5, 1, 8),
    );
    expect(fire, isNull);
  });

  test('logToday fires today when time is in the future', () {
    const spec = ReminderSpec(
      type: ReminderType.logToday,
      hour: 20,
      minute: 30,
    );
    final fire = s.nextFire(
      spec: spec,
      prediction: _futurePrediction(),
      now: DateTime(2026, 5, 1, 10),
    );
    expect(fire, DateTime(2026, 5, 1, 20, 30));
  });

  test('logToday fires tomorrow when time has passed', () {
    const spec = ReminderSpec(
      type: ReminderType.logToday,
      hour: 7,
      minute: 0,
    );
    final fire = s.nextFire(
      spec: spec,
      prediction: _futurePrediction(),
      now: DateTime(2026, 5, 1, 10),
    );
    expect(fire, DateTime(2026, 5, 2, 7, 0));
  });

  test('periodSoon fires N days before next period at requested time', () {
    final prediction = const CyclePredictor().predict(
      cycleStartDates: [DateTime(2026, 5, 1)],
    );
    // next period is May 29; daysBefore=2 -> May 27 at 09:00.
    const spec = ReminderSpec(
      type: ReminderType.periodSoon,
      hour: 9,
      minute: 0,
      daysBefore: 2,
    );
    final fire = s.nextFire(
      spec: spec,
      prediction: prediction,
      now: DateTime(2026, 5, 10),
    );
    expect(fire, DateTime(2026, 5, 27, 9, 0));
  });

  test('periodSoon returns null when the target is in the past', () {
    final prediction = const CyclePredictor().predict(
      cycleStartDates: [DateTime(2020, 1, 1)],
    );
    const spec = ReminderSpec(
      type: ReminderType.periodSoon,
      hour: 9,
      minute: 0,
      daysBefore: 2,
    );
    final fire = s.nextFire(
      spec: spec,
      prediction: prediction,
      now: DateTime(2026, 5, 1),
    );
    expect(fire, isNull);
  });
}
