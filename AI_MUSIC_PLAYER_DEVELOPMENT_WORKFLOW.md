# AI Development Workflow — Local Music Player

## Purpose

This document defines how an AI coding assistant should build the music player safely and systematically.

The assistant must behave as an engineering partner, not as a code generator.

---

## 1. Source of Truth

Priority:

1. Project-specific AGENTS.md
2. This MVP specification
3. Existing project architecture and code
4. Official Android documentation
5. General engineering best practices

If two instructions conflict, stop and report the conflict before making a major architectural decision.

---

## 2. Required Research Sources

For Android-specific behavior, prefer official Android documentation.

At minimum verify:

- Media3 / ExoPlayer
- MediaSession / MediaSessionService
- MediaStore audio access
- Android permissions
- Foreground media playback service
- Jetpack Compose
- Edge-to-edge
- Predictive back
- Android 16 behavior changes
- Current Google Play target API requirements

Do not rely on old tutorials when an official Android source exists.

---

## 3. Work In Small Vertical Slices

Bad workflow:

> Generate 40 files → compile → discover hundreds of errors.

Required workflow:

> Plan → implement one slice → build → test → inspect → commit/checkpoint → continue.

Every slice should leave the project in a working state.

---

## 4. Before Editing

The AI must inspect:

- settings.gradle(.kts)
- build.gradle(.kts)
- app/build.gradle(.kts)
- AndroidManifest.xml
- source tree
- resources
- tests
- AGENTS.md
- README
- existing architecture

Do not overwrite existing project files without understanding them.

---

## 5. Dependency Discipline

Before adding a dependency:

1. Explain why it is needed.
2. Check whether AndroidX already provides the capability.
3. Prefer official AndroidX libraries.
4. Avoid duplicate libraries doing the same job.
5. Verify current compatible versions.
6. Avoid libraries that are abandoned or unnecessary for MVP.

Keep the dependency graph small.

---

## 6. UI-First Review Loop

For every important screen:

### Step A

Describe the screen in terms of:

- hierarchy
- spacing
- typography
- color
- components
- interaction

### Step B

Implement.

### Step C

Run/build.

### Step D

Inspect the screen on a real or emulated device.

### Step E

Fix:

- clipping
- bad spacing
- weak hierarchy
- oversized controls
- tiny touch targets
- inconsistent icons
- broken scrolling
- navigation issues
- dark-theme issues
- RTL issues

### Step F

Only then move to the next screen.

---

## 7. Never Treat Compilation As Completion

"Build successful" is not equivalent to "feature complete."

The assistant must verify behavior.

Examples:

A playback feature requires:

- playback
- pause
- seek
- next
- previous
- background playback
- system media controls
- state restoration

A library requires:

- permission
- loading
- empty state
- populated state
- error state
- refresh
- search

---

## 8. Playback Safety

The assistant must keep playback architecture separate from UI.

Do not:

- create ExoPlayer inside a Composable
- release the player when a screen disappears
- store playback state only in Compose state
- make the Now Playing screen responsible for background playback

The service/session owns playback.

UI observes and controls playback through the appropriate controller/session architecture.

---

## 9. Media Library Safety

Use MediaStore as the device music source.

Do not copy every music file into app storage.

Do not upload music anywhere.

Do not require internet access for basic playback.

The MVP should work offline after installation and permission grant.

---

## 10. Permission Discipline

Only request permissions actually required.

Audio library access:

- Android 13+: READ_MEDIA_AUDIO
- Older supported versions: use the appropriate legacy storage behavior

Permission requests must be contextual and understandable.

---

## 11. Database Discipline

Room stores app-owned state.

MediaStore remains the source of truth for device audio metadata.

Do not create a giant duplicate music database without a concrete need.

---

## 12. Error Logging

Important failures must log:

- class/function
- operation
- media ID where relevant
- playlist ID where relevant
- exception

Avoid logging:

- full file paths unless genuinely required for diagnosis
- user-generated sensitive content
- unnecessary personal information

---

## 13. Git Discipline

Before large work:

- Ensure working tree is understood.
- Do not destroy unrelated changes.
- Keep commits/checkpoints logically grouped.
- Use feature/task branches when the repository workflow requires them.
- Never reset or force-push user work without explicit approval.

Suggested checkpoint names:

- foundation
- media-library
- playback
- player-ui
- playlists
- flow
- hardening
- release

---

## 14. Scope Control

The AI must maintain an explicit:

### MVP

Things required for the first usable release.

### Later

Good ideas that are intentionally postponed.

### Rejected

Features that create disproportionate complexity or conflict with the product vision.

If a feature is not required for MVP, do not quietly add it.

---

## 15. Decision Log

For architecture decisions, record:

- Decision
- Reason
- Alternatives considered
- Consequence

Example:

> Decision: Room stores playlists instead of Android system playlists.
>
> Reason: Android system playlists are deprecated and the app needs predictable app-owned behavior.
>
> Consequence: Playlist import/export can be added later.

---

## 16. Definition of Done

Before marking a task complete:

- [ ] Code compiles
- [ ] Relevant tests pass
- [ ] No obvious lint/static-analysis issue
- [ ] Real device/emulator behavior verified
- [ ] Loading state handled
- [ ] Empty state handled
- [ ] Error state handled
- [ ] Accessibility considered
- [ ] Dark theme checked
- [ ] RTL checked where applicable
- [ ] Back navigation checked
- [ ] Performance considered
- [ ] No unnecessary permissions
- [ ] Documentation updated if behavior changed

---

## 17. Final Release Gate

Do not say:

> "The app is ready for Play Store."

Instead produce a release checklist with:

- Build status
- Test status
- Target SDK
- Manifest review
- Permission review
- Signing status
- AAB status
- Privacy/data declarations
- Known issues
- Device testing
- Android-version testing
- Remaining blockers

The user makes the final release decision.

