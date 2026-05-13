import 'dart:math' as math;

class CyclePrediction {
  const CyclePrediction({
    required this.nextPeriodStart,
    required this.nextPeriodEnd,
    required this.fertileWindowStart,
    required this.fertileWindowEnd,
    required this.ovulationDate,
    required this.cycleLengthUsed,
    required this.periodLengthUsed,
    required this.cyclesAnalyzed,
    required this.irregular,
  });

  final DateTime nextPeriodStart;
  final DateTime nextPeriodEnd;
  final DateTime fertileWindowStart;
  final DateTime fertileWindowEnd;
  final DateTime ovulationDate;
  final int cycleLengthUsed;
  final int periodLengthUsed;
  final int cyclesAnalyzed;
  final bool irregular;
}

/// Pure-Dart cycle prediction. No I/O. Deterministic from inputs.
///
/// - With 0 cycles logged, falls back to [defaultCycleLength] /
///   [defaultPeriodLength].
/// - With 1 cycle logged, uses defaults but anchors to the logged start.
/// - With >=2 cycles, uses the rolling mean of the last [historyWindow] gaps.
/// - Marks [CyclePrediction.irregular] when standard deviation of the gaps
///   is greater than [irregularityThresholdDays].
class CyclePredictor {
  const CyclePredictor({
    this.defaultCycleLength = 28,
    this.defaultPeriodLength = 5,
    this.historyWindow = 6,
    this.irregularityThresholdDays = 7,
    this.minCycleLength = 21,
    this.maxCycleLength = 45,
  });

  final int defaultCycleLength;
  final int defaultPeriodLength;
  final int historyWindow;
  final int irregularityThresholdDays;
  final int minCycleLength;
  final int maxCycleLength;

  CyclePrediction predict({
    required List<DateTime> cycleStartDates,
    List<int>? periodLengths,
  }) {
    final sorted = [...cycleStartDates.map(_atMidnight)]..sort();

    final cycleLength = _estimateCycleLength(sorted);
    final periodLength = _estimatePeriodLength(periodLengths);
    final anchor = sorted.isEmpty ? _atMidnight(DateTime.now()) : sorted.last;

    final nextStart = anchor.add(Duration(days: cycleLength));
    final nextEnd = nextStart.add(Duration(days: periodLength - 1));
    final ovulation = nextStart.subtract(const Duration(days: 14));
    final fertileStart = nextStart.subtract(const Duration(days: 18));
    final fertileEnd = nextStart.subtract(const Duration(days: 11));

    return CyclePrediction(
      nextPeriodStart: nextStart,
      nextPeriodEnd: nextEnd,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
      ovulationDate: ovulation,
      cycleLengthUsed: cycleLength,
      periodLengthUsed: periodLength,
      cyclesAnalyzed: sorted.length,
      irregular: _isIrregular(sorted),
    );
  }

  /// Days elapsed since the last cycle start (inclusive of today),
  /// or `null` if there is no cycle history.
  int? currentCycleDay(List<DateTime> cycleStartDates, {DateTime? today}) {
    if (cycleStartDates.isEmpty) return null;
    final sorted = [...cycleStartDates.map(_atMidnight)]..sort();
    final ref = _atMidnight(today ?? DateTime.now());
    final diff = ref.difference(sorted.last).inDays + 1;
    return diff < 1 ? null : diff;
  }

  int _estimateCycleLength(List<DateTime> sorted) {
    if (sorted.length < 2) return defaultCycleLength;
    final gaps = _gapsInDays(sorted);
    final window = gaps.length > historyWindow
        ? gaps.sublist(gaps.length - historyWindow)
        : gaps;
    final mean = window.reduce((a, b) => a + b) / window.length;
    return mean.round().clamp(minCycleLength, maxCycleLength);
  }

  int _estimatePeriodLength(List<int>? periodLengths) {
    if (periodLengths == null || periodLengths.isEmpty) {
      return defaultPeriodLength;
    }
    final mean = periodLengths.reduce((a, b) => a + b) / periodLengths.length;
    return mean.round().clamp(1, 14);
  }

  bool _isIrregular(List<DateTime> sorted) {
    if (sorted.length < 3) return false;
    final gaps = _gapsInDays(sorted);
    final window = gaps.length > historyWindow
        ? gaps.sublist(gaps.length - historyWindow)
        : gaps;
    final mean = window.reduce((a, b) => a + b) / window.length;
    final variance =
        window.map((g) => (g - mean) * (g - mean)).reduce((a, b) => a + b) /
            window.length;
    final stddev = math.sqrt(variance);
    return stddev > irregularityThresholdDays;
  }

  List<int> _gapsInDays(List<DateTime> sorted) {
    final gaps = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      gaps.add(sorted[i].difference(sorted[i - 1]).inDays);
    }
    return gaps;
  }

  DateTime _atMidnight(DateTime d) => DateTime(d.year, d.month, d.day);
}
