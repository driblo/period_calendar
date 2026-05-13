import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/data/db/app_database.dart';
import 'package:period_calendar/features/calendar/day_classifier.dart';
import 'package:period_calendar/features/predictions/cycle_predictor.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

Cycle _cycle(int id, DateTime start, [DateTime? end]) => Cycle(
      id: id,
      startDate: start,
      endDate: end,
      notes: null,
    );

void main() {
  test('classifies actual period days from a recorded cycle', () {
    final prediction = const CyclePredictor().predict(
      cycleStartDates: [d(2026, 1, 1)],
    );
    final classifier = DayClassifier(
      cycles: [_cycle(1, d(2026, 1, 1), d(2026, 1, 5))],
      prediction: prediction,
      loggedDates: const {},
    );
    expect(classifier.classify(d(2026, 1, 3)), DayKind.period);
    expect(classifier.classify(d(2026, 1, 6)), isNot(DayKind.period));
  });

  test('classifies predicted period days', () {
    final prediction = const CyclePredictor().predict(
      cycleStartDates: [d(2026, 1, 1)],
    );
    final classifier = DayClassifier(
      cycles: [_cycle(1, d(2026, 1, 1), d(2026, 1, 5))],
      prediction: prediction,
      loggedDates: const {},
    );
    expect(classifier.classify(d(2026, 1, 29)), DayKind.predictedPeriod);
  });

  test('classifies ovulation and fertile window', () {
    final prediction = const CyclePredictor().predict(
      cycleStartDates: [d(2026, 1, 1)],
    );
    final classifier = DayClassifier(
      cycles: [_cycle(1, d(2026, 1, 1), d(2026, 1, 5))],
      prediction: prediction,
      loggedDates: const {},
    );
    expect(classifier.classify(prediction.ovulationDate), DayKind.ovulation);
    expect(
      classifier.classify(prediction.fertileWindowStart),
      DayKind.fertile,
    );
  });

  test('unclassified day returns none', () {
    final prediction = const CyclePredictor().predict(
      cycleStartDates: [d(2026, 1, 1)],
    );
    final classifier = DayClassifier(
      cycles: const [],
      prediction: prediction,
      loggedDates: const {},
    );
    expect(classifier.classify(d(2025, 6, 1)), DayKind.none);
  });
}
