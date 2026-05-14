import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import 'daos/cycle_dao.dart';
import 'daos/daily_log_dao.dart';
import 'daos/reminders_dao.dart';
import 'daos/settings_dao.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Cycles, DailyLogs, Symptoms, AppSettings, Reminders],
  daos: [CycleDao, DailyLogDao, SettingsDao, RemindersDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory test constructor; no encryption.
  AppDatabase.memory() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Opens the encrypted on-device DB using [encryptionKey].
Future<AppDatabase> openEncryptedDatabase(String encryptionKey) async {
  final dir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(dir.path, 'period_calendar.db'));

  // Override in the main isolate for any non-background sqlite3 use.
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  open.overrideFor(OperatingSystem.iOS, () => DynamicLibrary.process());

  final executor = NativeDatabase.createInBackground(
    dbFile,
    // Re-apply the override inside the background isolate — it doesn't
    // inherit the main-isolate override and would otherwise try libsqlite3.so.
    isolateSetup: _sqlCipherIsolateSetup,
    setup: (db) {
      db.execute("PRAGMA key = '${_escape(encryptionKey)}';");
      db.execute('PRAGMA cipher_compatibility = 4;');
    },
  );
  return AppDatabase(executor);
}

Future<void> _sqlCipherIsolateSetup() async {
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  open.overrideFor(OperatingSystem.iOS, () => DynamicLibrary.process());
}

String _escape(String s) => s.replaceAll("'", "''");
