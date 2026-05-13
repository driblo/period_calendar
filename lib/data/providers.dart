import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'repositories/cycle_repository.dart';
import 'repositories/daily_log_repository.dart';

/// Overridden in [main] with the real encrypted database.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('appDatabaseProvider must be overridden'),
);

final cycleRepositoryProvider = Provider<CycleRepository>(
  (ref) => CycleRepository(ref.watch(appDatabaseProvider)),
);

final dailyLogRepositoryProvider = Provider<DailyLogRepository>(
  (ref) => DailyLogRepository(ref.watch(appDatabaseProvider)),
);

final cyclesStreamProvider = StreamProvider(
  (ref) => ref.watch(cycleRepositoryProvider).watchAll(),
);
