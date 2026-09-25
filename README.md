# Timbre

**A calm, offline-first music player for Android** — your local library
presented as a broadcast radio station you own. No account, no streaming,
no tracking.

Tune the dial (Archive / Flow / Favorites), save memory presets, follow the
program guide, and browse the full archive (songs, albums, artists, genres,
folders) with search. Available in **English and Arabic (RTL)**.

## Install

No Play Store release — Timbre is distributed as a signed release APK
through GitHub Releases, and the app updates itself in place:

1. Download the latest `timbre-v*-arm64.apk` from
   [Releases](../../releases).
2. Open it on your phone and allow *Install unknown apps* for your browser
   / file manager when asked.
3. Later updates arrive inside the app: **Settings → Updates →
   Check for updates → Download & Install**.

## Features

- Offline playback of the on-device library (MediaStore scan)
- Broadcast-radio UI: tuner dial, presets, program guide, "on air" receiver
- Smart Flow queues from listening history + favorites
- Playlists, favorites, continue-listening, recently played, global search
- Swipe actions (share / delete) and long-press bulk selection
- Real audio-file sharing; safe on-device delete via Android consent flow
- Sleep timer, playback speed, background + lock-screen controls
- In-app language switcher (System / English / Arabic)

## Tech stack

Flutter (Dart) · `audio_service` + `just_audio` · `on_audio_query`
(MediaStore) · `sqflite` + `shared_preferences` · `provider` ·
Material 3 · small Kotlin bridge (MediaStore delete) · `ota_update`
(self-updates from GitHub Releases)

## Build from source

```bash
flutter analyze
flutter test
flutter build apk --release --target-platform android-arm64
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`.

> [!IMPORTANT]
> `audio_service` 0.18.x ships an empty Android manifest, so the
> foreground-service permissions in
> `android/app/src/main/AndroidManifest.xml` (`WAKE_LOCK`,
> `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`,
> `POST_NOTIFICATIONS`) are load-bearing — removing them reintroduces a
> launch-crash ANR on Android 14+. They are guarded by
> `test/manifest_test.dart`; keep that test green.

## Releasing a new version

1. Bump `version:` in `pubspec.yaml` (`x.y.z+N`).
2. Build the release APK, rename it with the tag and ABI, e.g.
   `timbre-v1.0.2-arm64.apk`, and take its SHA-256.
3. Create the GitHub release with that tag and attach the APK. Put a
   `sha256: <hex>` line in the release notes — the in-app updater
   verifies the download against it before installing.

```bash
flutter build apk --release --target-platform android-arm64
cp build/app/outputs/flutter-apk/app-release.apk \
   build/app/outputs/flutter-apk/timbre-v1.0.2-arm64.apk
gh release create v1.0.2 build/app/outputs/flutter-apk/timbre-v1.0.2-arm64.apk \
  --title "v1.0.2" --notes "Highlights… sha256: <hex>"
```

The updater only offers releases carrying an `.apk` asset whose tag is
newer than the installed version.

## Project docs

- `handoff.md` — maintainer briefing: device rules, history, recipes
- `AGENTS.md` — hard rules for AI assistants working in this repo
- `PORTFOLIO.md` — copy-paste brief for portfolio sites
