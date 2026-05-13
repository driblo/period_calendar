import 'package:drift/drift.dart';

import '../db/app_database.dart';

class CycleRepository {
  CycleRepository(this._db);

  final AppDatabase _db;

  Future<int> startCycle(DateTime startDate, {String? notes}) {
    final d = _normalize(startDate);
    return _db.cycleDao.insertCycle(
      CyclesCompanion.insert(
        startDate: d,
        notes: Value(notes),
      ),
    );
  }

  Future<bool> endCurrentCycle(DateTime endDate) async {
    final latest = await _db.cycleDao.latest();
    if (latest == null || latest.endDate != null) return false;
    return _db.cycleDao.updateCycle(
      latest.copyWith(endDate: Value(_normalize(endDate))),
    );
  }

  Future<List<Cycle>> all() => _db.cycleDao.getAll();

  Stream<List<Cycle>> watchAll() => _db.cycleDao.watchAll();

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}
