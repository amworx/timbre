# Project agent rules

## NEVER launch the Android emulator / Android Studio simulator

Running an AVD/emulator severely slows down the user's laptop.
Do **not** run any of the following, ever:

- `emulator -avd ...` / `avdmanager`
- `flutter emulators --launch ...`
- Any Android Studio simulator or device-manager launch
- Any script or IDE action that boots an Android virtual device

## SHARED TEST DEVICE — another AI assistant tests a different app on this phone

A second AI session tests `com.example.video_player` (the sibling `../video_player`
project) on the **same physical phone** (SM A346E, adb id `RFCWA0BJT9F`).
To never confuse the two apps:

- Always target the device explicitly: `adb -s RFCWA0BJT9F ...`.
- Timbre's package is `app.timbre.timbre`. Before driving the UI or reading
  screenshots/dumps/logs, verify the foreground app:
  `adb -s RFCWA0BJT9F shell dumpsys window | grep mCurrentFocus`
  If the focused package is not `app.timbre.timbre`, re-launch Timbre first and
  re-verify — taps and captures may otherwise land in the other app.
- Filter logs by Timbre's pid: `adb -s RFCWA0BJT9F logcat --pid=$(adb ... pidof app.timbre.timbre)`.
- NEVER force-stop, uninstall, clear data of, or tap inside the other
  assistant's app. Don't kill processes you didn't start.
- Launching Timbre steals the foreground and can confuse the other session —
  coordinate with the user before long UI-driven test runs on the phone.
- A red ErrorWidget screen, crash, or active media session seen while another
  app is focused may belong to the OTHER app — confirm the package before
  attributing any symptom to Timbre.

## THIS DEVICE (Galaxy A34 / Mali GPU): debug builds render a SOLID RED screen

Verified 2026-09-20: any **debug** APK of Timbre on this phone renders as a solid
red screen (widget tree/logic stay healthy underneath — audio keeps playing and
taps still land, which made the app look "crashed" and the audio unstoppable).
Release builds render perfectly. The debug engine ships Vulkan validation
layers that corrupt the surface on this Mali driver; disabling Impeller
(`io.flutter.embedding.android.EnableImpeller=false` in the manifest) did NOT
fix debug — only release/profile works.

- For ALL on-device testing use `flutter build apk --release` or
  `flutter run --release`/`--profile`. Never install a debug APK on this phone.
- A red screen on the physical display here = debug build, not an app bug.
  (The sibling `../video_player` debug app does NOT show this — it is
  Timbre-specific.)
- Keep the `EnableImpeller=false` meta-data in AndroidManifest.xml unless the
  GPU driver is fixed; Skia is the verified-good renderer on this device.

## AUDIO_SERVICE 0.18.19 NEEDS EXPLICIT FGS PERMISSIONS (empty plugin manifest)

Verified 2026-09-23: `audio_service` 0.18.19 ships an **empty** plugin manifest —
it does NOT contribute WAKE_LOCK / FOREGROUND_SERVICE /
FOREGROUND_SERVICE_MEDIA_PLAYBACK / POST_NOTIFICATIONS. On Android 14+
(targetSdk 36) the app then dies shortly after EVERY launch with
`Context.startForegroundService() did not then call Service.startForeground()`
(ANR; `dumpsys activity services` shows `startForegroundCount=0`). The
permissions are now declared in `android/app/src/main/AndroidManifest.xml` —
keep them there if the plugin is upgraded.

### Allowed instead

- `flutter test` (unit/widget tests — no device needed)
- `flutter analyze` / `dart analyze`
- `flutter build apk` / `flutter build appbundle` (compile without booting a device)
- A **physical Android device** the user plugs in (`flutter run -d <device-id>`, after confirming with the user)
- `flutter run -d windows` if the user explicitly asks to run on desktop
