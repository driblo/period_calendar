import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/data/db/app_database.dart';
import 'package:period_calendar/features/insights/cycle_stats.dart';

Cycle _c(int id, DateTime s, [DateTime? e]) =>
    Cycle(id: id, startDate: s, endDate: e, notes: null);

void main() {
  const calc = CycleStatsCalculator();

  test('empty input yields no data', () {
    final s = calc.compute(const []);
    expect(s.hasData, isFalse);
    expect(s.avgCycleLength, isNull);
  });

  test('three cycles compute averages and range', () {
    final s = calc.compute([
      _c(1, DateTime(2026, 1, 1), DateTime(2026, 1, 5)),
      _c(2, DateTime(2026, 1, 29), DateTime(2026, 2, 3)),
      _c(3, DateTime(2026, 2, 26), DateTime(2026, 3, 1)),
    ]);
    expect(s.cyclesCount, 3);
    expect(s.cycleLengths, [28, 28]);
    expect(s.avgCycleLength, 28);
    expect(s.shortestCycle, 28);
    expect(s.longestCycle, 28);
    expect(s.periodLengths, [5, 6, 4]);
    expect(s.avgPeriodLength, closeTo(5.0, 0.01));
  });
}
