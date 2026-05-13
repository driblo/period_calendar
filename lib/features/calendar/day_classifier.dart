import '../../data/db/app_database.dart';
import '../predictions/cycle_predictor.dart';

enum DayKind {
  none,
  period,
  predictedPeriod,
  fertile,
  ovulation,
  logged,
}

/// Pure-Dart helper: given cycles + a prediction, classify each calendar day.
class DayClassifier {
  DayClassifier({
    required this.cycles,
    required this.prediction,
    required this.loggedDates,
    this.assumedPeriodLength = 5,
  });

  final List<Cycle> cycles;
  final CyclePrediction prediction;
  final Set<DateTime> loggedDates;
  final int assumedPeriodLength;

  DayKind classify(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);

    for (final c in cycles) {
      final start =
          DateTime(c.startDate.year, c.startDate.month, c.startDate.day);
      final end = c.endDate != null
          ? DateTime(c.endDate!.year, c.endDate!.month, c.endDate!.day)
          : start.add(Duration(days: assumedPeriodLength - 1));
      if (!d.isBefore(start) && !d.isAfter(end)) return DayKind.period;
    }

    if (!d.isBefore(prediction.nextPeriodStart) &&
        !d.isAfter(prediction.nextPeriodEnd)) {
      return DayKind.predictedPeriod;
    }
    if (_sameDay(d, prediction.ovulationDate)) return DayKind.ovulation;
    if (!d.isBefore(prediction.fertileWindowStart) &&
        !d.isAfter(prediction.fertileWindowEnd)) {
      return DayKind.fertile;
    }

    if (loggedDates.contains(d)) return DayKind.logged;

    return DayKind.none;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
