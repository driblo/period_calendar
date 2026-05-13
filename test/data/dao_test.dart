import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import 'package:period_calendar/data/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.memory());
  tearDown(() => db.close());

  test('CycleDao insert + latest + watch', () async {
    await db.cycleDao.insertCycle(
      CyclesCompanion.insert(startDate: DateTime(2026, 1, 1)),
    );
    await db.cycleDao.insertCycle(
      CyclesCompanion.insert(startDate: DateTime(2026, 2, 1)),
    );

    final latest = await db.cycleDao.latest();
    expect(latest, isNotNull);
    expect(latest!.startDate, DateTime(2026, 2, 1));

    final all = await db.cycleDao.getAll();
    expect(all, hasLength(2));
  });

  test('DailyLogDao upsert replaces by date', () async {
    final date = DateTime(2026, 3, 5);
    await db.dailyLogDao.upsert(
      DailyLogsCompanion.insert(date: date, mood: const Value(3)),
    );
    await db.dailyLogDao.upsert(
      DailyLogsCompanion.insert(date: date, mood: const Value(5)),
    );

    final log = await db.dailyLogDao.getByDate(date);
    expect(log, isNotNull);
    expect(log!.mood, 5);
  });

  test('SettingsDao get/put/remove', () async {
    expect(await db.settingsDao.get('cycle.length'), isNull);
    await db.settingsDao.put('cycle.length', '28');
    expect(await db.settingsDao.get('cycle.length'), '28');
    await db.settingsDao.put('cycle.length', '30');
    expect(await db.settingsDao.get('cycle.length'), '30');
    await db.settingsDao.remove('cycle.length');
    expect(await db.settingsDao.get('cycle.length'), isNull);
  });

  test('RemindersDao upsert + delete', () async {
    final id = await db.remindersDao.upsert(
      RemindersCompanion.insert(
        type: 'periodSoon',
        hour: 9,
        minute: 0,
        daysBefore: const Value(2),
      ),
    );
    expect(await db.remindersDao.getAll(), hasLength(1));
    await db.remindersDao.deleteReminder(id);
    expect(await db.remindersDao.getAll(), isEmpty);
  });

  test('Symptom cascades on daily log delete', () async {
    final date = DateTime(2026, 4, 1);
    await db.dailyLogDao.upsert(
      DailyLogsCompanion.insert(date: date, flow: const Value(2)),
    );
    final log = await db.dailyLogDao.getByDate(date);
    await db.dailyLogDao.addSymptom(
      SymptomsCompanion.insert(dailyLogId: log!.id, type: 'cramps'),
    );
    expect(await db.dailyLogDao.getSymptoms(log.id), hasLength(1));
    await (db.delete(db.dailyLogs)..where((t) => t.id.equals(log.id))).go();
    expect(await db.dailyLogDao.getSymptoms(log.id), isEmpty);
  });
}
