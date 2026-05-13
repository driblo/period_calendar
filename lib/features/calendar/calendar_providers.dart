import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../predictions/cycle_predictor.dart';

const _predictor = CyclePredictor();

/// All cycles, watched as a stream.
final cyclesProvider = StreamProvider<List<Cycle>>(
  (ref) => ref.watch(cycleRepositoryProvider).watchAll(),
);

/// Current prediction derived from the latest cycle list.
final cyclePredictionProvider = Provider<CyclePrediction>((ref) {
  final cycles = ref.watch(cyclesProvider).valueOrNull ?? const <Cycle>[];
  final starts = cycles.map((c) => c.startDate).toList();
  final lengths = <int>[];
  for (final c in cycles) {
    if (c.endDate != null) {
      lengths.add(c.endDate!.difference(c.startDate).inDays + 1);
    }
  }
  return _predictor.predict(
    cycleStartDates: starts,
    periodLengths: lengths.isEmpty ? null : lengths,
  );
});
