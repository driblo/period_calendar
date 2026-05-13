# Period Calendar

A warm, private period & cycle calendar for Android and iOS, built with
Flutter and Material 3.

## Highlights

- **Local-only.** All data lives on-device in a SQLCipher-encrypted SQLite
  database. No accounts, no backend, no analytics, no third-party SDKs.
- **App lock.** PIN (PBKDF2-HMAC-SHA256) plus biometric (Face / Touch ID /
  Android biometric). Auto-locks 30 s after backgrounding; UI is masked
  while the app is inactive.
- **Predictions.** Pure-Dart cycle predictor: rolling mean of the last 6
  cycles, fertile window, ovulation, current cycle day, irregularity flag.
- **Reminders.** Local notifications for upcoming period, daily log nudge,
  and an optional pill reminder.
- **Insights.** At-a-glance stats and a 6-cycle bar chart (`fl_chart`).
- **Data control.** Export everything to JSON or wipe the device data with
  a double-confirm.

## Stack

Flutter 3.27 · Dart 3.6 · Riverpod · go_router-ready scaffold · Drift +
SQLCipher · `flutter_local_notifications` · `local_auth` · `fl_chart` ·
`table_calendar`.

## Development

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
flutter run
```

Android requires `minSdk` 23 and Java 17. iOS deployment target is 13.0.

## Layout

```
lib/
  app.dart                 # MaterialApp + onboarding/lock/privacy gates
  main.dart                # bootstrap, DB key, ProviderScope overrides
  core/                    # theme, reusable widgets
  data/
    db/                    # Drift schema, DAOs, encrypted open
    repositories/          # higher-level data access
    providers.dart         # Riverpod providers
  features/
    calendar/              # month view + day-detail sheet
    predictions/           # pure-Dart cycle predictor
    insights/              # stats + bar chart
    reminders/             # scheduling logic + plugin wrapper
    security/              # PIN, biometric, lock gate, export, wipe
    settings/              # settings menu
    shell/                 # bottom-nav scaffold
    onboarding/            # first-run flow
```

## Privacy

This app does not transmit your data. Period data, daily logs, symptoms,
reminders, and your PIN hash never leave your device. There is no
analytics, telemetry, or third-party network call.

If you delete the app, the local DB and PIN go with it. Use **Settings →
Privacy & security → Delete all data** to wipe explicitly.
