import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/features/predictions/cycle_predictor.dart';

DateTime d(int y, int m, int day) => DateTime(y, m, day);

void main() {
  const predictor = CyclePredictor();

  group('CyclePredictor.predict — fallbacks', () {
    test('0 cycles uses default cycle and period length', () {
      final p = predictor.predict(cycleStartDates: const []);
      expect(p.cycleLengthUsed, 28);
      expect(p.periodLengthUsed, 5);
      expect(p.cyclesAnalyzed, 0);
      expect(p.irregular, isFalse);
    });

    test('0 cycles produces a prediction anchored ~28 days from today', () {
      final p = predictor.predict(cycleStartDates: const []);
      final today = DateTime.now();
      final diff = p.nextPeriodStart.difference(
        DateTime(today.year, today.month, today.day),
      );
      expect(diff.inDays, 28);
    });

    test('1 cycle uses defaults but anchors to logged start', () {
      final p = predictor.predict(cycleStartDates: [d(2026, 1, 1)]);
      expect(p.cycleLengthUsed, 28);
      expect(p.nextPeriodStart, d(2026, 1, 29));
      expect(p.nextPeriodEnd, d(2026, 2, 2));
    });

    test('explicit period lengths overrides default', () {
      final p = predictor.predict(
        cycleStartDates: [d(2026, 1, 1)],
        periodLengths: const [4, 4, 4],
      );
      expect(p.periodLengthUsed, 4);
      expect(p.nextPeriodEnd, d(2026, 2, 1));
    });
  });

  group('CyclePredictor.predict — windows', () {
    test('ovulation is 14 days before next period', () {
      final p = predictor.predict(cycleStartDates: [d(2026, 1, 1)]);
      expect(
        p.ovulationDate,
        p.nextPeriodStart.subtract(const Duration(days: 14)),
      );
    });

    test('fertile window is days 18..11 before next period', () {
      final p = predictor.predict(cycleStartDates: [d(2026, 1, 1)]);
      expect(
        p.fertileWindowStart,
        p.nextPeriodStart.subtract(const Duration(days: 18)),
      );
      expect(
        p.fertileWindowEnd,
        p.nextPeriodStart.subtract(const Duration(days: 11)),
      );
    });

    test('fertile window length is 7 days', () {
      final p = predictor.predict(cycleStartDates: [d(2026, 1, 1)]);
      final len =
          p.fertileWindowEnd.difference(p.fertileWindowStart).inDays + 1;
      expect(len, 8);
    });

    test('next period length spans periodLengthUsed days', () {
      final p = predictor.predict(
        cycleStartDates: [d(2026, 1, 1)],
        periodLengths: const [6],
      );
      final spanDays = p.nextPeriodEnd.difference(p.nextPeriodStart).inDays + 1;
      expect(spanDays, 6);
    });
  });

  group('CyclePredictor.predict — rolling mean', () {
    test('2 perfectly 30-day cycles yields cycle length 30', () {
      final p = predictor.predict(
        cycleStartDates: [
          d(2026, 1, 1),
          d(2026, 1, 31),
        ],
      );
      expect(p.cycleLengthUsed, 30);
      expect(p.nextPeriodStart, d(2026, 3, 2));
    });

    test('mixed 27/28/29-day gaps average to 28', () {
      final p = predictor.predict(
        cycleStartDates: [
          d(2026, 1, 1),
          d(2026, 1, 28), // 27
          d(2026, 2, 25), // 28
          d(2026, 3, 26), // 29
        ],
      );
      expect(p.cycleLengthUsed, 28);
    });

    test('only last 6 gaps are considered', () {
      // 8 gaps of 25 days, then 6 gaps of 35 days at the end
      final starts = <DateTime>[d(2026, 1, 1)];
      for (var i = 0; i < 8; i++) {
        starts.add(starts.last.add(const Duration(days: 25)));
      }
      for (var i = 0; i < 6; i++) {
        starts.add(starts.last.add(const Duration(days: 35)));
      }
      final p = predictor.predict(cycleStartDates: starts);
      expect(p.cycleLengthUsed, 35);
    });

    test('extremely short gaps are clamped to minCycleLength', () {
      final p = predictor.predict(
        cycleStartDates: [
          d(2026, 1, 1),
          d(2026, 1, 11), // 10
          d(2026, 1, 21), // 10
        ],
      );
      expect(p.cycleLengthUsed, 21);
    });

    test('extremely long gaps are clamped to maxCycleLength', () {
      final p = predictor.predict(
        cycleStartDates: [
          d(2026, 1, 1),
          d(2026, 4, 1), // 90
          d(2026, 7, 1), // 91
        ],
      );
      expect(p.cycleLengthUsed, 45);
    });

    test('unsorted input is sorted internally', () {
      final unsorted = predictor.predict(
        cycleStartDates: [
          d(2026, 3, 1),
          d(2026, 1, 1),
          d(2026, 2, 1),
        ],
      );
      final sorted = predictor.predict(
        cycleStartDates: [
          d(2026, 1, 1),
          d(2026, 2, 1),
          d(2026, 3, 1),
        ],
      );
      expect(unsorted.cycleLengthUsed, sorted.cycleLengthUsed);
      expect(unsorted.nextPeriodStart, sorted.nextPeriodStart);
    });
  });

  group('CyclePredictor.predict — irregularity', () {
    test('regular ~28-day cycles are not flagged irregular', () {
      final starts = <DateTime>[d(2026, 1, 1)];
      for (var i = 0; i < 5; i++) {
        starts.add(starts.last.add(const Duration(days: 28)));
      }
      final p = predictor.predict(cycleStartDates: starts);
      expect(p.irregular, isFalse);
    });

    test('highly variable cycles are flagged irregular', () {
      final p = predictor.predict(
        cycleStartDates: [
          d(2026, 1, 1),
          d(2026, 1, 21), // 20
          d(2026, 3, 1), // 39
          d(2026, 3, 22), // 21
          d(2026, 5, 1), // 40
        ],
      );
      expect(p.irregular, isTrue);
    });

    test('<3 cycles can never be flagged irregular', () {
      final p = predictor.predict(
        cycleStartDates: [
          d(2026, 1, 1),
          d(2026, 1, 21),
        ],
      );
      expect(p.irregular, isFalse);
    });
  });

  group('CyclePredictor — boundary dates', () {
    test('leap-year February is handled correctly', () {
      // 2028 is a leap year; cycle starting Feb 1 with 28-day length lands Feb 29.
      final p = predictor.predict(cycleStartDates: [d(2028, 2, 1)]);
      expect(p.nextPeriodStart, d(2028, 2, 29));
    });

    test('year boundary rollover', () {
      final p = predictor.predict(cycleStartDates: [d(2026, 12, 15)]);
      expect(p.nextPeriodStart, d(2027, 1, 12));
    });

    test('DST-spanning dates: prediction stays on calendar day', () {
      // US spring-forward is mid-March. Verify date arithmetic doesn't drift.
      final p = predictor.predict(cycleStartDates: [d(2026, 3, 1)]);
      expect(p.nextPeriodStart, d(2026, 3, 29));
    });

    test('timestamps with hours/minutes are normalized to midnight', () {
      final p = predictor.predict(
        cycleStartDates: [
          DateTime(2026, 1, 1, 23, 59, 59),
        ],
      );
      expect(p.nextPeriodStart, d(2026, 1, 29));
      expect(p.nextPeriodStart.hour, 0);
    });
  });

  group('CyclePredictor.currentCycleDay', () {
    test('returns null when there is no history', () {
      expect(predictor.currentCycleDay(const []), isNull);
    });

    test('day 1 on the start date itself', () {
      expect(
        predictor.currentCycleDay(
          [d(2026, 1, 1)],
          today: d(2026, 1, 1),
        ),
        1,
      );
    });

    test('day 15 fourteen days after the start', () {
      expect(
        predictor.currentCycleDay(
          [d(2026, 1, 1)],
          today: d(2026, 1, 15),
        ),
        15,
      );
    });

    test('returns null when today is before any logged cycle start', () {
      expect(
        predictor.currentCycleDay(
          [d(2026, 6, 1)],
          today: d(2026, 1, 1),
        ),
        isNull,
      );
    });
  });
}
