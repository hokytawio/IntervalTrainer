# Interval Trainer (Android)

Interval workout timer with voice cues in English or Portuguese, saved workouts, workout history, and a retro XP-inspired look. Fully offline: no server, no account, no internet.

## Features
- **Saved workouts (presets)**, e.g. "Leg day": number of exercises, sets per exercise, set time, rest time, and change-exercise time (recommended 3–5 min for full recovery).
- After the last set of an exercise, the **change time replaces the normal rest**.
- **Voice cues (EN / PT):** "Start workout", "Start rest", "Change exercise. Next: …", "30 seconds", "10 seconds", then 5‑4‑3‑2‑1 spoken and shown big on screen.
- **Plays over music:** voice cues duck YouTube / Spotify (music gets quieter while the voice speaks), like a GPS app.
- **Screen locked? Still running.** An Android foreground service keeps the timer alive, with a notification showing a big live countdown and Pause / Skip / Stop buttons.
- Pause / Resume, Skip, Stop, vibration on phase changes, keep-screen-on option.
- **History** of every workout (completed or stopped early) with time and sets done.

## Requirements
- Flutter 3.24 or newer (tested with 3.47)
- Android Studio, with these installed in **SDK Manager → SDK Tools** (tick "Show Package Details"):
  - Android SDK Command-line Tools (latest)
  - NDK (Side by side), the version the build asks for (e.g. 28.2.13676358)
- An Android phone with USB debugging on (Android 7.0+ for the big-timer notification)

## Setup
1. Clone the repository and open a terminal in the project folder.
2. Generate the missing Android platform files (keeps the existing code, manifest and Kotlin files):
   ```
   flutter create --org pt.tavio --project-name interval_trainer --platforms=android .
   ```
3. Get packages and run on a connected phone:
   ```
   flutter pub get
   flutter test
   flutter run
   ```
4. Build an installable APK:
   ```
   flutter build apk --release
   ```
   Output: `build/app/outputs/flutter-apk/app-release.apk`

## How it works
| Part | File | What it does |
|---|---|---|
| Timer engine | `lib/engine.dart` | Builds the phase timeline (prep → work → rest … → change → …) and counts down from a monotonic stopwatch, so it never drifts |
| Voice | `lib/voice.dart` → `Speaker.kt` | Native Android text-to-speech with transient audio focus + ducking |
| Background | `lib/background.dart` → `WorkoutService.kt` | Foreground service, CPU wake lock, big-timer notification with buttons |
| Bridge | `MainActivity.kt` | Method channels between Dart and Kotlin (`interval_trainer/service`, `interval_trainer/voice`) |
| Storage | `lib/storage.dart` | Presets, history and settings in `shared_preferences` |
| UI | `lib/xp/xp.dart`, `lib/screens/` | XP-inspired widgets drawn from scratch (no Microsoft assets) |

## Project layout
```
lib/
  main.dart               app entry
  models.dart             Exercise, Preset, HistoryEntry, Settings
  storage.dart            local persistence
  engine.dart             timeline builder + drift-free timer engine
  voice.dart              EN/PT voice lines, vibration, bridge to Speaker.kt
  background.dart         bridge to the foreground service
  xp/xp.dart              XP-inspired widgets
  screens/                home, editor, workout, history, settings
test/widget_test.dart     timeline tests
android/app/src/main/
  AndroidManifest.xml
  kotlin/pt/tavio/interval_trainer/
    MainActivity.kt       method channels
    WorkoutService.kt     foreground service + notification
    Speaker.kt            text-to-speech with audio ducking
  res/layout/
    notification_timer.xml       collapsed notification (big timer on the right)
    notification_timer_big.xml   expanded / lock-screen notification (very big timer)
```

## Troubleshooting
- **`flutter` not recognized:** add the Flutter `bin` folder (e.g. `C:\Users\<you>\flutter\bin`) to your user PATH and restart the editor.
- **"No Android SDK found":** install Android Studio, then `flutter config --android-sdk "%LOCALAPPDATA%\Android\Sdk"`.
- **`sdkmanager` crash / "Package ndk not found":** install the NDK version from the error manually in Android Studio → SDK Manager → SDK Tools → NDK (Side by side).
- **"compiled against android-33" from a plugin:** update it, e.g. `flutter pub add vibration`, or run `flutter pub upgrade --major-versions`. Then `flutter clean`.
- **Portuguese voice sounds English:** on the phone, Settings → Text-to-speech → install the Portuguese voice pack.
- **Timer stops with the screen locked (Xiaomi, Samsung, Huawei, OnePlus):** set the app's battery usage to **Unrestricted** and allow **Autostart**.
- **No notification on the lock screen:** Settings → Apps → Interval Trainer → Notifications → enable, including "Lock screen".
- **Kotlin package errors:** the Kotlin files expect the package `pt.tavio.interval_trainer`. If you used another `--org`, move them to the matching folder and change the `package` line at the top of each.

## Notes
- Swiping the app away from the recent apps list ends the workout.
- The UI is in English; only the voice is bilingual for now.

Security notes are in [SECURITY.md](SECURITY.md).
