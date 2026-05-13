import '../../data/db/app_database.dart';

class CycleStats {
  const CycleStats({
    required this.cyclesCount,
    required this.cycleLengths,
    required this.periodLengths,
    required this.avgCycleLength,
    required this.avgPeriodLength,
    required this.shortestCycle,
    required this.longestCycle,
  });

  final int cyclesCount;
  final List<int> cycleLengths;
  final List<int> periodLengths;
  final double? avgCycleLength;
  final double? avgPeriodLength;
  final int? shortestCycle;
  final int? longestCycle;

  bool get hasData => cyclesCount >= 2;
}

/// Pure-Dart aggregation. No I/O.
class CycleStatsCalculator {
  const CycleStatsCalculator();

  CycleStats compute(List<Cycle> cycles) {
    final sorted = [...cycles]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final gaps = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      gaps.add(
        sorted[i].startDate.difference(sorted[i - 1].startDate).inDays,
      );
    }

    final periods = <int>[];
    for (final c in sorted) {
      if (c.endDate != null) {
        periods.add(c.endDate!.difference(c.startDate).inDays + 1);
      }
    }

    double? mean(List<int> xs) =>
        xs.isEmpty ? null : xs.reduce((a, b) => a + b) / xs.length;

    return CycleStats(
      cyclesCount: sorted.length,
      cycleLengths: gaps,
      periodLengths: periods,
      avgCycleLength: mean(gaps),
      avgPeriodLength: mean(periods),
      shortestCycle: gaps.isEmpty ? null : gaps.reduce((a, b) => a < b ? a : b),
      longestCycle: gaps.isEmpty ? null : gaps.reduce((a, b) => a > b ? a : b),
    );
  }
}
