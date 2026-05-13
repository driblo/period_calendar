import 'package:drift/drift.dart';

import '../db/app_database.dart';

class DailyLogRepository {
  DailyLogRepository(this._db);

  final AppDatabase _db;

  Future<DailyLog?> forDate(DateTime day) => _db.dailyLogDao.getByDate(day);

  Stream<List<DailyLog>> watchRange(DateTime from, DateTime to) =>
      _db.dailyLogDao.watchRange(from, to);

  Future<int> saveLog({
    required DateTime date,
    int? mood,
    int? energy,
    int? flow,
    String? notes,
  }) {
    final normalized = DateTime(date.year, date.month, date.day);
    return _db.dailyLogDao.upsert(
      DailyLogsCompanion.insert(
        date: normalized,
        mood: Value(mood),
        energy: Value(energy),
        flow: Value(flow),
        notes: Value(notes),
      ),
    );
  }

  Future<void> setSymptoms(int dailyLogId, List<String> types) async {
    await _db.dailyLogDao.clearSymptoms(dailyLogId);
    for (final t in types) {
      await _db.dailyLogDao.addSymptom(
        SymptomsCompanion.insert(dailyLogId: dailyLogId, type: t),
      );
    }
  }

  Future<List<Symptom>> symptomsFor(int dailyLogId) =>
      _db.dailyLogDao.getSymptoms(dailyLogId);
}
