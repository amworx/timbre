# Local Music Player — MVP Specification

**Document:** MVP Specification  
**Version:** 1.0  
**Status:** Ready for AI-assisted implementation  
**Platform:** Android smartphones  
**Primary stack:** Kotlin + Jetpack Compose + Material 3 + AndroidX Media3  
**Product principle:** Local-first, beautiful, fast, private, simple.

---

## 1. Product Vision

Build a modern offline music player for people who already have music stored on their Android phone.

The app should feel more like a carefully designed music instrument than a traditional file browser.

### Core promise

> Open the app, find your music immediately, start playing in one or two taps, and stay out of the user's way.

### Product personality

- Elegant
- Calm
- Musical
- Modern
- Fast
- Tactile
- Private
- Uncluttered

### Explicitly avoid

- Streaming services
- User accounts
- Backend/cloud dependency
- Social features
- Advertising in the MVP
- AI/cloud recommendations
- Complicated audio-processing pipelines
- Excessive settings
- Feature-heavy dashboards
- Copying Spotify/Apple Music UI

---

# 2. MVP Feature Set

## 2.1 Library

Scan Android MediaStore for locally available audio.

Primary library categories:

- Songs
- Albums
- Artists
- Genres
- Folders

Each song should expose, where available:

- Title
- Artist
- Album
- Album artist
- Duration
- Track number
- Album art
- URI
- MIME type
- File size
- Date added

The app must handle missing or malformed metadata gracefully.

### Library behavior

- First scan after permission grant
- Incremental refresh when practical
- Pull-to-refresh
- Empty state
- Missing-art fallback
- Unknown artist/album handling
- Very large libraries must remain responsive
- No blocking UI while scanning

---

# 3. Playback

Use AndroidX Media3 / ExoPlayer for playback.

Required:

- Play
- Pause
- Previous
- Next
- Seek
- Seek forward/backward
- Queue
- Shuffle
- Repeat off / all / one
- Playback speed
- Resume position
- Background playback
- Lock-screen/media controls
- Bluetooth/headset controls where supported
- Audio focus handling
- Becoming-noisy handling
- Continue playback while app is not visible
- Restore playback state after app restart

Playback must be owned by a media service/session rather than by a screen.

---

# 4. Signature Features

These features make the player feel different without creating a large technical scope.

## 4.1 Flow Queue

The user can turn any song into a temporary listening session.

Example:

> Play this song → Flow

The app creates a queue from nearby musical context using local metadata:

1. Current song
2. More from the same artist
3. More from the same album/genre
4. Recently enjoyed songs
5. Other tracks not recently played

No cloud AI is required.

### Important

The algorithm must remain deterministic, explainable, lightweight, and local.

Display a small explanation such as:

> Flow • Similar artist + recent favorites

The user can always edit the queue.

---

## 4.2 Continue Listening

Remember where the user stopped.

On reopening the app:

> Continue listening  
> Song title — 02:41 remaining

One tap resumes playback.

This should be more prominent than a generic "Recently Played" list.

---

## 4.3 Listening Memory

A small local history system.

Track:

- Last played
- Play count
- Last position
- Completed plays

Use this only to improve navigation and Flow Queue.

Do not turn this into a statistics dashboard in the MVP.

Useful surfaces:

- Recently played
- Most played
- Not played recently

---

## 4.4 Sleep Timer With Fade

Simple sleep timer:

- 15 min
- 30 min
- 45 min
- 60 min
- End of current track

Optional MVP enhancement:

- Fade volume during the final 30 seconds

Do not implement advanced audio DSP.

---

## 4.5 Quick Actions

Long-press or overflow actions:

- Play next
- Add to queue
- Add to playlist
- Favorite
- Go to artist
- Go to album
- Share song

Keep destructive actions separated.

---

# 5. Playlists

MVP supports local playlists created inside the app.

Required:

- Create playlist
- Rename
- Delete
- Add/remove songs
- Reorder songs
- Play playlist
- Shuffle playlist

Suggested starter playlists:

- Favorites
- Recently Played

Do not rely on deprecated Android system playlists as the application's primary playlist database.

Use the app's own Room data for playlists.

---

# 6. Favorites

A simple favorite/bookmark state.

Favorite actions must be available from:

- Song row
- Mini player
- Now Playing
- Song menu

Favorites should appear as a prominent library destination.

---

# 7. Search

One global search.

Search across:

- Song title
- Artist
- Album
- Genre

Search behavior:

- Instant filtering
- Typing should feel responsive
- Group results by type
- Show useful empty state
- Preserve recent search terms locally only if implemented

Do not build a complex search engine.

---

# 8. UI / UX Direction

## 8.1 Design Goal

The UI should be:

> "Premium and distinctive without looking complicated."

Do not imitate Spotify, YouTube Music, Apple Music, Poweramp, or other major players.

The visual identity should come from:

- Strong typography
- Album artwork
- Large intentional spacing
- Soft depth
- Subtle motion
- Clear hierarchy
- One distinctive accent treatment
- Excellent micro-interactions

---

# 9. Recommended Visual Concept

## "Album Canvas"

The interface uses the current album artwork as the visual anchor.

The artwork should influence a subtle local surface treatment:

- blurred artwork background
- low-opacity color wash
- dark/light contrast adaptation
- restrained gradient

Important:

The artwork effect must never reduce readability.

Do not turn every screen into a colorful gradient.

Use artwork-driven visual treatment primarily on:

- Now Playing
- Mini player
- Selected album/artist surfaces

Library screens should remain calm and readable.

---

# 10. Main Navigation

Use a small navigation model.

Recommended bottom navigation:

1. Home
2. Library
3. Playlists
4. Search

The mini player sits above the navigation bar whenever music is active.

Do not create a fifth navigation destination for Settings.

Settings should be accessible from the Home/library header.

---

# 11. Home Screen

The Home screen should answer:

> "What should I listen to right now?"

Suggested structure:

### Header

- App name/logo
- Settings button

### Continue Listening

Large compact card:

- Album art
- Song title
- Artist
- Progress
- Play/resume button

### Quick Mix

A visually distinctive horizontal card:

> Flow

Subtitle:

> A fresh queue from your library

Action:

> Start Flow

### Recently Played

Horizontal or compact vertical list.

### Favorites

Small horizontal collection.

Do not overload Home with many sections.

---

# 12. Library Screen

Top:

- "Library"
- Search shortcut
- Refresh

Category chips/tabs:

- Songs
- Albums
- Artists
- Genres
- Folders

Song rows should contain:

- Small artwork
- Title
- Artist
- Duration
- Favorite indicator if active
- Overflow menu

Interactions:

- Tap = play
- Long press = contextual actions
- Swipe actions may be added only if they remain discoverable and accessible

---

# 13. Now Playing Screen

This is the emotional center of the app.

### Layout

Top:

- Back/minimize
- Queue button
- More menu

Center:

- Large square album artwork
- Rounded corners
- Very subtle elevation
- Optional artwork-derived background

Below:

- Song title
- Artist
- Album

Progress:

- Thin but easily touchable seek area
- Current time
- Remaining time

Controls:

- Shuffle
- Previous
- Large Play/Pause
- Next
- Repeat

Secondary:

- Favorite
- Queue
- Sleep timer
- Speed

### Gesture behavior

- Swipe down: dismiss Now Playing
- Swipe left/right: previous/next where appropriate
- Tap artwork: optional visual state change, but never hide essential controls

The screen must remain usable one-handed.

---

# 14. Mini Player

Persistent whenever a song is active.

Contains:

- Album art
- Song title
- Artist
- Play/pause
- Optional next

Tap opens Now Playing.

The mini player must not compete with bottom navigation.

---

# 15. Queue Screen

Display:

### Now Playing

Current item highlighted.

### Up Next

Remaining queue.

Actions:

- Reorder
- Remove
- Play immediately
- Add song
- Clear queue

Use drag handles only where necessary.

Do not make queue editing visually complicated.

---

# 16. Search UI

Search should open quickly.

Top:

- Search field
- Back button

Results:

- Songs
- Artists
- Albums
- Genres

Use clear section headers.

When there are no results:

> Nothing found

Then show a helpful suggestion:

> Try another song, artist, or album.

---

# 17. Empty States

Never show a blank screen.

Examples:

### No music

> Your music will appear here.

Action:

> Scan library

### No favorites

> Favorite songs you want to find quickly.

### No playlists

> Make a playlist for your next listening session.

### Search empty

> Nothing found.

Each empty state should have one primary action where appropriate.

---

# 18. Permission UX

Request audio permission only when the user reaches a feature that requires local music.

Do not request unnecessary permissions.

Explain before requesting permission:

> Your music stays on your device. We only need access to find and play your audio files.

If permission is denied:

- Explain what is unavailable
- Provide a retry path
- Do not repeatedly prompt without user action

---

# 19. Accessibility

The AI must treat accessibility as part of implementation, not polish.

Required:

- Content descriptions for meaningful icons/images
- Touch targets at least 48dp
- Sufficient contrast
- Dynamic text scaling
- TalkBack-friendly controls
- Avoid information conveyed by color alone
- Clear focus order
- RTL support
- Arabic text must render correctly

---

# 20. Motion Design

Motion should communicate state.

Use subtle animations for:

- Play/pause transitions
- Mini player appearance
- Navigation
- Queue changes
- Favorite state
- Artwork transitions
- Bottom sheets

Avoid:

- Constant floating animations
- Excessive spring effects
- Slow page transitions
- Decorative animation that consumes battery

Target perception:

> Fast, calm, responsive.

---

# 21. UI Design Rules For The AI

The AI must follow these rules while implementing UI.

1. Do not create generic CRUD-looking screens.
2. Do not fill empty space with unnecessary cards.
3. Do not use gradients everywhere.
4. Do not use excessive rounded containers.
5. Do not use huge text unless it establishes hierarchy.
6. Do not use icons without a clear purpose.
7. Do not hide essential playback controls behind menus.
8. Prefer composition and spacing over decoration.
9. Prefer one strong visual idea per screen.
10. Every interaction should have an obvious visual response.
11. Preserve Android platform conventions where users expect them.
12. Use Material 3 components as foundations, not as a reason for a generic Material UI.
13. Keep touch targets comfortable.
14. Use edge-to-edge correctly.
15. Design for small phones first.
16. Then adapt to larger screens.
17. Never hardcode layout assumptions for one device size.
18. Test light and dark themes.
19. Test Arabic/RTL layouts even if English is the primary development language.
20. Avoid visual noise.

---

# 22. Color System

Use a restrained theme.

Base:

- Dark theme should be first-class.
- Light theme must also be supported.

Accent:

- One primary accent derived from the product identity.
- Optional artwork-derived accent on Now Playing.

Do not hardcode colors throughout composables.

All colors belong in the theme/design system.

---

# 23. Typography

Use a clear hierarchy:

- Display: Now Playing title
- Headline: section titles
- Title: song/album names
- Body: metadata
- Label: buttons and secondary actions

Avoid excessive font weights.

Typography should carry much of the visual identity.

---

# 24. Architecture

Recommended:

- Kotlin
- Jetpack Compose
- Material 3
- MVVM
- Clean Architecture boundaries
- Room
- Hilt
- Coroutines
- Flow/StateFlow
- AndroidX Media3
- Navigation Compose

Suggested structure:

app/
  data/
    local/
    media/
    repository/
  domain/
    model/
    repository/
    usecase/
  playback/
  ui/
    home/
    library/
    search/
    playlists/
    nowplaying/
    queue/
    settings/
    components/
    theme/
  di/

Keep domain models independent from Android framework classes where practical.

---

# 25. Playback Architecture

The playback engine must be independent from Compose screens.

Recommended:

MediaController
    ↓
MediaSession
    ↓
MediaSessionService
    ↓
ExoPlayer

The UI observes playback state.

The UI must not own the ExoPlayer lifecycle.

Required playback state:

- Current media item
- Is playing
- Position
- Duration
- Queue
- Shuffle state
- Repeat state
- Playback speed

---

# 26. Local Data

Use Room for application-owned state.

Suggested entities:

SongHistory
- mediaId
- lastPlayedAt
- playCount
- lastPositionMs
- completedCount

Favorite
- mediaId
- createdAt

Playlist
- id
- name
- createdAt
- updatedAt

PlaylistSong
- playlistId
- mediaId
- position

AppSettings
- key/value or typed settings

Do not duplicate the entire MediaStore database in Room unless a concrete requirement appears.

MediaStore remains the source for device music metadata.

---

# 27. Flow Queue Algorithm

MVP algorithm:

Input:
- current song
- library
- listening history
- favorites

Score candidates approximately by:

1. Same artist
2. Same album/genre
3. Favorite
4. Frequently played
5. Not played recently
6. Avoid current song
7. Avoid duplicates

Then shuffle within similar score groups.

The algorithm must be deterministic enough to debug.

Keep it as a pure domain component so it can be tested without Android.

---

# 28. Performance Requirements

The app must remain responsive with:

- 1,000 songs
- 5,000 songs
- 10,000+ songs

Requirements:

- Lazy lists
- Stable keys
- No full-library recomposition
- No blocking MediaStore query on the main thread
- Cache expensive derived data
- Avoid loading full-resolution album artwork into every list item
- Avoid unnecessary database writes
- Do not perform expensive work during Compose recomposition

---

# 29. Error Handling

Every important operation must have a user-safe failure state.

Examples:

- MediaStore unavailable
- Permission denied
- Corrupt audio
- Unsupported format
- Missing artwork
- Playback failure
- Database failure

User-facing errors should be understandable.

Developer logs should include:

- function/component name
- relevant media ID
- relevant playlist ID where applicable
- exception type
- useful diagnostic context

Never log sensitive user data unnecessarily.

---

# 30. Testing

Minimum tests:

## Unit

- Flow Queue scoring
- History updates
- Favorite operations
- Playlist ordering
- Search filtering
- Resume position
- Sleep timer logic

## UI

- Home
- Library
- Search
- Now Playing
- Queue
- Playlist creation

## Playback

- Play/pause
- Next/previous
- Seek
- Background playback
- Queue persistence
- Audio focus
- Bluetooth/headset controls where testable

## Device

Test at minimum:

- Small phone
- Modern Android phone
- Android 13+
- Android 15+
- Android 16
- Light theme
- Dark theme
- RTL
- Large font scale

---

# 31. Google Play Readiness

The app is intended to be publishable on Google Play.

The AI must not consider the project complete merely because it compiles.

Before release:

- Release build succeeds
- App launches from a clean install
- No debug-only dependencies
- No test credentials
- Correct application ID
- App icon
- Adaptive icon
- App name
- Versioning
- Privacy policy if required by the final data/permissions behavior
- Accurate permission declarations
- Accurate Play Console declarations
- Release signing configuration prepared
- ProGuard/R8 checked
- Crash-free smoke test
- Offline behavior tested
- Background playback tested
- Android 16 behavior tested
- Target API 36 or newer for current Google Play submission requirements
- No unnecessary permissions
- No hidden network dependency
- No copyrighted demo media bundled into release

The AI must verify current Play requirements before final release because Google Play policies can change.

---

# 32. MVP Non-Goals

Do NOT implement these in MVP:

- Cloud synchronization
- User accounts
- Streaming
- Lyrics scraping
- Online music discovery
- AI-generated recommendations
- Social sharing feeds
- Equalizer with complex DSP
- Audio normalization engine
- Music recognition
- Podcast support
- Android Auto unless separately scoped
- Wear OS
- Desktop version
- Cloud backup
- Subscription system
- Ads

These can be evaluated after MVP validation.

---

# 33. Phase 2 Ideas

Only consider these after the MVP is stable.

Possible low-complexity additions:

1. Smart "Forgotten Favorites"
   - Favorites not played for a long time.

2. "Finish Album"
   - One tap to continue an unfinished album.

3. Mood-free Flow presets
   - Calm
   - Familiar
   - Discover
   - Recent

4. Folder shortcuts

5. Home screen widgets

6. Android Auto

7. Import/export playlists

8. Audio tags editor

9. Optional equalizer

10. Local backup/export of app settings and playlists

Avoid adding Phase 2 features until the MVP has been tested with real users.

---

# 34. Definition of Done

A feature is NOT complete when the AI writes the code.

A feature is complete only when:

- Code compiles
- Relevant tests pass
- UI works on a real/emulated device
- Loading state exists
- Empty state exists where needed
- Error state exists where needed
- Accessibility has been considered
- Dark/light themes work
- RTL does not break it
- Rotation/configuration changes are handled where applicable
- Navigation/back behavior works
- No obvious performance regression exists
- Logs are useful
- No unnecessary permission is introduced
- Documentation is updated

---

# 35. AI Development Rules

The AI assistant must work in phases.

It must NOT generate the whole application blindly in one pass.

Required workflow:

## Phase 0 — Understand

Read:

- MVP_SPEC.md
- AGENTS.md
- project instructions
- existing source code
- existing tests

Then produce:

- architecture summary
- implementation plan
- dependency plan
- risk list

Do not modify code yet.

## Phase 1 — Project Foundation

Implement:

- Gradle/project configuration
- theme
- navigation foundation
- dependency injection
- data/domain skeleton
- testing foundation

Build and verify.

## Phase 2 — Media Library

Implement:

- permission flow
- MediaStore repository
- song model
- library UI
- search
- album/artist grouping

Build and test.

## Phase 3 — Playback

Implement:

- Media3
- ExoPlayer
- MediaSession
- MediaSessionService
- MediaController
- background playback
- notification/system controls

Test on a real device.

## Phase 4 — Player UX

Implement:

- mini player
- Now Playing
- queue
- seek
- shuffle/repeat
- playback state persistence

## Phase 5 — Personal Features

Implement:

- favorites
- history
- Continue Listening
- Flow Queue
- playlists
- sleep timer

## Phase 6 — UI Refinement

Perform a dedicated UI/UX pass.

Check:

- spacing
- typography
- visual hierarchy
- animations
- accessibility
- empty states
- error states
- dark/light
- RTL
- small screens
- larger screens

Do not add features during this phase unless required to fix UX.

## Phase 7 — Hardening

Run:

- unit tests
- UI tests
- playback tests
- lint
- static analysis
- release build
- install/uninstall test
- permission-denied test
- empty-library test
- large-library test

## Phase 8 — Play Readiness

Verify:

- current Google Play target API requirement
- manifest
- permissions
- app metadata
- release configuration
- privacy/data declarations
- signing
- release APK/AAB

Then report remaining issues.

---

# 36. AI Communication Protocol

The AI must not silently make major product decisions.

For ambiguous decisions:

1. Identify the decision.
2. Give the smallest number of reasonable options.
3. Recommend one based on the MVP goals.
4. Wait for confirmation if the decision can materially affect architecture or scope.

For minor implementation details:

- Make the decision autonomously.
- Follow Android best practices.
- Document the decision if it affects future work.

Never expand scope simply because an implementation is technically possible.

---

# 37. UI Implementation Protocol

Before implementing each screen, the AI must first define:

- screen purpose
- primary user action
- visual hierarchy
- component hierarchy
- states
- navigation behavior
- loading state
- empty state
- error state
- accessibility behavior
- animation behavior

Then implement.

The AI must inspect the result visually before declaring the screen finished.

If screenshots or an emulator are available, compare the implementation against the UI specification and fix obvious visual defects.

---

# 38. Product Success Criteria

The MVP should make these actions extremely easy:

1. Find music
2. Play music
3. Resume music
4. Control playback
5. Build a queue
6. Favorite a song
7. Create a playlist
8. Search
9. Continue listening
10. Start Flow

If a new feature makes one of these actions harder, reconsider the feature.

---

# 39. First Implementation Task For The AI

Do NOT start coding immediately.

First:

1. Read this document completely.
2. Inspect the project.
3. Inspect existing AGENTS.md/instructions.
4. Verify current Android/Media3/Play requirements from official Android documentation.
5. Propose the project architecture.
6. Propose the package structure.
7. Identify dependencies.
8. Identify risks.
9. Identify decisions requiring user approval.
10. Create an implementation plan with small verifiable tasks.

Wait for approval before implementing the foundation if the project is new.

