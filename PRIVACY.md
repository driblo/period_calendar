# Privacy Policy — Period Calendar

_Last updated: 2026-05-13_

Period Calendar is a single-purpose, local-only cycle tracker. Your data
stays on your device.

## What we collect

**Nothing.** The app does not contain analytics SDKs, crash reporting
SDKs, advertising SDKs, or any third-party service that transmits data.
There is no account system.

## What is stored on your device

- Period start/end dates you log
- Daily logs (mood, energy, flow, notes)
- Symptoms you tag against any day
- Reminder configuration
- Your app-lock PIN, stored as a salted PBKDF2-HMAC-SHA256 hash in the
  platform keychain / keystore
- The encryption key for the local database, also stored in the
  keychain / keystore

The local database is encrypted at rest using SQLCipher.

## Network access

The app does not make outbound network requests.

## Sharing

We do not share, sell, or transmit your data because the app does not
receive your data in the first place.

## Your controls

- **Settings → Privacy & security → Export data**: copies a JSON dump of
  your data to the clipboard for personal backup.
- **Settings → Privacy & security → Delete all data**: irreversibly
  wipes the local database, your PIN, and your biometric preference.
- Uninstalling the app removes all stored data from your device.

## Contact

This is a personal project. For questions, open an issue on the project's
GitHub repository.
