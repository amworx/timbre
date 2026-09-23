# Timbre — Portfolio Brief

> Copy-paste-ready description of the Timbre app for the portfolio site's
> Projects section. Prepared 2026-09-24.

## Essentials

- **Name:** Timbre
- **What:** Offline music player for Android (plays the music already on your device — no account, no streaming, no tracking)
- **Platform:** Android (Flutter, single codebase)
- **Status:** v1.0.1, live and tested on-device
- **Repo:** https://github.com/amworx/timbre
- **Latest release:** https://github.com/amworx/timbre/releases/tag/v1.0.1

## Short description (use as the project card blurb)

> Timbre is a calm, offline-first music player for Android with a broadcast-radio
> personality — tune the dial, save presets, and play your local library with
> smart Flow queues, playlists, and in-app updates.

## Longer description (use for the project detail page)

> Timbre treats your local music library like a radio station you own. A tuner
> dial (Archive / Flow / Favorites), memory presets for playlists, a program
> guide with continue-listening and recently played, and a full archive browser
> (songs, albums, artists, genres, folders) with search. Playback runs through a
> foreground audio service with lock-screen controls, sleep timer, and playback
> speed. Extras include Gmail-style swipe actions and bulk selection, real audio
> file sharing, safe on-device delete with Android's consent flow, self-updating
> releases from GitHub, and a full Arabic (RTL) interface alongside English.

## Feature highlights (bullets for the page)

- Offline playback of the device library — MediaStore scan, no network needed
- Broadcast-radio UI: tuner dial, presets, program guide, "on air" Now Playing
- Smart Flow queues built from listening history + favorites
- Playlists, favorites, continue-listening, recently played, global search
- Swipe-to-share / swipe-to-delete, long-press bulk actions
- In-app updates: checks GitHub Releases, downloads, installs automatically
- Full Arabic RTL localization with in-app language switcher
- Sleep timer, playback speed, background + lock-screen controls

## Tech stack (badges/shields)

Flutter (Dart) · audio_service + just_audio · on_audio_query (MediaStore) ·
sqflite + shared_preferences · provider · Material 3 · Kotlin bridge
(MediaStore delete) · GitHub Releases (distribution)

## Design notes (for styling the portfolio entry)

- **Metaphor:** vintage broadcast receiver — GUIDE / ARCHIVE / BANK / SCAN tabs,
  "stations", "tuned", "on air"
- **Palette:** warm cream faceplate `rgb(236, 229, 214)` with amber accents,
  full light/dark themes
- **Type:** Inter (UI) + IBM Plex Mono (dial/readouts)
- **Bilingual:** English (LTR) + Arabic (RTL) — same layout mirrors cleanly

## Assets available in the repo

- `timbre_icon.png`, `timbre_icon_fg.png`, `timbre_icon_mono.png` — launcher icon + variants
- `design_gallery/` — design references (`index.html`, device screenshot page)
- `_blank.png` — placeholder art
- Live screenshots available on request (GUIDE tuner, Library, Arabic RTL, update flow)
