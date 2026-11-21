# Lt

Live speech translation for Android, Windows and macOS, built with Flutter and the OpenAI Realtime API. Each user enters their own OpenAI API key; there is no server. Transcripts and audio are stored only on the device.

## Development

Requires only the Flutter SDK (no Xcode or Android Studio).

```bash
flutter pub get
flutter run -d chrome        # day-to-day UI work
dart run build_runner watch  # regenerate Drift code after editing tables
flutter analyze && flutter test
```

Audio saving uses `dart:io` and is tested in the desktop builds, not in Chrome.

## Layout

```
lib/
  audio/       WAV writer, line ↔ playback sync
  core/        router, theme, languages
  data/        Drift database, settings, API key storage, providers
  features/    live, history, session, settings screens
web/           sqlite3.wasm + drift_worker.js for Drift in the browser
```

## Releases

Builds run on GitHub Actions, never on a local machine.

```bash
git tag v0.1.0 && git push origin v0.1.0
```

That builds the Android APK, macOS DMG and Windows ZIP and attaches them to a GitHub Release. Running the **Release** workflow manually from the Actions tab builds the same files as downloadable artifacts without publishing.

Android release signing reads these repository secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
