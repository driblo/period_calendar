import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'cycle_dao.g.dart';

@DriftAccessor(tables: [Cycles])
class CycleDao extends DatabaseAccessor<AppDatabase> with _$CycleDaoMixin {
  CycleDao(super.db);

  Future<List<Cycle>> getAll() =>
      (select(cycles)..orderBy([(c) => OrderingTerm.asc(c.startDate)])).get();

  Stream<List<Cycle>> watchAll() =>
      (select(cycles)..orderBy([(c) => OrderingTerm.asc(c.startDate)])).watch();

  Future<Cycle?> latest() => (select(cycles)
        ..orderBy([(c) => OrderingTerm.desc(c.startDate)])
        ..limit(1))
      .getSingleOrNull();

  Future<int> insertCycle(CyclesCompanion entry) => into(cycles).insert(entry);

  Future<bool> updateCycle(Cycle entry) => update(cycles).replace(entry);

  Future<int> deleteCycle(int id) =>
      (delete(cycles)..where((c) => c.id.equals(id))).go();
}
