import 'package:drift/drift.dart';

class Cycles extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}

class DailyLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime().unique()();
  IntColumn get mood => integer().nullable()(); // 1..5
  IntColumn get energy => integer().nullable()(); // 1..5
  IntColumn get flow => integer().nullable()(); // 0..4 (none..heavy)
  TextColumn get notes => text().nullable()();
}

class Symptoms extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dailyLogId =>
      integer().references(DailyLogs, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // e.g. cramps, headache, acne
  IntColumn get severity => integer().withDefault(const Constant(1))();
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // periodSoon, logToday, pill
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  IntColumn get daysBefore => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
}
