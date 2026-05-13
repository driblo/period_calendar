import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'reminders_dao.g.dart';

@DriftAccessor(tables: [Reminders])
class RemindersDao extends DatabaseAccessor<AppDatabase>
    with _$RemindersDaoMixin {
  RemindersDao(super.db);

  Future<List<Reminder>> getAll() => select(reminders).get();

  Stream<List<Reminder>> watchAll() => select(reminders).watch();

  Future<int> upsert(RemindersCompanion entry) =>
      into(reminders).insertOnConflictUpdate(entry);

  Future<int> deleteReminder(int id) =>
      (delete(reminders)..where((r) => r.id.equals(id))).go();
}
