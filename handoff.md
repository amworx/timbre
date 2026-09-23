# handoff.md — Timbre (Flutter offline music player)

Welcome. This file is the fast-track briefing for an AI assistant (or human) taking
over this project. Read it together with `AGENTS.md` at the repo root — `AGENTS.md`
holds the hard device rules; this file holds the project context, history, and
verification recipes.

## What this project is

- **App:** Timbre — a local/offline music player for Android. Package id:
  `app.timbre.timbre`. UI metaphor: a broadcast radio receiver (tabs GUIDE /
  ARCHIVE / BANK / SCAN, "stations", "on air", Now Playing = "the receiver").
- **Stack:** Flutter (Dart SDK ^3.12.2), targetSdk 36, audio via
  `audio_service` 0.18.19 + `just_audio` 0.10.6, library via `on_audio_query`,
  persistence via `sqflite` + `shared_preferences`, state via `provider`.
  Localization: en + ar.
- **No git metadata is present** in this folder — treat the working tree as the
  single source of truth.

## Non-negotiable rules (details in AGENTS.md)

1. **NEVER launch an Android emulator / AVD / Android Studio simulator.** It
   cripples the user's laptop. Test on the physical phone only, or with
   `flutter test` / `flutter analyze` / `flutter build apk`.
2. **The physical phone is SHARED** with another AI session testing
   `com.example.video_player` (a sibling project `../video_player`). Before any
   tap, screenshot, or log read: verify the foreground app is
   `app.timbre.timbre` (`adb shell dumpsys window | grep mCurrentFocus`).
   Never force-stop/uninstall/tap the other app.
3. **Never install a debug APK on the test phone** (Galaxy A34, Mali GPU): debug
   builds render a solid red screen (Vulkan validation layer bug in the debug
   engine). It is not an app bug. Use `--release` (or `--profile`).
4. **The foreground-service permissions in `android/app/src/main/AndroidManifest.xml`
   must stay.** `audio_service` 0.18.19 ships an EMPTY manifest, so without
   WAKE_LOCK / FOREGROUND_SERVICE / FOREGROUND_SERVICE_MEDIA_PLAYBACK /
   POST_NOTIFICATIONS the app is ANR-killed on every launch (this was the
   "app keeps crashing" bug, fixed 2026-09-23).
5. Keep `io.flutter.embedding.android.EnableImpeller=false` in the manifest
   (Skia is the verified-good renderer on this device).

## Test device facts

- Samsung Galaxy A34 (SM A346E), Android 16, adb id `RFCWA0BJT9F`.
- adb over **Wi-Fi is set up**: `adb connect 10.10.0.6:5555` (phone IP `10.10.0.6`).
  USB is not required. If the phone's Wi-Fi IP changes, re-pair once over USB.
- Screen 1080×2340; status bar ≈ 96 px tall; edge-to-edge is ON (targetSdk 36).

## Project map

```
lib/
  main.dart                      AudioService.init + providers + routes
  playback/timbre_audio_handler.dart   audio_service handler (queue/flow/history)
  state/app_state.dart           ChangeNotifier facade over handler + library
  data/library_repository.dart   on_audio_query + sqflite side tables
  domain/models.dart             Song/Album/Artist/Genre/Playlist/FolderRef
  ui/
    shell/app_shell.dart         Scaffold: tab Stack, MiniPlayer + NavigationBar, permission gate
    home/home_screen.dart        GUIDE tab (tuner dial, presets, program guide)
    library/library_screen.dart  ARCHIVE tab (songs/albums/artists/genres/folders)
    playlists/, search/, queue/, settings/, detail/, nowplaying/
    theme/timbre_theme.dart      design tokens (cream faceplate, amber accents)
    icons/broadcast_icons.dart   custom painters
test/                            3 suites, 14 tests (unit/widget, run with `flutter test`)
tool/                            gen_icon.py, mirror-init.gradle
```

## Recent work (most recent last)

1. **Fixed launch-crash ANR (2026-09-23):** added the four FGS permissions to the
   app manifest (see rule 4). Verified: `startForegroundCount=1`,
   `isForeground=true`, playback stable, zero ANR/fatal lines.
2. **Red-screen root cause:** debug-engine Vulkan validation layer corrupts the
   surface on this Mali GPU. Workaround = release builds + Impeller disabled.
   Debug builds are still broken on-device (fine elsewhere).
3. **Header/status-bar fix:** `HomeScreen` was the only tab without `SafeArea`;
   its header row sat under the system icons. Fixed with
   `SafeArea(top: true, bottom: false)`. Verified by UI-tree measurement:
   header now starts at y=96 (status-bar bottom).
4. Full verification state at handoff: `flutter analyze` clean,
   `flutter test` 14/14 pass, release APK built and installed on the phone,
   playback verified PLAYING over Wi-Fi adb.

## How to build / test / verify

```bash
flutter analyze                                   # static checks
flutter test                                      # 14 unit/widget tests
flutter build apk --release --target-platform android-arm64   # THE device build
adb connect 10.10.0.6:5555                        # Wi-Fi adb (USB usually works too)
adb -s 10.10.0.6:5555 install -r build/app/outputs/flutter-apk/app-release.apk
adb -s 10.10.0.6:5555 shell am start -n app.timbre.timbre/.MainActivity
```

Useful on-device probes (always with `-s <transport>`):

- Foreground app: `dumpsys window | grep mCurrentFocus`
- Playback: `dumpsys media_session | grep -A12 "media-session app.timbre"`
- FGS health: `dumpsys activity services app.timbre.timbre | grep startForegroundCount`
- Crash history: `dumpsys dropbox --print data_app_anr` / `data_app_crash`
  (note: entries for `com.example.video_player` belong to the OTHER app)
- Screen sanity: `screencap -p` + pixel histogram — the day faceplate is
  rgb(236,229,214); large dark-red area = debug build, not a bug.

## Known environment quirks (Windows laptop)

- After a streamed install the adb daemon sometimes wedges ("device offline").
  `adb kill-server && adb start-server` fixes it; don't blame the cable first.
- Git Bash mangles `/sdcard/...` paths in adb shell commands. Prefix with
  `MSYS_NO_PATHCONV=1` or wrap the remote command in quotes.
- Pub cache is at `C:/Users/HP/AppData/Local/Pub/Cache/hosted/pub.dev/`
  (note: USER dir is `HP`, the username is `Admin` in some paths — check both).
- Never `flutter run` without `--release` on this phone (rule 3).

## In-app updates (added 2026-09-23, after first GitHub push)

- Settings → Updates checks `api.github.com/repos/amworx/timbre/releases/latest`
  and compares the tag against the installed version (`package_info_plus`).
- Download + auto-install via `ota_update` 7.1.0 legacy flow: APK goes to
  internal storage, then the system installer opens automatically (user taps
  Install to finish). Needs `INTERNET` + `REQUEST_INSTALL_PACKAGES` in the
  manifest, the `OtaUpdateFileProvider` entry, `res/xml/filepaths.xml`, and
  core-library desugaring 2.1.4+ in `android/app/build.gradle.kts`.
- Logic lives in `lib/update/app_updater.dart` (pure, unit-tested);
  UI in `SettingsScreen` ("Updates" section); tests in
  `test/update_check_test.dart` (20 tests: version compare, asset pick,
  checksum extract, check-flow incl. offline/rate-limit/no-APK cases).
- To ship an update users will see: bump `pubspec.yaml` version, then
  `flutter build apk --release --target-platform android-arm64`, rename the
  APK to include `arm64` (e.g. `timbre-v1.0.1-arm64.apk`), and attach it to
  a GitHub release whose tag is the version (`v1.0.1`). Optional: add a
  `sha256: <hex>` line to the release notes for checksum verification.
- Verified: `flutter analyze` clean, `flutter test` 34/34 pass, release APK
  builds (20.7MB). End-to-end on-device NOT yet tested — needs a published
  release with an APK plus coordination (shared phone, installer steals
  foreground).

## v1.0.1 batch (2026-09-23/24, all verified on-device)

- Manifest regression test (`test/manifest_test.dart`): FGS perms, updater
  provider, Impeller=false.
- Notification-denied playback: one-time prompt on first play (never blocks
  music) + Settings status tile with fix-up path.
- Full Arabic localization: gen-l10n, ~140 keys en/ar, locale-aware counts/
  dates, RTL automatic, arb parity test. Phone is en-locale so device shows
  English; Arabic activates on ar-locale phones.
- Share/delete/swipe/bulk (from prior session) + player-window actions,
  bulk-bar clearance, scrollable action sheets, Back-exits-selection.
- v1.0.1 shipped as GitHub release with arm64 APK + sha256; in-app update
  proven end-to-end on the A34 (1.0.0 → found 1.0.1 → downloaded → system
  installer → 1.0.1 running, "You're up to date", zero crashes).

## Suggested next steps (not started)

- Full inset audit: bottom gesture-bar padding behind MiniPlayer/NavigationBar
  on every screen; long lists already use ~140 bottom padding but verify.
- Graceful handling when POST_NOTIFICATIONS is denied (play without media
  notification instead of relying on FGS timing).
- In-app diagnostics screen (last crash stack, FGS state, permission status).
- Regression test asserting the merged manifest keeps the FGS permissions.
- Optional polish: scroll-away header on Home, Now Playing gestures.
