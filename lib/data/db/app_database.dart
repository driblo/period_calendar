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
///
/// The key is supplied via [SqlCipherKeyProvider] — typically read from
/// secure storage and generated on first launch.
Future<AppDatabase> openEncryptedDatabase(String encryptionKey) async {
  final dir = await getApplicationDocumentsDirectory();
  final dbFile = File(p.join(dir.path, 'period_calendar.db'));

  // Ensure SQLCipher native libs are loaded before any sqlite3 use.
  await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
  open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  open.overrideFor(OperatingSystem.iOS, () => DynamicLibrary.process());

  final executor = NativeDatabase.createInBackground(
    dbFile,
    setup: (db) {
      // Apply the key BEFORE any other statement.
      db.execute("PRAGMA key = '${_escape(encryptionKey)}';");
      // Sanity check: confirm the DB is readable with the key.
      db.execute('PRAGMA cipher_compatibility = 4;');
    },
  );
  return AppDatabase(executor);
}

String _escape(String s) => s.replaceAll("'", "''");
