# Security

## Data and privacy
- The app is fully offline. It makes no network requests and has no backend, analytics, or accounts.
- Workouts, history, and settings are stored only on the device via `shared_preferences` (app-private storage). Uninstalling the app deletes them.
- No personal data is collected beyond workout names you type yourself.
- Voice cues use the phone's own text-to-speech engine. Some engines may offer online voices; the app itself sends nothing.

## Third-party content
- The exercise catalog and photos (`assets/exercises/`) come from free-exercise-db and are public domain (Unlicense). They are bundled in the app, so the library works offline and loads nothing from the internet.
- Exercise instructions are general guidance, not medical advice; the app says so on the "How to do it" screen.

## Permissions
| Permission | Why |
|---|---|
| `VIBRATE` | Vibrate on phase changes |
| `WAKE_LOCK` | Keep the screen on and the CPU awake during a workout |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_SPECIAL_USE` | Keep the timer running with the screen locked |
| `POST_NOTIFICATIONS` | Show the "workout in progress" notification (asked at runtime on Android 13+) |
| `<queries>` TTS_SERVICE | Find the phone's text-to-speech engine (not a permission prompt) |

The app does **not** request `INTERNET`, location, contacts, storage, microphone, or camera. Flutter debug builds add `INTERNET` automatically for hot reload; release builds only include what the manifest lists.

## Background service hardening
- `WorkoutService` is declared `android:exported="false"`: other apps can't start, stop, or bind to it.
- Notification buttons use explicit, `FLAG_IMMUTABLE` pending intents that target the app's own service, so they can't be redirected or modified.
- The CPU wake lock is held only while a workout runs, with a 4-hour safety cap so a bug can't drain the battery indefinitely. It is released when the workout ends, is stopped, or the app is swiped away.
- The notification shows the phase and exercise name and is visible on the lock screen (`VISIBILITY_PUBLIC`). Avoid putting anything private in workout names.
- `specialUse` is the declared foreground-service type. Publishing on Google Play requires justifying it in the Play Console (an interval timer that must keep running with the screen locked).

## Audio
- `Speaker.kt` requests **transient** audio focus with ducking (`AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK`) only while speaking, and releases it shortly after. It never takes permanent focus, so it can't stop other apps' playback.

## Dependencies
Third-party packages (from pub.dev): `shared_preferences`, `wakelock_plus`, `vibration`. Text-to-speech and the foreground service are native Kotlin code in this repository, not plugins.
- Check for updates with `flutter pub outdated`, and review changelogs before major upgrades.
- `pubspec.lock` is committed so builds are reproducible.

## Repository hygiene
- Never commit signing material or secrets: `key.properties`, `*.jks`, `*.keystore`, `local.properties`. These are in `.gitignore`.
- Build output (`build/`, `.dart_tool/`) is not committed.

## Release signing
Before publishing to the Play Store, create your own upload keystore and keep it, with its passwords, outside the repository.

## Reporting
Found a security problem? Please open a private security advisory on the GitHub repository (Security → Report a vulnerability) instead of a public issue.
