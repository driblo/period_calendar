import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'daily_log_dao.g.dart';

@DriftAccessor(tables: [DailyLogs, Symptoms])
class DailyLogDao extends DatabaseAccessor<AppDatabase>
    with _$DailyLogDaoMixin {
  DailyLogDao(super.db);

  Future<DailyLog?> getByDate(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return (select(dailyLogs)..where((t) => t.date.equals(d)))
        .getSingleOrNull();
  }

  Stream<List<DailyLog>> watchRange(DateTime from, DateTime to) {
    return (select(dailyLogs)
          ..where((t) => t.date.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<int> upsert(DailyLogsCompanion entry) => into(dailyLogs).insert(
        entry,
        onConflict: DoUpdate(
          (_) => entry,
          target: [dailyLogs.date],
        ),
      );

  Future<List<Symptom>> getSymptoms(int dailyLogId) =>
      (select(symptoms)..where((s) => s.dailyLogId.equals(dailyLogId))).get();

  Future<int> addSymptom(SymptomsCompanion entry) =>
      into(symptoms).insert(entry);

  Future<int> clearSymptoms(int dailyLogId) =>
      (delete(symptoms)..where((s) => s.dailyLogId.equals(dailyLogId))).go();
}
