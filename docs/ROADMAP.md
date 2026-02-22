# Vampir Köylü — Milestone Roadmap

> Generated from audit reviews audit-001 through audit-006.
> Each task has an audit source reference. Check the box when done.

---

## How to read this

- **Risk ID** — matches the 20-item risk table in `audit.md`
- **Effort** — S (< half-day) · M (1–2 days) · L (3–5 days) · XL (1+ week)
- **Stream** — A Auth · B Game Logic · C UI · D Infrastructure
- **Source** — which audit review first identified this

---

## Milestone 0 — Stabilization
> Goal: fix all CRITICAL + HIGH issues before any playtesting with real users.

### 0.1 Security Foundation

- [ ] **[R1-a] Write and deploy `firestore.rules`** — deny all reads/writes by default; allow only authenticated room members to read/write their room; allow only the host to mutate `gameState`, `phase`, `deadPlayers`
  - Effort: M · Stream: D · Source: audit-002 B.4
  - File: `firestore.rules` (create), `firebase.json` (add rules reference)

- [ ] **[R1-b] Add minimal Firestore schema hardening** — add write allowlists for `players`, `nightActions`, `dayVotes` so clients can only write their own sub-keys
  - Effort: S · Stream: D · Source: audit-002 B.4

- [ ] **[R20] Remove `bonusNickname` backdoor** — delete the `kadergamer123` constant and the bonus-gold branch
  - Effort: S · Stream: D · Source: audit-001 B.4
  - File: `lib/services/gold_service.dart:L6-L7, L52-L57`

### 0.2 Day-Phase Race Fix

- [ ] **[R2-a] Add `phaseResolutionLock` field to the room document** — use a Firestore Transaction: read lock → check if already resolved → only proceed if not locked; set lock before writing resolution results
  - Effort: M · Stream: B · Source: audit-002 B.1
  - Files: `lib/services/day_resolution_service.dart`, `lib/screens/game_screen.dart:L654-L670, L909-L929`

- [ ] **[R2-b] Remove auto-resolution from non-host clients** — `_shouldAutoStartVoting` must only fire on the host client; all others should be read-only observers
  - Effort: S · Stream: B · Source: audit-002 B.1
  - File: `lib/screens/game_screen.dart:L654-L670`

### 0.3 Night Resolution Correctness

- [ ] **[R4] Fix blocked-role actor lookup** — resolve the acting player's ID by role explicitly before checking `blockedPlayers`; do not rely on map iteration order
  - Effort: S · Stream: B · Source: audit-004 B.1
  - File: `lib/services/night_resolution_service.dart:L95-L128`

- [ ] **[R5] Fix misafir/doctor block semantics** — block should cancel the *doctor's* protection action (check actor ID, not target ID)
  - Effort: S · Stream: B · Source: audit-005 B.1
  - File: `lib/services/night_resolution_service.dart:L45-L59`

- [ ] **[R7] Fix doctor overwrite at 12+ players** — change `roleActions` from `Map<String, String>` keyed by role to a per-player structure so two doctors don't clobber each other
  - Effort: S · Stream: B · Source: audit-002 B.3
  - File: `lib/services/night_resolution_service.dart:L31-L38, L63`

- [ ] **[R11] Add role-based target constraints for night actions** — vampirs must not be able to select fellow vampirs as targets
  - Effort: S · Stream: B · Source: audit-005 B.2
  - File: `lib/screens/game_screen.dart:L189-L235`

### 0.4 Room Integrity

- [ ] **[R8] Wrap join/leave/kick in Firestore Transactions** — `playerCount` increment and `players` map update must be atomic; prevents capacity bypass
  - Effort: M · Stream: B · Source: audit-001 B.6
  - Files: `lib/screens/join_room_screen.dart:L171-L187`, `lib/screens/room_lobby_screen.dart:L95-L100, L149-L152`

- [ ] **[R9] Add room-code collision guard on create** — check doc existence inside a transaction before writing; regenerate code on conflict
  - Effort: S · Stream: B · Source: audit-004 B.2
  - File: `lib/screens/create_room_screen.dart:L60-L81`

- [ ] **[R12] Enforce single active room per user (all states)** — extend existing check from `waiting` only to all `gameState` values; best enforced via a `currentRoomId` field on the user/guest doc
  - Effort: M · Stream: B · Source: audit-005 B.3
  - Files: `lib/main.dart:L117-L158`, `lib/screens/join_room_screen.dart:L28-L55`

- [ ] **[R13] Guard `deadPlayers` append against duplicates** — before any `deadPlayers.add(id)` call, check `!deadPlayers.contains(id)` and `players.containsKey(id)`
  - Effort: S · Stream: B · Source: audit-006 B.3
  - Files: `lib/services/night_resolution_service.dart:L83`, `lib/services/day_resolution_service.dart:L52`

### 0.5 Identity & Auth (Planning)

- [ ] **[R6] Migrate auth to Firebase Auth** — replace custom SHA-256+SharedPrefs session with Firebase Auth Anonymous (guests) + Email/Password (accounts); enables server-verified tokens, rate limiting, account deletion
  - Effort: L · Stream: A · Source: audit-002 B.2
  - Files: `lib/services/auth_service.dart`, all screen files

- [ ] **[R3] Bind Firestore writes to Firebase Auth UID** — after auth migration, update Firestore rules to enforce `request.auth.uid == resource.data.playerId`
  - Effort: M · Stream: A · Source: audit-004 B.3 _(depends on R6)_

- [ ] **[R14] Fix nickname uniqueness race** — introduce a `nicknames/{nicknameLower}` document with transaction/create-only semantics; fail fast on conflict
  - Effort: M · Stream: A · Source: audit-006 B.1

### 0.6 Debug Cleanup

- [ ] **Gate bot button behind `kDebugMode`** — "BOT EKLE" must not appear in production builds
  - Effort: S · Stream: C · Source: audit-002 B.5
  - File: `lib/screens/room_lobby_screen.dart:L532-L585`

- [ ] **Remove `testRoles()` dead code** — no callers; delete or gate behind `kDebugMode`
  - Effort: S · Stream: D · Source: audit-001 B.8
  - File: `lib/services/role_distribution.dart:L103-L128`

- [ ] **Remove unused `firebase_messaging` dependency**
  - Effort: S · Stream: D · Source: audit-001 B.7
  - File: `pubspec.yaml`

---

## Milestone 1 — Core Loop Completion
> Goal: every role works, every game can finish correctly, and the loop is repeatable.

### 1.1 Missing Role Implementations

- [ ] **[R10-a] Implement `asik` (lover) role logic in night resolution** — define the win-condition override (lovers die together); update `resolveNight()` accordingly
  - Effort: M · Stream: B · Source: audit-003 B.9
  - File: `lib/services/night_resolution_service.dart`

- [ ] **[R10-b] Implement `manipulator` role logic** — swap-vote effect in day resolution; add to `nightRoles` list and resolve in `resolveNight()`
  - Effort: M · Stream: B · Source: audit-003 B.9
  - File: `lib/services/night_resolution_service.dart`, `lib/services/day_resolution_service.dart`

- [ ] **[R10-c] Add `manipulator` to `RoleRevealScreen` role metadata map** — currently missing, causes silent display bug
  - Effort: S · Stream: C · Source: audit-001 B.5
  - File: `lib/screens/role_reveal_screen.dart:L21-L54`

### 1.2 Role Metadata Consolidation

- [ ] **Consolidate role metadata into `lib/models/role_metadata.dart`** — create canonical `GameRole` enum, `RoleMetadata` class, and single source for `roleIcons`, `roleNames`, `roleColors`, `roleDescriptions`; update all 4 call sites
  - Effort: M · Stream: C · Source: audit-001 B.5
  - Files: `game_screen.dart:L703-L745`, `role_reveal_screen.dart:L21-L54`, `role_info_dialog.dart:L12-L73`, `game_end_screen.dart:L160-L230`

### 1.3 Phase State Machine

- [ ] **Implement enforced phase-transition state machine** — define allowed transitions (`waiting → roleReveal → night → dayDiscussion → dayVote → resolution → finished`); block invalid transitions server-side
  - Effort: M · Stream: B · Source: audit-001 D (M1)

- [ ] **[R-clock] Replace client-clock phase timing with server timestamp** — store `phaseStartedAt` server timestamp in Firestore; derive elapsed time from that, not `DateTime.now()`
  - Effort: M · Stream: B · Source: audit-004 B.4
  - Files: `lib/screens/game_screen.dart:L38-L55`, `lib/screens/widgets/game_time_display.dart:L45-L74`

### 1.4 Rematch / Restart Flow

- [ ] **Implement rematch flow from end screen** — same room reset (clear `deadPlayers`, `nightActions`, `dayVotes`, `phase`; reassign roles); return to lobby state
  - Effort: M · Stream: B · Source: audit-001 D (M1)
  - File: `lib/screens/game_end_screen.dart`

### 1.5 Reconnect / Resume

- [ ] **Add reconnect/resume for players re-opening mid-game** — detect active room on app start via `currentRoomId` on user doc; route directly to `GameScreen` if game is in progress
  - Effort: M · Stream: A · Source: audit-003 B.2

### 1.6 Tests

- [ ] **Add unit tests for `calculateRoles()`** — cover all player-count thresholds, role ratios, edge cases
  - Effort: S · Stream: D · Source: audit-001 B.9

- [ ] **Add unit tests for win conditions** — all three win paths (vampir win, köylü win, deli win)
  - Effort: S · Stream: D · Source: audit-001 B.9

- [ ] **Add unit tests for night resolution** — doctor protection, blocked actors, misafir block, two-doctor case
  - Effort: M · Stream: D · Source: audit-002 B.3

- [ ] **Add unit tests for day voting resolution** — majority vote, tie, auto-resolve
  - Effort: S · Stream: D · Source: audit-001 D (M1)

### 1.7 UX Fixes

- [ ] **[R17] Fix guest reward display** — hide gold reward badge (`💰 +10`) for guest users on end screen
  - Effort: S · Stream: C · Source: audit-005 B.4
  - Files: `lib/screens/game_end_screen.dart:L120-L170`

- [ ] **[R18] Handle room deletion gracefully** — when room doc is missing/deleted, navigate non-host clients back to main menu with a clear message (or use soft-close flag)
  - Effort: S · Stream: C · Source: audit-006 B.2
  - Files: `lib/screens/room_lobby_screen.dart:L71-L90`, `lib/screens/game_screen.dart:L606-L623`

---

## Milestone 2 — Content & Polish
> Goal: the game feels good to play, handles edge cases smoothly.

- [ ] **Decompose `game_screen.dart` monolith [R15]** — extract phase sub-widgets, host panel, night action panel, day vote panel into separate files; introduce `GameController` class
  - Effort: L · Stream: C · Source: audit-001 B.1

- [ ] **Add state management (Riverpod)** — replace fragmented `setState` with Riverpod providers for auth state, game state, player state
  - Effort: L · Stream: C · Source: audit-003 B.4

- [ ] **Add proper routing with `go_router`** — define named routes, authentication guards, deep-link support
  - Effort: M · Stream: C · Source: audit-003 B.5

- [ ] **Replace sequential gold writes with `WriteBatch`** — batch all per-player reward writes into one Firestore batch
  - Effort: S · Stream: B · Source: audit-001 B.11
  - File: `lib/services/gold_service.dart:L78-L97`

- [ ] **Add `currentRoomId` field to user/guest documents** — enables O(1) membership lookup; replaces O(N rooms) scan
  - Effort: S · Stream: B · Source: audit-006 B.4

- [ ] **Phase transition animations and alive/dead/voted visual states**
  - Effort: M · Stream: C · Source: audit-001 D (M2)

- [ ] **Audio/haptic feedback layer**
  - Effort: M · Stream: C · Source: audit-001 D (M2)

- [ ] **Role tooltip / onboarding tutorial**
  - Effort: S · Stream: C · Source: audit-001 D (M2)

- [ ] **Reduce Firestore stream rebuild scope** — use sub-collection listeners or narrower `StreamBuilder` scopes to prevent full rebuilds on any field change
  - Effort: M · Stream: C · Source: audit-001 B.10

---

## Milestone 3 — Production Readiness
> Goal: safe to ship to the Play Store.

- [ ] **[R19] Configure release signing with a real keystore** — replace debug signing in release build config
  - Effort: S · Stream: D · Source: audit-003 B.10
  - File: `android/app/build.gradle.kts:L33-L42`

- [ ] **Add CI pipeline** — `flutter analyze`, `flutter test`, `flutter build apk --release` on every push
  - Effort: M · Stream: D · Source: audit-001 D (M3)

- [ ] **Add Crashlytics + Analytics**
  - Effort: M · Stream: D · Source: audit-001 D (M3)

- [ ] **Add input allowlist sanitization** — enforce character restrictions and length limits on display names, room codes, passwords
  - Effort: S · Stream: A · Source: audit-003 B.6

- [ ] **Extract magic constants to a config file** — timing values (`780`, `'21:00'`), player-count thresholds, role ratios
  - Effort: S · Stream: B · Source: audit-003 B.7
  - Files: `lib/screens/game_screen.dart:L38-L55`, `lib/services/role_distribution.dart:L22-L36`

- [ ] **Performance profiling pass** — measure Firestore reads/writes per game session; profile widget rebuild frequency
  - Effort: M · Stream: C · Source: audit-001 D (M3)

---

## Milestone 4 — Growth (optional)
> Goal: social features, monetization, cross-platform.

- [ ] **Localization (TR + EN)** — extract all hardcoded Turkish strings to `.arb` files; add `flutter_localizations`
  - Effort: M · Source: audit-003 B.3

- [ ] **Social layer: friends / invites / deep links**
  - Effort: L · Source: audit-001 D (M4)

- [ ] **Cloud save + account linking (guest → full account)**
  - Effort: L · Source: audit-001 D (M4)

- [ ] **Monetization (cosmetics)**
  - Effort: L · Source: audit-001 D (M4)

- [ ] **iOS / Web / Desktop platform hardening**
  - Effort: L · Source: audit-001 D (M4)

---

## Open Questions (blocking decisions)

| # | Question | Blocks | Suggested Default |
|---|----------|--------|-------------------|
| Q1 | Cloud Functions vs Firestore Transactions for authority? | R2 race fix | Transactions first; Functions if abuse persists |
| Q2 | Same-room rematch or new room? | M1 restart task | Same room reset |
| Q3 | Android-only for v1? | M3 platform scope | Android-only |
| Q4 | `asik`/`manipulator` — ship at launch or hide? | R10 | Hide until implemented |
| Q5 | Guests earn gold/progression, or hide rewards entirely? | R17 | Hide for guests |
| Q6 | Nickname globally unique + immutable? | R14 | Unique + immutable for v1 |
| Q7 | Soft room close (flag) or hard delete? | R18 | Soft close + auto-return CTA |
| Q8 | Bots as real participants or dev-only tool? | bot gating | Dev-only behind `kDebugMode` |

---

_Last updated: 2026-02-22 · Source: audit-001 through audit-006_
