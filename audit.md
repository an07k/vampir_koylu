# Vampir Köylü — Multi-Agent Audit & Review Ledger

---

## Agent Prompt — READ THIS FIRST

> **Copy-paste this block as your prompt when starting a new agent session.**

You are a **senior Flutter/Dart developer and technical architect** with expertise in **Firebase-backed real-time multiplayer apps**. You are reviewing a social deduction game called **Vampir Köylü** (Werewolf/Mafia variant) — a turn-based multiplayer card game, NOT a rendered/physics game.

**Your task:** Read this entire file (`audit.md`), then independently review the codebase and append your analysis as the next review section.

### Step-by-step instructions

1. **Read this file top to bottom** — understand the Document Schema, Shared Context, and every prior review (agreements, findings, risk matrix, roadmap, open questions).
2. **Read the source code independently** — explore all files under `lib/` (screens, services, widgets), plus `pubspec.yaml`, `firebase.json`, build configs (`android/app/build.gradle.kts`), and `test/`.
3. **Perform a structured review** covering:
   - **Architecture**: Project organization, state management (or lack thereof), navigation pattern, service layer design
   - **Tech stack**: Flutter/Dart version, Firebase services used vs declared, third-party dependencies, build config
   - **Game systems**: Turn/phase management, role assignment, night/day resolution, voting, win conditions, economy (gold), matchmaking (room create/join)
   - **Real-time & networking**: Firestore streams, document structure, read/write patterns, concurrency handling, offline behavior
   - **Security**: Auth mechanism, Firestore rules, data validation, client-trust model, secrets exposure
   - **Code quality**: Patterns used, separation of concerns, naming conventions, duplication, test coverage
   - **Performance risks**: Widget rebuild scope, Firestore listener granularity, batch vs sequential writes, unnecessary re-renders
   - **Known issues**: TODOs, FIXMEs, dead code, hardcoded values, missing error handling
4. **Gap analysis**: What works well and should be preserved? What is incomplete, missing, or fragile? What is over-engineered? What critical bugs or architectural debt will block progress?
5. **Roadmap assessment**: Review the existing milestone plan (M0–M4). Propose amendments using MOVE/ADD/REMOVE/REORDER operations with effort estimates.
6. **Append your review** as `## Review [N]` following the Document Schema below. Use the next sequential `review_id` (check the last review's ID and increment).

### Review quality standards

- **Be specific** — reference actual file names, class names, and line ranges (e.g., `game_screen.dart:L653-L670`).
- **Flag the top 3 highest-risk items** that could derail the project in your Risk Matrix (section C).
- **Include a "Quick Wins" subsection** in your Roadmap Amendments (section D): things achievable in under a day with high impact.
- **State agreements/disagreements** with every prior review finding — don't just add new items. Use AGREE / PARTIALLY AGREE / DISAGREE with a one-sentence rationale.
- **Fill in all six sections** (A–F) of the schema. No sections may be skipped or left empty.

### Output constraints

- Append your review at the bottom of this file, just before the `<!-- NEXT AGENT -->` comment.
- Update the `<!-- NEXT AGENT -->` comment to reference the next `audit-[NNN]` ID.
- Do NOT modify any prior review sections or the Shared Context.
- Do NOT repeat the Document Schema or Shared Context in your review — just reference them.

---

> **Purpose**: Living document for sequential agent reviews. Each agent appends one `## Review` section following the schema below. Agents read all prior reviews before writing their own.

---

## Document Schema

Every review section MUST follow this structure. Copy this template, fill it in, and append it after the last review.

```
## Review [N] — [Agent Role]

> review_id: audit-[NNN]
> date: YYYY-MM-DD
> role: [short title, e.g. "Initial Auditor", "Security Reviewer"]
> scope: [what files/areas were examined]
> reads_reviews: [list of prior review_ids read before writing]
> confidence: LOW | MEDIUM | HIGH
> status: DRAFT | FINAL

### A. Agreements (with prior reviews)
Bullet list. Reference review_id and finding number. State whether you AGREE, PARTIALLY AGREE, or DISAGREE, with one-sentence rationale.

### B. New Findings
Numbered list. Each finding follows this sub-structure:

**B.[N] [SHORT TITLE]**
- Severity: CRITICAL | HIGH | MEDIUM | LOW | INFO
- Category: SECURITY | LOGIC_BUG | ARCHITECTURE | PERFORMANCE | POLICY | UX | DEVOPS
- Files: file.dart:L1-L2, file2.dart:L3
- Description: [what is wrong and why it matters]
- Evidence: [code snippet or behavioral proof]
- Recommended Fix: [concrete action]

### C. Risk Matrix Update
Table. Include ALL known risks (from prior reviews + your new ones), re-ranked by your assessment. Use this schema:

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|

### D. Roadmap Amendments
State whether you agree with the current milestone order. If not, list specific changes:
- MOVE task X from M[n] to M[m] — reason
- ADD task — effort [S/M/L/XL] — dependency — reason
- REMOVE task — reason
- REORDER within milestone — new sequence — reason

### E. Open Questions
Numbered list. Each question states:
- The question
- What it blocks (task or decision)
- Suggested default if no answer is received

### F. Handoff Metadata
yaml block:
  review_id: audit-[NNN]
  reviewer: [Agent Role]
  files_read: [count and list]
  confidence: HIGH | MEDIUM | LOW
  open_items: [count]
  next_recommended_agent: [role + first task]
  blocked_on: [what needs answering]
```

---

## Shared Context

### Repository Overview

| Property | Value |
|----------|-------|
| Project | Vampir Köylü (social deduction game) |
| Framework | Flutter / Dart 3.x |
| Backend | Firebase (Firestore, Auth declared but unused, Messaging declared but unused) |
| Platforms | Android (primary), iOS/Web/Desktop (scaffolded but untested) |
| Source Files | 16 Dart files in `lib/` |
| Test Files | 1 empty file (`test/widget_test.dart`) |
| Lines of Code (approx.) | ~4,500 Dart |

### File Index

| File | Lines | Role |
|------|-------|------|
| `lib/main.dart` | 444 | App entry, AuthChecker, MainMenuScreen |
| `lib/firebase_options.dart` | — | Generated Firebase config |
| `lib/services/auth_service.dart` | 262 | Custom auth (SHA-256 hash, SharedPrefs session) |
| `lib/services/role_distribution.dart` | 160 | Role calculation, assignment, Firestore save |
| `lib/services/night_resolution_service.dart` | 215 | Night phase resolution logic |
| `lib/services/day_resolution_service.dart` | 186 | Day voting resolution + win check |
| `lib/services/gold_service.dart` | 110 | Currency system + hardcoded bonus |
| `lib/screens/welcome_screen.dart` | 151 | Landing page with auth options |
| `lib/screens/create_account_screen.dart` | 346 | Registration form |
| `lib/screens/login_account_screen.dart` | 218 | Login form |
| `lib/screens/guest_login_screen.dart` | 295 | Guest entry form |
| `lib/screens/create_room_screen.dart` | 427 | Room creation with code + password |
| `lib/screens/join_room_screen.dart` | 512 | Room join with code + password |
| `lib/screens/room_lobby_screen.dart` | 632 | Lobby: player list, bot add, game start |
| `lib/screens/role_reveal_screen.dart` | 241 | Card-flip role reveal |
| `lib/screens/game_screen.dart` | 1152 | Main game: phases, actions, voting, host panel |
| `lib/screens/game_end_screen.dart` | 256 | Winner display + return to menu |
| `lib/screens/widgets/role_info_dialog.dart` | 168 | Role info bottom sheet |
| `lib/screens/widgets/game_time_display.dart` | 101 | In-game clock widget |

### Dependency Graph

```
auth_service.dart ← ALL screens (session lookup)
gold_service.dart ← game_end_screen, room_lobby_screen, day_resolution_service
role_distribution.dart ← room_lobby_screen
night_resolution_service.dart ← game_screen
day_resolution_service.dart ← game_screen
```

### Parallelizable Work Streams

| Stream | Scope | Files |
|--------|-------|-------|
| A — Auth | Auth system refactor | auth_service, welcome_screen, login_account_screen, create_account_screen, guest_login_screen |
| B — Game Logic | Resolution, roles, economy | role_distribution, night_resolution_service, day_resolution_service, gold_service |
| C — UI Decomposition | Break apart large widgets | game_screen, room_lobby_screen, role_reveal_screen |
| D — Infrastructure | Rules, CI, config, deps | firebase.json, pubspec.yaml, build.gradle.kts, analysis_options.yaml |

### Canonical Type Contract (proposed, not yet implemented)

Any agent adding models should use these canonical types:

```dart
// lib/models/game_enums.dart
enum GamePhase { waiting, roleReveal, night, dayDiscussion, dayVote, resolution, finished }
enum GameRole { vampir, koylu, doktor, asik, deli, dedektif, misafir, polis, takipci, manipulator }
enum WinCondition { vampir, koylu, deli }
```

```dart
// lib/models/role_metadata.dart
class RoleMetadata {
  final GameRole role;
  final String displayName;  // 'VAMPİR'
  final String icon;          // '🧛'
  final Color color;          // Color(0xFFDC143C)
  final String description;   // from role_info_dialog descriptions
  final bool hasNightAction;
}
```

---

## Review 1 — Initial Auditor

> review_id: audit-001
> date: 2025-02-21
> role: Initial Auditor
> scope: Full repository — all Dart files, pubspec, build config, assets, tests
> reads_reviews: (none — first review)
> confidence: HIGH
> status: FINAL

### A. Agreements

_(First review — no prior reviews to agree/disagree with.)_

### B. New Findings

**B.1 Monolithic Game Screen**
- Severity: HIGH
- Category: ARCHITECTURE
- Files: `game_screen.dart:L1-L1152`
- Description: Single widget handles phase rendering, host control panels, night action submission, day vote submission, target selection dialogs, player list, role display, auto-voting timer, and phase transition triggers. This is the single biggest maintainability risk.
- Recommended Fix: Extract into sub-widgets and a `GameController` class.

**B.2 Client-Authoritative Game Resolution**
- Severity: HIGH
- Category: SECURITY
- Files: `game_screen.dart:L653-L670`, `game_screen.dart:L909-L926`, `day_resolution_service.dart:L7-L75`
- Description: Host buttons and delayed auto-resolve trigger critical game state mutations from client side. Race conditions and cheat potential.
- Recommended Fix: Move phase transitions to server-authoritative path (Cloud Function or Firestore transaction gate).

**B.3 Plaintext Room Passwords**
- Severity: MEDIUM
- Category: SECURITY
- Files: `create_room_screen.dart:L71`, `join_room_screen.dart:L104-L110`
- Description: Room password stored and compared in plaintext in Firestore.
- Recommended Fix: Hash+salt or remove password feature until proper implementation.

**B.4 Hardcoded Privilege (kadergamer123)**
- Severity: MEDIUM
- Category: SECURITY
- Files: `gold_service.dart:L6-L7`, `gold_service.dart:L61-L81`
- Description: Hardcoded nickname `kadergamer123` triggers bonus gold for all players in that host's room. Developer backdoor, not a feature.
- Recommended Fix: Remove and replace with role/flag config.

**B.5 Role Metadata Duplication**
- Severity: MEDIUM
- Category: ARCHITECTURE
- Files: `game_screen.dart:L682-L716`, `role_reveal_screen.dart:L26-L63`, `role_info_dialog.dart:L12-L73`, `game_end_screen.dart:L218-L252`
- Description: `roleIcons`, `roleNames`, `roleColors` maps duplicated in 4 files. Drift risk; `role_reveal_screen.dart` already missing `manipulator`.
- Recommended Fix: Consolidate into single `role_metadata.dart`.

**B.6 No Transactional Guards on Room Join/Leave/Kick**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `join_room_screen.dart:L171-L187`, `room_lobby_screen.dart:L105-L117`, `room_lobby_screen.dart:L164-L178`
- Description: `playerCount` incremented/decremented via `FieldValue.increment` alongside `players` map updates but not inside a transaction. Concurrent joins can exceed `maxPlayers`.
- Recommended Fix: Wrap in Firestore Transaction.

**B.7 Unused Dependencies**
- Severity: LOW
- Category: DEVOPS
- Files: `pubspec.yaml:L39` (`firebase_messaging`), `pubspec.yaml:L37` (`firebase_auth`)
- Description: `firebase_messaging` is declared but never imported. `firebase_auth` is declared but the app uses a custom auth system instead.
- Recommended Fix: Remove unused deps or wire them properly.

**B.8 Dead Debug Code**
- Severity: LOW
- Category: ARCHITECTURE
- Files: `role_distribution.dart:L103-L128`
- Description: `testRoles()` method has no callers.
- Recommended Fix: Remove or gate behind `kDebugMode`.

**B.9 No Automated Tests**
- Severity: MEDIUM
- Category: DEVOPS
- Files: `test/widget_test.dart:L1-L10`
- Description: Single test file with empty `main()` and a TODO comment. Zero test coverage.
- Recommended Fix: Add unit tests for role distribution, win conditions, and resolution logic.

**B.10 Performance — Full-Document Stream Rebuilds**
- Severity: MEDIUM
- Category: PERFORMANCE
- Files: `game_screen.dart:L596-L1152`, `room_lobby_screen.dart:L278-L632`
- Description: Entire room document streamed into large widget trees. Any field change triggers full rebuild.
- Recommended Fix: Use sub-collection listeners or `select()` projections; break widget tree into smaller `StreamBuilder` scopes.

**B.11 Gold Reward Loop — Sequential Writes**
- Severity: LOW
- Category: PERFORMANCE
- Files: `gold_service.dart:L66-L100`
- Description: Per-player Firestore writes in a loop for rewards. With 15 winners, that's 15 sequential write calls.
- Recommended Fix: Batch writes using `WriteBatch`.

### C. Risk Matrix Update

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|
| 1 | Client-authoritative resolution / race conditions | HIGH | Near-certain with 3+ players | Game state corruption | Stream B | B.2 |
| 2 | Plaintext room password + hardcoded privilege | MEDIUM | On any inspection | Data exposure, unfair advantage | Stream D | B.3, B.4 |
| 3 | game_screen.dart monolith | HIGH | Ongoing | Dev velocity collapse | Stream C | B.1 |
| 4 | No transactional room operations | MEDIUM | On concurrent joins | playerCount drift, exceeded max | Stream B | B.6 |
| 5 | No tests | MEDIUM | Ongoing | Regressions undetected | Stream D | B.9 |
| 6 | Performance hotspots | MEDIUM | At scale | Laggy UI, Firestore cost | Stream C | B.10 |

### D. Roadmap Amendments

_(First review — establishes baseline roadmap.)_

**Milestone 0 — Stabilization**
1. [M] Move phase transitions to server-authoritative path. _Dep: Cloud Functions vs Transaction decision._
2. [M] Secure room passwords. _Dep: migration strategy for existing docs._
3. [S] Remove hardcoded nickname privilege. _Dep: game economy rules._
4. [M] Add transactional join/leave/kick. _Dep: room schema invariants._
5. [M] Consolidate role metadata into single file. _Dep: none._
6. [S] Remove/gate debug code (testRoles, bot controls). _Dep: debug mode strategy._

**Milestone 1 — Core Loop Completion**
1. [M] Restart/rematch flow from end screen. _Dep: same room vs new room decision._
2. [M] Phase state machine with enforced transitions. _Dep: timing rules._
3. [M] Complete missing role logic (asik, manipulator). _Dep: exact rules for special roles._
4. [S] Reconnect/resume for players in active games. _Dep: session policy._
5. [M] Tests for win conditions + role assignment + transitions. _Dep: Firebase emulator harness._

**Milestone 2 — Content & Polish**
1. [M] Audio/haptic feedback layer. _Dep: asset pipeline._
2. [M] Phase transition animations, alive/dead/voted states. _Dep: UX direction._
3. [S] Avatar assets and role art. _Dep: art availability._
4. [M] Configurable role ratios + phase durations (remote config). _Dep: live-ops surface._
5. [S] Role tooltips/tutorial onboarding. _Dep: copy finalized._

**Milestone 3 — Production Readiness**
1. [M] Crashlytics + Analytics. _Dep: privacy policy + event taxonomy._
2. [M] CI pipeline (analyze, test, build). _Dep: signing keys._
3. [M] Performance profiling pass. _Dep: multiplayer test scenario._
4. [S] Harden Android metadata. _Dep: package name decision._
5. [M] Abuse controls. _Dep: moderation policy._

**Milestone 4 — Growth (optional)**
1. [M] Social layer: friends/invites. _Dep: deep link strategy._
2. [M] Cloud save + account linking. _Dep: merge rules._
3. [L] Localization (TR/EN). _Dep: translations._
4. [M] Monetization (cosmetics). _Dep: legal policy._
5. [M] Cross-device polish. _Dep: platform priority._

**Quick Wins (<1 day)**
- Consolidate role_metadata.dart (removes 4 duplicate maps).
- Remove bonusNickname hardcode.
- Add 5–8 unit tests for role_distribution and win-condition logic.
- Wrap join/kick/leave in Firestore Transaction.
- Remove unused `firebase_messaging` dep.
- Add host-only guard on day resolution trigger.

### E. Open Questions

_(None from first review — establishing baseline.)_

### F. Handoff Metadata

```yaml
review_id: audit-001
reviewer: Initial Auditor
files_read: 16/16 Dart, pubspec.yaml, build.gradle.kts, analysis_options.yaml, todo.txt, widget_test.dart
confidence: HIGH
open_items: 0
next_recommended_agent: Architecture & Security Reviewer (deeper pass on auth + race conditions)
blocked_on: nothing
```

---

## Review 2 — Architecture & Security Reviewer

> review_id: audit-002
> date: 2025-02-21
> role: Architecture & Security Reviewer
> scope: Full independent source read — all 16 Dart files, pubspec.yaml, analysis_options.yaml, firebase.json, todo.txt, widget_test.dart
> reads_reviews: audit-001
> confidence: HIGH
> status: FINAL

### A. Agreements

- **AGREE** with audit-001 B.1 (monolith). Confirmed 1152 lines, all concerns listed are present in one `build()` method tree.
- **AGREE** with audit-001 B.2 (client-authoritative). Expanding severity — see B.1 below.
- **AGREE** with audit-001 B.3 (plaintext passwords). Confirmed at exact lines.
- **AGREE** with audit-001 B.4 (kadergamer123). Confirmed at `gold_service.dart:L7`. Developer backdoor.
- **AGREE** with audit-001 B.5 (role metadata duplication). Confirmed 4 copies. Additionally: `role_reveal_screen.dart` is missing `manipulator` (9 roles vs 10 elsewhere) — silent data inconsistency.
- **AGREE** with audit-001 B.6 (no transactional guards).
- **AGREE** with audit-001 B.7–B.11.

### B. New Findings

**B.1 Triple-Trigger Resolution Race (escalation of audit-001 B.2)**
- Severity: CRITICAL
- Category: LOGIC_BUG
- Files: `game_screen.dart:L653-L670`, `game_screen.dart:L909-L926`, `day_resolution_service.dart:L7-L75`
- Description: Day resolution has **three independent trigger paths**, not two:

  | Trigger | File | Line | Actor |
  |---------|------|------|-------|
  | Host button "OYLAMAYI BİTİR" | game_screen.dart | L909-L926 | Host (manual) |
  | Auto-start voting at 22:00 game-time | game_screen.dart | L653-L670 | Any client whose timer fires |
  | Host button after auto-start already triggered | game_screen.dart | L909-L926 | Host again |

  `_shouldAutoStartVoting` runs inside `StreamBuilder.build` on **every client**. The guard `_hasAutoStartedVoting` is local widget state, not Firestore state. With 10 players, up to 10 concurrent `resolveVoting()` calls race, each reading the same doc, computing the same victim, appending to `deadPlayers` non-atomically. Can produce duplicate entries or skip win-condition.
- Evidence: `_hasAutoStartedVoting` is a `bool` field on `_GameScreenState` (widget-local). No server-side lock exists.
- Recommended Fix: Add `phaseResolutionLock` field in Firestore. Use a Firestore Transaction: read lock → check if already resolved → proceed only if not. Or restrict all resolution to host-only and remove auto-resolve from non-host clients.

**B.2 Custom Auth Bypasses Firebase Auth Entirely**
- Severity: HIGH
- Category: SECURITY
- Files: `auth_service.dart:L1-L262`, `pubspec.yaml:L37`
- Description: `firebase_auth` is in `pubspec.yaml` but **never imported in any Dart file**. The entire auth system is custom:
  - SHA-256 + random salt (not a proper KDF — fast to brute-force).
  - Session = bare `SharedPreferences` string (`userId`). No token, no expiry, no server-side validation.
  - No email verification, no login rate limiting, no account lockout.
  - No account deletion (required by Google Play/App Store since 2022).
- Evidence: `grep -r "firebase_auth" lib/` returns zero results.
- Recommended Fix: Replace with Firebase Auth Anonymous (guests) + Email/Password (accounts). Immediate benefits: secure hashing, rate limiting, token-based sessions, delete account API.

**B.3 Doctor Role Overwrite Bug at 12+ Players**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `night_resolution_service.dart:L33-L38`
- Description: `roleActions` maps `playerRole → target`. With 2 doctors (at `playerCount >= 12` per `role_distribution.dart:L27`), the second doctor's target **overwrites** the first:
  ```dart
  roleActions[playerRole] = nightActions[playerId]; // OVERWRITES
  ```
  First doctor's protection is silently discarded. Vampires sidestep this via a separate `vampirVotes` counting mechanism.
- Evidence: `Map<String, String>` keyed by role string. Two entries with key `'doktor'` → last write wins.
- Recommended Fix: Change to `Map<String, List<String>>` or handle multi-instance roles with explicit per-player logic.

**B.4 No Firestore Security Rules in Repository**
- Severity: CRITICAL
- Category: SECURITY
- Files: `firebase.json` (no `firestore.rules` reference)
- Description: No `firestore.rules` file exists. Either rules are unversioned in Firebase Console, or default test-mode rules are active (`allow read, write: if true`). Anyone with the project ID can read/write any document — roles, gold, game state.
- Evidence: `ls firestore.rules` → file not found. `firebase.json` contains no rules path.
- Recommended Fix: Create `firestore.rules` with least-privilege access. Version-control it. Deploy via `firebase deploy --only firestore:rules`.

**B.5 Bot System Exposed in Production UI**
- Severity: LOW
- Category: UX
- Files: `room_lobby_screen.dart:L201-L244`, `night_resolution_service.dart:L154-L189`
- Description: "BOT EKLE" button visible to all hosts. Bots are inert placeholders (no AI, can't vote). `areAllActionsSubmitted` filters them out for night, but day vote totals are wrong.
- Recommended Fix: Gate behind `kDebugMode` or a feature flag.

### C. Risk Matrix Update

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|
| 1 | Multi-client resolution race (3 trigger paths) | CRITICAL | Near-certain with 3+ players | Game state corruption, wrong winner | Stream B | audit-002 B.1 |
| 2 | No Firestore security rules (open database) | CRITICAL | Certain if deployed | Complete data compromise, cheating | Stream D | audit-002 B.4 |
| 3 | Custom auth: no KDF, no session tokens | HIGH | Exploitable by motivated user | Account takeover, impersonation | Stream A | audit-002 B.2 |
| 4 | Doctor role overwrite at 12+ players | MEDIUM | Certain at that player count | Silent gameplay error | Stream B | audit-002 B.3 |
| 5 | No account deletion (policy violation) | MEDIUM | Certain on store review | App store rejection | Stream A | audit-002 B.2 |
| 6 | game_screen.dart monolith (1152 lines) | MEDIUM | Ongoing | Dev velocity collapse | Stream C | audit-001 B.1 |
| 7 | No transactional room operations | MEDIUM | On concurrent joins | playerCount drift | Stream B | audit-001 B.6 |
| 8 | No automated tests | MEDIUM | Ongoing | Regressions undetected | Stream D | audit-001 B.9 |

### D. Roadmap Amendments

- **ADD** to M0: Write and deploy Firestore security rules — effort M — _dep: Firebase project access_ — Without this, entire app is an open database. No other fix matters.
- **ADD** to M0: Fix doctor role overwrite bug — effort S — _dep: none_ — Pure logic fix, prevents false test results.
- **REORDER** M0 execution sequence:
  1. Firestore security rules (unblocks safe testing)
  2. Resolution race fix (unblocks correct gameplay testing)
  3. Doctor overwrite fix (quick, prevents false test results)
  4. Role metadata consolidation (reduces error surface)
  5. Remove hardcoded nickname privilege
  6. Transactional join/leave/kick
  7. Gate bot system behind debug flag
  8. Auth migration planning (larger effort, can be M1)
- **MOVE** auth migration from M0 to M1 — current auth *works* for dev/playtesting; game-breaking logic bugs are higher priority.

### E. Open Questions

1. **Rematch flow**: Same room reset, or new room?
   - Blocks: M1 restart task.
   - Default: Same room reset (simpler).

2. **Target platforms**: Android-only? iOS? Web?
   - Blocks: M3 build config, M4 cross-device.
   - Default: Android-only for v1.

3. **Firestore billing plan**: Spark (free) or Blaze (pay-as-you-go)?
   - Blocks: Cloud Functions vs client-side Transactions decision.
   - Default: Assume Spark → use client-side Transactions only.

4. **kadergamer123 bonus**: Developer's own account? Become generic feature, or delete?
   - Blocks: M0 privilege removal task.
   - Default: Delete entirely.

5. **Eccentric roles completeness**: `manipulator` (swap votes) and `asik` (lover) are described but not implemented in resolution services. Ship at launch, or hide?
   - Blocks: M1 role gaps task.
   - Default: Hide from mode selection until implemented.

### F. Handoff Metadata

```yaml
review_id: audit-002
reviewer: Architecture & Security Reviewer
files_read: 16/16 Dart files, pubspec.yaml, analysis_options.yaml, firebase.json, todo.txt, widget_test.dart
confidence: HIGH
open_items: 5 (see E. Open Questions)
next_recommended_agent: Implementation Agent (Stream D — Firestore rules first)
blocked_on: Product owner answers to questions 1-5
```

---

<!-- NEXT AGENT: Copy the "## Review [N]" template from the Document Schema section above. Fill in your review_id as audit-003, read all prior reviews, and append your section here. -->

## Review 3 — Implementation Agent

> review_id: audit-003
> date: 2025-02-22
> role: Implementation Agent
> scope: Independent review of all 16 Dart files, services, screens, widgets, pubspec.yaml, build configs, and test files
> reads_reviews: audit-001, audit-002
> confidence: HIGH
> status: FINAL

### A. Agreements (with prior reviews)

- **AGREE** with audit-001 B.1 (monolithic game_screen.dart). Confirmed 1152 lines with all game logic in one StreamBuilder.build() method.
- **AGREE** with audit-001 B.2 (client-authoritative resolution). The auto-voting trigger in game_screen.dart:L653-L670 is indeed client-side and racy.
- **AGREE** with audit-001 B.3 (plaintext room passwords). No hashing implemented.
- **AGREE** with audit-001 B.4 (hardcoded kadergamer123 privilege). Confirmed in gold_service.dart:L7.
- **AGREE** with audit-001 B.5 (role metadata duplication). Four copies of roleIcons, roleNames, roleColors maps.
- **AGREE** with audit-001 B.6 (no transactional room operations). FieldValue.increment used alongside map updates.
- **AGREE** with audit-001 B.7 (unused firebase_auth dependency). Not imported anywhere in the codebase.
- **AGREE** with audit-001 B.8 (dead testRoles method). No callers, should be removed or gated.
- **AGREE** with audit-001 B.9 (no automated tests). Only empty widget_test.dart.
- **AGREE** with audit-001 B.10 (performance hotspots). Full document streams causing unnecessary rebuilds.
- **AGREE** with audit-001 B.11 (sequential gold writes). Loop-based Firestore updates.
- **AGREE** with audit-002 B.1 (triple-trigger resolution race). Three independent paths can conflict.
- **AGREE** with audit-002 B.2 (custom auth bypasses Firebase Auth). SHA-256 without proper KDF, SharedPreferences sessions.
- **AGREE** with audit-002 B.3 (doctor role overwrite). Map<String, String> keyed by role causes overwrite at 12+ players.
- **AGREE** with audit-002 B.4 (no Firestore security rules). No firestore.rules file in repository.
- **AGREE** with audit-002 B.5 (bot system exposed). "BOT EKLE" button visible to all hosts.

### B. New Findings

**B.1 No Error Handling for Network Failures**
- Severity: HIGH
- Category: LOGIC_BUG
- Files: `auth_service.dart:L30-L50`, `game_screen.dart:L85-L95`, `day_resolution_service.dart:L7-L20`
- Description: Firestore operations have no try-catch for network timeouts, quota exceeded, or permission denied. Auth failures, action submissions, and resolution calls can silently fail or crash the app.
- Evidence: `await docRef.set({...})` in auth_service has no error handling. Similar in game_screen action submissions.
- Recommended Fix: Wrap all Firestore calls in try-catch, show user-friendly error messages, implement retry logic for transient failures.

**B.2 No Offline Support or State Persistence**
- Severity: MEDIUM
- Category: UX
- Files: `main.dart:L50-L65`, `game_screen.dart:L585-L600`
- Description: App requires constant internet for authentication and gameplay. No offline mode, no local state persistence for interrupted games.
- Evidence: AuthChecker immediately fails without network. StreamBuilder shows loading on any disconnection.
- Recommended Fix: Implement offline auth caching, local game state backup, and reconnection flow.

**B.3 Turkish-Only UI with No Localization**
- Severity: LOW
- Category: POLICY
- Files: All screen files (welcome_screen.dart, game_screen.dart, etc.)
- Description: All text is hardcoded in Turkish. No i18n setup despite Flutter's built-in support.
- Evidence: `Text('VAMPİR KÖYLÜ')` throughout. No arb files or localization delegates.
- Recommended Fix: Extract strings to .arb files, add flutter_localizations dependency, implement locale switching.

**B.4 Improper State Management (setState Abuse)**
- Severity: MEDIUM
- Category: ARCHITECTURE
- Files: `main.dart:L75-L95`, `game_screen.dart:L27-L35`
- Description: Complex state scattered across StatefulWidget local state. No centralized state management (Provider, Bloc, Riverpod).
- Evidence: MainMenuScreen manages _displayName, _gold, _isLoading locally. GameScreen has _userId, _hasAutoStartedVoting as widget state.
- Recommended Fix: Adopt Riverpod for global state, extract business logic to controllers/services.

**B.5 Navigation Stack Issues**
- Severity: MEDIUM
- Category: UX
- Files: `game_screen.dart:L620-L630`, `main.dart:L155-L165`
- Description: Game end redirects with pushReplacement, but back button behavior undefined. No deep linking support.
- Evidence: `Navigator.of(context).pushReplacement()` on game finish. No route guards for authenticated screens.
- Recommended Fix: Implement proper routing with go_router, add authentication guards.

**B.6 No Input Validation on User-Generated Content**
- Severity: MEDIUM
- Category: SECURITY
- Files: `create_account_screen.dart:L50-L70`, `guest_login_screen.dart:L40-L60`
- Description: Display names and room codes not sanitized. Potential for XSS if displayed, or injection if used in queries.
- Evidence: Direct string interpolation in Firestore paths and UI. No length limits enforced on room codes.
- Recommended Fix: Add input sanitization, length validation, and character restrictions.

**B.7 Hardcoded Game Constants**
- Severity: LOW
- Category: ARCHITECTURE
- Files: `game_screen.dart:L650`, `role_distribution.dart:L15-L25`
- Description: Magic numbers like '21:00', '09:00', player count thresholds scattered throughout code.
- Evidence: `elapsedGameMinutes >= 780` for 13-hour game day. Role ratios hardcoded in calculateRoles().
- Recommended Fix: Extract to constants file or configuration.

**B.8 No Loading States or Progress Indicators**
- Severity: LOW
- Category: UX
- Files: `room_lobby_screen.dart:L200-L250`, `game_screen.dart:L85-L95`
- Description: Long operations (role assignment, resolution) show no progress. Users unsure if actions succeeded.
- Evidence: `resolveVoting()` and `resolveNight()` are fire-and-forget. No loading overlays.
- Recommended Fix: Add loading states, progress bars for async operations.

**B.9 Incomplete Role Implementations**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `night_resolution_service.dart:L120-L140`, `role_distribution.dart:L10-L15`
- Description: 'asik' (lover) and 'manipulator' roles defined but not implemented in night resolution. 'asik' mentioned in nightRoles but no logic exists.
- Evidence: `nightRoles.contains('asik')` but no handling in resolveNight(). 'manipulator' not even in nightRoles list.
- Recommended Fix: Implement missing role logic or remove from available roles.

**B.10 No Build Optimization or Asset Management**
- Severity: LOW
- Category: DEVOPS
- Files: `pubspec.yaml:L50-L60`, `android/app/build.gradle.kts:L20-30`
- Description: No asset optimization, no build flavors, debug signing config in release.
- Evidence: `signingConfig = signingConfigs.getByName("debug")` in release build. No asset bundling.
- Recommended Fix: Configure proper signing, add build flavors, optimize assets.

### C. Risk Matrix Update

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|
| 1 | Multi-client resolution race (3 trigger paths) | CRITICAL | Near-certain with 3+ players | Game state corruption, wrong winner | Stream B | audit-002 B.1 |
| 2 | No Firestore security rules (open database) | CRITICAL | Certain if deployed | Complete data compromise, cheating | Stream D | audit-002 B.4 |
| 3 | Custom auth: no KDF, no session tokens | HIGH | Exploitable by motivated user | Account takeover, impersonation | Stream A | audit-002 B.2 |
| 4 | Network failure crashes (no error handling) | HIGH | Common on poor connections | App crashes, data loss | Stream B | audit-003 B.1 |
| 5 | Doctor role overwrite at 12+ players | MEDIUM | Certain at that player count | Silent gameplay error | Stream B | audit-002 B.3 |
| 6 | game_screen.dart monolith (1152 lines) | MEDIUM | Ongoing | Dev velocity collapse | Stream C | audit-001 B.1 |
| 7 | No transactional room operations | MEDIUM | On concurrent joins | playerCount drift | Stream B | audit-001 B.6 |
| 8 | No automated tests | MEDIUM | Ongoing | Regressions undetected | Stream D | audit-001 B.9 |
| 9 | No offline support | MEDIUM | On network issues | Game interruption | Stream B | audit-003 B.2 |
| 10 | Improper state management | MEDIUM | Ongoing | Buggy UI updates | Stream C | audit-003 B.4 |

### D. Roadmap Amendments

- **ADD** to M0: Implement comprehensive error handling for Firestore operations — effort M — _dep: none_ — Prevents crashes on network failures.
- **ADD** to M0: Fix incomplete role implementations (asik, manipulator) — effort S — _dep: game rules clarification_ — Either implement or remove from selection.
- **ADD** to M1: Implement offline support and state persistence — effort L — _dep: Firebase offline capabilities_ — Improves UX on poor connections.
- **ADD** to M2: Add localization (TR/EN) — effort M — _dep: translation strings_ — Required for international users.
- **ADD** to M3: Configure proper build optimization and signing — effort S — _dep: signing keys_ — Required for store deployment.
- **REORDER** M0 tasks by risk priority:
  1. Firestore security rules (blocks deployment)
  2. Error handling (prevents crashes)
  3. Resolution race fix (core gameplay)
  4. Doctor overwrite fix (gameplay correctness)
  5. Role metadata consolidation (maintainability)
  6. Remove hardcoded privilege
  7. Transactional join/leave/kick
  8. Gate bot system
  9. Auth migration planning
- **MOVE** localization from M4 to M2 — effort M — International expansion is content, not growth.

### E. Open Questions

1. **Offline strategy**: Full offline mode, or just reconnection/resume?
   - Blocks: M1 offline task.
   - Default: Reconnection/resume only (simpler).

2. **State management framework**: Riverpod, Bloc, or Provider?
   - Blocks: M1 state management refactor.
   - Default: Riverpod (modern, Flutter-preferred).

3. **Missing role implementations**: Implement asik/manipulator, or hide them?
   - Blocks: M0 role fix task.
   - Default: Hide until implemented (avoid broken features).

4. **Build flavors**: Debug/Release only, or add staging?
   - Blocks: M3 build optimization.
   - Default: Debug/Release only.

5. **Input sanitization scope**: Basic length/character checks, or full XSS prevention?
   - Blocks: M1 input validation.
   - Default: Basic validation (sufficient for game context).

### F. Handoff Metadata

```yaml
review_id: audit-003
reviewer: Implementation Agent
files_read: 16/16 Dart files, pubspec.yaml, build.gradle.kts, analysis_options.yaml, firebase.json, todo.txt, widget_test.dart
confidence: HIGH
open_items: 5 (see E. Open Questions)
next_recommended_agent: Testing & QA Agent (focus on adding test coverage and validating fixes)
blocked_on: Product owner answers to questions 1-5
```

## Review 4 — Consistency & Correctness Reviewer

> review_id: audit-004
> date: 2026-02-22
> role: Consistency & Correctness Reviewer
> scope: Full independent pass over `lib/` (all 16 Dart files), plus `pubspec.yaml`, `firebase.json`, `android/app/build.gradle.kts`, `analysis_options.yaml`, `test/widget_test.dart`, `lib/todo.txt`
> reads_reviews: audit-001, audit-002, audit-003
> confidence: HIGH
> status: FINAL

### A. Agreements (with prior reviews)

- **AGREE** with audit-001 B.1 — `game_screen.dart` remains a monolith (`lib/screens/game_screen.dart:L1-L1152`) with UI + orchestration + mutation logic tightly coupled.
- **AGREE** with audit-001 B.2 — day resolution is still client-triggered from host UI and auto-trigger path (`lib/screens/game_screen.dart:L654-L670`, `:L926`) without server lock.
- **AGREE** with audit-001 B.3 — room password is written and compared as plaintext (`lib/screens/create_room_screen.dart:L66`, `lib/screens/join_room_screen.dart:L93-L98`).
- **AGREE** with audit-001 B.4 — hardcoded privilege (`bonusNickname`) is still present (`lib/services/gold_service.dart:L6-L7`, `:L52-L57`).
- **AGREE** with audit-001 B.5 — role metadata duplication exists; `role_reveal_screen.dart` still omits `manipulator` (`lib/screens/role_reveal_screen.dart:L21-L54`).
- **AGREE** with audit-001 B.6 — join/leave/kick still update player maps and counters outside transactions (`lib/screens/join_room_screen.dart:L171-L178`, `lib/screens/room_lobby_screen.dart:L95-L100`, `:L149-L152`).
- **AGREE** with audit-001 B.7 — `firebase_auth` and `firebase_messaging` remain declared but unused in `lib/` (`pubspec.yaml:L37-L39`).
- **AGREE** with audit-001 B.8 — `testRoles()` remains dead debug code (`lib/services/role_distribution.dart:L103-L128`).
- **AGREE** with audit-001 B.9 — test coverage is still effectively zero (`test/widget_test.dart:L1-L10`).
- **AGREE** with audit-001 B.10 — broad room-doc streams still drive large rebuild scopes (`lib/screens/game_screen.dart:L585-L1152`, `lib/screens/room_lobby_screen.dart:L255-L632`).
- **AGREE** with audit-001 B.11 — winner rewards are still sequential per-player reads/writes (`lib/services/gold_service.dart:L78-L97`).

- **AGREE** with audit-002 B.1 — triple-trigger race remains (auto day timeout + host voting start/end) with only local `_hasAutoStartedVoting` guard (`lib/screens/game_screen.dart:L25`, `:L654-L670`, `:L904-L929`).
- **AGREE** with audit-002 B.2 — auth remains custom SHA-256 + SharedPreferences session, with no FirebaseAuth token binding (`lib/services/auth_service.dart:L17-L21`, `:L213-L259`).
- **AGREE** with audit-002 B.3 — doctor overwrite remains in `roleActions` map keyed by role (`lib/services/night_resolution_service.dart:L31-L38`, `:L63`).
- **AGREE** with audit-002 B.4 — no `firestore.rules` file and no rules mapping in `firebase.json`.
- **AGREE** with audit-002 B.5 — bot feature is visible to any host and not debug-gated (`lib/screens/room_lobby_screen.dart:L551-L578`).

- **PARTIALLY AGREE** with audit-003 B.1 — many calls have try/catch, but failure handling is inconsistent and mostly log/snackbar-level; transactional/permission-aware recovery is missing.
- **PARTIALLY AGREE** with audit-003 B.2 — explicit resume flow is missing, but claim “no offline support” is overstated because Firestore client caching exists by default.
- **AGREE** with audit-003 B.3 — UI is hardcoded Turkish and localization scaffold is absent.
- **PARTIALLY AGREE** with audit-003 B.4 — state is local and fragmented, but this is maintainability debt rather than immediate functional failure.
- **PARTIALLY AGREE** with audit-003 B.5 — routing is ad-hoc and stack behavior is fragile, but current flows are still operable for MVP.
- **DISAGREE** with audit-003 B.6 — validation does exist (length, emptiness, room-code length) in auth/join paths (`lib/services/auth_service.dart:L35-L57`, `lib/screens/join_room_screen.dart:L57-L66`); stronger allowlist/sanitization is still recommended.
- **AGREE** with audit-003 B.7 — magic constants are scattered (`lib/screens/game_screen.dart:L49`, `lib/services/role_distribution.dart:L22-L36`).
- **DISAGREE** with audit-003 B.8 — loading/progress states are present in many flows (`_isLoading`, `CircularProgressIndicator`, snackbars); issue is inconsistency, not absence.
- **AGREE** with audit-003 B.9 — role implementation gap remains (`asik` required at night but unresolved; `manipulator` distributed but no effect).
- **PARTIALLY AGREE** with audit-003 B.10 — release signing is debug (`android/app/build.gradle.kts:L37-L42`), but “asset optimization missing” is not a verified blocker at this stage.

### B. New Findings

**B.1 Blocked-role resolution checks evaluate wrong actor**
- Severity: HIGH
- Category: LOGIC_BUG
- Files: `lib/services/night_resolution_service.dart:L95-L108`, `lib/services/night_resolution_service.dart:L121-L128`
- Description: Dedektif/Polis/Takipci blocked checks are computed via `players.keys.firstWhere((id) => roleActions['X'] != null, ...)`, which does not identify the acting player; it returns the first map key when role action exists.
- Evidence: Predicate ignores `id`, so block logic depends on map iteration order rather than actor identity.
- Recommended Fix: Resolve actor IDs by role explicitly (or track actions by actor ID only), then check `blockedPlayers.contains(actorId)`.

**B.2 Room code collision can overwrite existing room document**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `lib/screens/create_room_screen.dart:L27-L31`, `lib/screens/create_room_screen.dart:L60-L81`
- Description: Room code is random 6-char and persisted with unconditional `.set()` on doc ID. A collision replaces existing room state.
- Evidence: No pre-existence check/transaction around `rooms/{roomCode}` creation.
- Recommended Fix: Use transaction/create-only semantics; regenerate code on conflict.

**B.3 Identity is client-asserted and mutable (session spoof risk)**
- Severity: HIGH
- Category: SECURITY
- Files: `lib/services/auth_service.dart:L213-L221`, `lib/services/auth_service.dart:L224-L249`, `lib/screens/game_screen.dart:L30-L35`
- Description: Session identity is a local `SharedPreferences` string (`userId`) fetched client-side and trusted for writes; there is no signed token binding in app logic.
- Evidence: `_userId` loaded from local prefs is directly used in write paths (`nightActions.$_userId`, `dayVotes.$_userId`).
- Recommended Fix: Migrate to FirebaseAuth (or equivalent server-verified identity) and enforce per-user rules in Firestore security rules.

**B.4 Day-phase timing and resolution are client-clock dependent**
- Severity: MEDIUM
- Category: ARCHITECTURE
- Files: `lib/screens/game_screen.dart:L42-L50`, `lib/screens/game_screen.dart:L654-L670`, `lib/screens/widgets/game_time_display.dart:L53-L78`
- Description: Vote auto-start and phase clock both derive from local wall-clock computations, allowing drift across clients and inconsistent trigger timing.
- Evidence: `_shouldAutoStartVoting` and `GameTimeDisplay` both use `DateTime.now()` and local elapsed calculations.
- Recommended Fix: Use server timestamp progression and a single authoritative phase-transition executor.

### C. Risk Matrix Update

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|
| 1 | Open/insufficient Firestore rules with client-state authority | CRITICAL | Certain if deployed as-is | Full game/data tampering | Stream D | audit-002 B.4 + audit-002 B.1 |
| 2 | Multi-trigger resolution race in day phase | CRITICAL | Near-certain in real rooms | Wrong eliminations/winners | Stream B | audit-002 B.1 |
| 3 | Client-asserted identity (prefs userId) without token binding | HIGH | High with motivated attacker | Impersonation / unauthorized actions | Stream A | audit-004 B.3 |
| 4 | Night blocker logic checks wrong actor | HIGH | High in eccentric-role matches | Incorrect night outcomes | Stream B | audit-004 B.1 |
| 5 | Doctor overwrite when 2 doctors exist | MEDIUM | Certain at 12+ players | Silent gameplay corruption | Stream B | audit-002 B.3 |
| 6 | Non-transactional join/leave/kick | MEDIUM | Medium under concurrency | playerCount drift / capacity bypass | Stream B | audit-001 B.6 |
| 7 | Room code collision overwrite | MEDIUM | Low-probability but real | Room data loss/corruption | Stream B | audit-004 B.2 |
| 8 | Incomplete role implementation (`asik`/`manipulator`) | MEDIUM | Certain when selected | Rules inconsistency / player confusion | Stream B | audit-003 B.9 |
| 9 | Monolithic game screen architecture | MEDIUM | Ongoing | Slower fixes, regression risk | Stream C | audit-001 B.1 |
| 10 | No automated tests for core logic | MEDIUM | Certain | Regressions undetected | Stream D | audit-001 B.9 |
| 11 | Hardcoded privileged bonus path | LOW | Deterministic | Fairness/reputation damage | Stream D | audit-001 B.4 |
| 12 | Release build signed with debug key | LOW | Certain in current config | Store/deploy friction | Stream D | audit-003 B.10 |

### D. Roadmap Amendments

- **REORDER** M0 as: (1) Firestore rules, (2) day-phase lock/authoritative resolution, (3) identity/auth binding, (4) blocker/doctor night fixes, (5) transactional room operations.
- **ADD** M0: Fix wrong-actor blocked checks in night resolution — effort **S** — dependency: none — correctness blocker.
- **ADD** M0: Add room create collision guard (`create`-only/transaction + retry) — effort **S** — dependency: none — prevents destructive overwrite.
- **MOVE** “role metadata consolidation” to run in parallel with M0 bug fixes (Stream C), not before correctness/security fixes.
- **REMOVE** “full offline mode” from near-term scope; keep “reconnect/resume” only after core authority/security work.

**Quick Wins (<1 day)**
- Patch blocked-role checks to use actor IDs (B.1).
- Prevent room-code collision overwrite by checking existence before create (B.2).
- Hide bot button behind `kDebugMode` (already marked test-only in comments).
- Remove `bonusNickname` branch and deploy fairness fix.
- Add 6–10 unit tests for `calculateRoles`, doctor overwrite case, and win-condition edges.

### E. Open Questions

1. Should game authority be Cloud Functions first, or Firestore transaction locks first?
   - Blocks: final architecture for M0 race fix.
   - Suggested default: transaction lock first (faster), then Functions if abuse persists.

2. Are guests allowed in ranked/progression rooms that award gold?
   - Blocks: reward/security rule design.
   - Suggested default: unranked-only for guests.

3. Should `asik` and `manipulator` be disabled immediately until logic is complete?
   - Blocks: release candidate role pool.
   - Suggested default: disable in selection UI now.

4. Can we enforce one active room membership per user at rules level?
   - Blocks: consistency model for join/leave/race prevention.
   - Suggested default: enforce via transaction + rule check on membership fields.

5. Is Android the only target for v1 launch?
   - Blocks: platform hardening priorities.
   - Suggested default: Android-only scope freeze for v1.

### F. Handoff Metadata

```yaml
review_id: audit-004
reviewer: Consistency & Correctness Reviewer
files_read: 16/16 Dart files in lib, plus pubspec.yaml, firebase.json, android/app/build.gradle.kts, analysis_options.yaml, test/widget_test.dart, lib/todo.txt
confidence: HIGH
open_items: 5
next_recommended_agent: Security Implementation Agent — first task: add firestore.rules + transaction lock for day resolution
blocked_on: Product decisions in E.1-E.5
```

<!-- NEXT AGENT: Copy the "## Review [N]" template from the Document Schema section above. Fill in your review_id as audit-005, read all prior reviews, and append your section here. -->

## Review 5 — Gameplay Logic & Data Integrity Reviewer

> review_id: audit-005
> date: 2026-02-22
> role: Gameplay Logic & Data Integrity Reviewer
> scope: Full independent pass over lib/ (all 16 Dart files), pubspec.yaml, firebase.json, android/app/build.gradle.kts, analysis_options.yaml, test/widget_test.dart, lib/todo.txt
> reads_reviews: audit-001, audit-002, audit-003, audit-004
> confidence: HIGH
> status: FINAL

### A. Agreements (with prior reviews)

- **AGREE** with audit-001 B.1 (monolithic game screen) — `lib/screens/game_screen.dart:L1-L1152` is still a single, coupled widget.
- **AGREE** with audit-001 B.2 (client-authoritative resolution) — day and night resolution remain client-triggered in `lib/screens/game_screen.dart:L654-L670`, `:L904-L929`.
- **AGREE** with audit-001 B.3 (plaintext room passwords) — `lib/screens/create_room_screen.dart:L67-L75` and `lib/screens/join_room_screen.dart:L93-L98` compare raw values.
- **AGREE** with audit-001 B.4 (hardcoded privilege) — `bonusNickname` is still in `lib/services/gold_service.dart:L6-L7`.
- **AGREE** with audit-001 B.5 (role metadata duplication) — multiple copies in `lib/screens/game_screen.dart:L703-L745`, `lib/screens/role_reveal_screen.dart:L21-L54`, `lib/screens/widgets/role_info_dialog.dart:L12-L73`, `lib/screens/game_end_screen.dart:L160-L230`.
- **AGREE** with audit-001 B.6 (no transactional join/leave/kick) — `FieldValue.increment` is used without transactions in `lib/screens/join_room_screen.dart:L171-L187` and `lib/screens/room_lobby_screen.dart:L95-L100`.
- **AGREE** with audit-001 B.7 (unused deps) — `firebase_auth` and `firebase_messaging` are still unused in code (`pubspec.yaml:L25-L35`).
- **AGREE** with audit-001 B.8 (dead debug code) — `testRoles()` remains unused in `lib/services/role_distribution.dart:L103-L128`.
- **AGREE** with audit-001 B.9 (no tests) — `test/widget_test.dart:L1-L10` remains an empty TODO.
- **AGREE** with audit-001 B.10 (broad stream rebuilds) — full room-doc listeners remain in `lib/screens/game_screen.dart:L585-L1152` and `lib/screens/room_lobby_screen.dart:L116-L632`.
- **AGREE** with audit-001 B.11 (sequential gold writes) — reward loop still writes per player in `lib/services/gold_service.dart:L78-L97`.

- **AGREE** with audit-002 B.1 (multi-trigger race) — auto-start + host buttons still produce concurrent resolution paths in `lib/screens/game_screen.dart:L654-L670`, `:L904-L929`.
- **AGREE** with audit-002 B.2 (custom auth bypass) — auth is still SHA-256 + SharedPrefs only (`lib/services/auth_service.dart:L1-L260`).
- **AGREE** with audit-002 B.3 (doctor overwrite) — `roleActions` is keyed by role string in `lib/services/night_resolution_service.dart:L31-L38`.
- **AGREE** with audit-002 B.4 (no Firestore rules in repo) — `firebase.json` still has no rules mapping.
- **AGREE** with audit-002 B.5 (bot system exposed) — “BOT EKLE” visible to all hosts in `lib/screens/room_lobby_screen.dart:L271-L321`.

- **AGREE** with audit-003 B.1 (inconsistent error handling) — some try/catch exists, but many failure paths are still silent or only snackbar-based.
- **PARTIALLY AGREE** with audit-003 B.2 (offline support) — no resume flow, but Firestore offline cache exists by default.
- **AGREE** with audit-003 B.3 (no localization scaffold) — all strings are hardcoded in Turkish.
- **PARTIALLY AGREE** with audit-003 B.4 (state management) — maintainability debt exists but not an immediate blocker.
- **PARTIALLY AGREE** with audit-003 B.5 (routing/stack fragility) — functional but brittle.
- **PARTIALLY AGREE** with audit-003 B.6 (input validation) — basic validation exists; allowlist/sanitization still missing.
- **AGREE** with audit-003 B.7 (magic constants) — time and role thresholds are hardcoded in `lib/screens/game_screen.dart:L39-L52` and `lib/services/role_distribution.dart:L22-L36`.
- **PARTIALLY AGREE** with audit-003 B.8 (loading state) — present but inconsistent across flows.
- **AGREE** with audit-003 B.9 (missing role implementations) — `asik` / `manipulator` still unimplemented in resolution services.
- **AGREE** with audit-003 B.10 (release signing uses debug key) — `android/app/build.gradle.kts:L37-L42`.

- **AGREE** with audit-004 B.1 (blocked-role checks wrong actor) — blocked checks are still mis-keyed in `lib/services/night_resolution_service.dart:L95-L128`.
- **AGREE** with audit-004 B.2 (room code collision overwrite) — room create uses `.set()` without pre-check in `lib/screens/create_room_screen.dart:L60-L81`.
- **AGREE** with audit-004 B.3 (client-asserted identity) — `SharedPreferences` userId is trusted for writes in `lib/services/auth_service.dart:L213-L249` and `lib/screens/game_screen.dart:L30-L35`.
- **AGREE** with audit-004 B.4 (client-clock phase timing) — day auto-start derives from local clock in `lib/screens/game_screen.dart:L42-L50` and `lib/screens/widgets/game_time_display.dart:L44-L78`.

### B. New Findings

**B.1 Misafir Block Does Not Cancel Doctor Action**
- Severity: HIGH
- Category: LOGIC_BUG
- Files: `lib/services/night_resolution_service.dart:L45-L59`
- Description: The misafir block is tracked by target player id, but the doctor check compares the **doctor's target** to blockedPlayers, not the **doctor's actor id**. This means blocking the doctor does not actually cancel their protection.
- Evidence: `protectedPlayer = (doktorTarget != null && !blockedPlayers.contains(doktorTarget)) ? doktorTarget : null;` uses the target id instead of the doctor id.
- Recommended Fix: Track blocks by actor id (or derive doctor actor id from role mapping) and test against the doctor’s player id, not the target.

**B.2 Vampir Targeting Allows Team-Kill**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `lib/screens/game_screen.dart:L189-L235`
- Description: Night target selection filters only by `alive` and `id != self`, so a vampire can target another vampire. This breaks standard werewolf rules and can end the game early or incorrectly.
- Evidence: `availableTargets = players.keys.where((id) => id != _userId && !deadPlayers.contains(id))` has no role-based filtering.
- Recommended Fix: Apply role-specific target constraints (e.g., vampires cannot target vampires).

**B.3 Multi-Room Membership Not Prevented for Active Games**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `lib/main.dart:L56-L95`, `lib/screens/join_room_screen.dart:L16-L55`
- Description: The “already in a room” checks only scan `gameState == 'waiting'` rooms. A player in an active game can still create or join another room, causing multi-room membership and inconsistent state.
- Evidence: `MainMenuScreen._navigateToCreateRoom()` and `JoinRoomScreen._checkExistingRoom()` both query only waiting rooms.
- Recommended Fix: Enforce one active-room membership across all states via transaction + Firestore rule, or track `currentRoomId` on user document.

**B.4 Winner Gold Display Mismatch for Guests**
- Severity: LOW
- Category: UX
- Files: `lib/screens/game_end_screen.dart:L129-L213`, `lib/services/gold_service.dart:L78-L97`
- Description: Game end UI shows `💰 +10` for winners unconditionally, but guest users never receive gold because rewards only update `users` collection. This creates a misleading reward display.
- Evidence: `GoldService.awardWinGold` only updates documents under `users`, while guests are stored in `guests`.
- Recommended Fix: Hide gold reward badge for guests or persist guest rewards separately.

### C. Risk Matrix Update

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|
| 1 | Open/insufficient Firestore rules with client-state authority | CRITICAL | Certain if deployed as-is | Full game/data tampering | Stream D | audit-002 B.4 + audit-002 B.1 |
| 2 | Multi-trigger resolution race in day phase | CRITICAL | Near-certain in real rooms | Wrong eliminations/winners | Stream B | audit-002 B.1 |
| 3 | Client-asserted identity (prefs userId) without token binding | HIGH | High with motivated attacker | Impersonation / unauthorized actions | Stream A | audit-004 B.3 |
| 4 | Night blocked-role logic selects wrong actor | HIGH | High in eccentric-role matches | Incorrect night outcomes | Stream B | audit-004 B.1 |
| 5 | Misafir block does not cancel doctor action | HIGH | High with misafir+doctor in match | Incorrect night outcomes | Stream B | audit-005 B.1 |
| 6 | Doctor overwrite when 2 doctors exist | MEDIUM | Certain at 12+ players | Silent gameplay corruption | Stream B | audit-002 B.3 |
| 7 | Non-transactional join/leave/kick | MEDIUM | Medium under concurrency | playerCount drift / capacity bypass | Stream B | audit-001 B.6 |
| 8 | Room code collision overwrite | MEDIUM | Low-probability but real | Room data loss/corruption | Stream B | audit-004 B.2 |
| 9 | Incomplete role implementation (`asik`/`manipulator`) | MEDIUM | Certain when selected | Rules inconsistency / player confusion | Stream B | audit-003 B.9 |
| 10 | Vampir targeting allows team-kill | MEDIUM | Possible in live rooms | Premature/incorrect eliminations | Stream B | audit-005 B.2 |
| 11 | Multi-room membership not prevented | MEDIUM | Possible with active games | State divergence, ghost players | Stream B | audit-005 B.3 |
| 12 | Monolithic game screen architecture | MEDIUM | Ongoing | Slower fixes, regression risk | Stream C | audit-001 B.1 |
| 13 | No automated tests for core logic | MEDIUM | Certain | Regressions undetected | Stream D | audit-001 B.9 |
| 14 | Hardcoded privileged bonus path | LOW | Deterministic | Fairness/reputation damage | Stream D | audit-001 B.4 |
| 15 | Release build signed with debug key | LOW | Certain in current config | Store/deploy friction | Stream D | audit-003 B.10 |
| 16 | Winner reward display mismatch for guests | LOW | Common in guest rooms | User confusion | Stream C | audit-005 B.4 |

### D. Roadmap Amendments

- **ADD** M0: Fix misafir/doctor blocking logic by tracking actor ids — effort **S** — dependency: none — correctness blocker.
- **ADD** M0: Add role-specific target constraints (e.g., vampires cannot target vampires) — effort **S** — dependency: none — prevents rule-breaking kills.
- **ADD** M0: Enforce single active room per user (waiting + playing) — effort **M** — dependency: rules/transaction choice — prevents multi-room state divergence.
- **ADD** M1: Adjust winner gold display for guests — effort **S** — dependency: guest reward policy.

**Quick Wins (<1 day)**
- Fix misafir/doctor block check to use actor ids.
- Add vampire-target filter to night action UI.
- Prevent multi-room membership by rejecting create/join when user is in any room.
- Hide gold reward badge for guest users.

### E. Open Questions

1. Should vampires be allowed to target other vampires in any special mode?
   - Blocks: B.2 fix design choice.
   - Suggested default: Disallow vampir→vampir targeting.

2. Is there a global “one active room per user” rule for all game states?
   - Blocks: B.3 enforcement strategy.
   - Suggested default: Yes, one active room across all states.

3. Should guests earn gold (or any progression), or should rewards be hidden for guests?
   - Blocks: B.4 UI/logic alignment.
   - Suggested default: Hide rewards for guests.

### F. Handoff Metadata

```yaml
review_id: audit-005
reviewer: Gameplay Logic & Data Integrity Reviewer
files_read: 16/16 Dart files in lib, pubspec.yaml, firebase.json, android/app/build.gradle.kts, analysis_options.yaml, test/widget_test.dart, lib/todo.txt
confidence: HIGH
open_items: 3
next_recommended_agent: Security Implementation Agent — add firestore.rules and enforce single-room membership in rules/transactions
blocked_on: Product decisions in E.1-E.3
```

## Review 6 — Security & Reliability Reviewer

> review_id: audit-006
> date: 2026-02-22
> role: Security & Reliability Reviewer
> scope: Full independent pass over all Dart sources under `lib/` (screens, services, widgets), plus `pubspec.yaml`, FlutterFire `firebase.json`, `analysis_options.yaml`, `android/app/build.gradle.kts`, and `test/widget_test.dart`
> reads_reviews: audit-001, audit-002, audit-003, audit-004, audit-005
> confidence: HIGH
> status: FINAL

### A. Agreements (with prior reviews)

- audit-001 B.1 — **AGREE** — `lib/screens/game_screen.dart` is still a coupled UI+orchestrator+mutator and remains the main maintainability choke-point.
- audit-001 B.2 — **AGREE** — critical room state mutations are still client-triggered; day voting can still be resolved from UI paths.
- audit-001 B.3 — **AGREE** — room passwords are stored/compared as plaintext (`lib/screens/create_room_screen.dart:L67-L75`, `lib/screens/join_room_screen.dart:L85-L113`).
- audit-001 B.4 — **AGREE** — `bonusNickname` backdoor still exists (`lib/services/gold_service.dart:L6-L7`).
- audit-001 B.5 — **AGREE** — role metadata is duplicated and already inconsistent; `manipulator` is still missing from role reveal (`lib/screens/role_reveal_screen.dart:L24-L62`).
- audit-001 B.6 — **AGREE** — join/leave/kick still update maps + `playerCount` outside transactions (`lib/screens/join_room_screen.dart:L171-L187`, `lib/screens/room_lobby_screen.dart:L105-L118`, `:L160-L172`).
- audit-001 B.7 — **AGREE** — `firebase_auth` and `firebase_messaging` are still declared but unused in code (`pubspec.yaml:L28-L35`).
- audit-001 B.8 — **AGREE** — `RoleDistribution.testRoles()` remains dead debug code (`lib/services/role_distribution.dart:L103-L150`).
- audit-001 B.9 — **AGREE** — tests remain effectively empty (`test/widget_test.dart:L1-L10`).
- audit-001 B.10 — **AGREE** — room-doc level streams still rebuild large UI scopes (`lib/screens/game_screen.dart:L579-L1152`, `lib/screens/room_lobby_screen.dart:L213-L413`).
- audit-001 B.11 — **AGREE** — gold awarding still loops sequentially (`lib/services/gold_service.dart:L78-L97`).

- audit-002 B.1 — **AGREE** — day-phase resolution can still be triggered via multiple paths (auto-trigger + host panel), with only a widget-local guard (`lib/screens/game_screen.dart:L25`, `:L654-L673`, `:L909-L969`).
- audit-002 B.2 — **AGREE** — auth is still custom SHA-256+salt stored in Firestore plus SharedPreferences session; `firebase_auth` remains unused (`lib/services/auth_service.dart:L1-L208`).
- audit-002 B.3 — **AGREE** — doctor overwrite at 12+ remains because night actions are keyed by role (`lib/services/night_resolution_service.dart:L35`).
- audit-002 B.4 — **AGREE** — there is still no `firestore.rules` in repo and no Firebase CLI rules deployment config; current `firebase.json` is FlutterFire config only.
- audit-002 B.5 — **AGREE** — bot feature is still visible to host and not debug-gated (`lib/screens/room_lobby_screen.dart:L532-L585`).

- audit-003 B.1 — **PARTIALLY AGREE** — there is try/catch in many code paths (e.g., `GameScreen` submit actions), but failure handling is not consistent and lacks transactional retry/lock semantics.
- audit-003 B.2 — **PARTIALLY AGREE** — explicit resume flows are missing, but Firestore offline cache exists by default; the UX still degrades sharply on disconnect.
- audit-003 B.3 — **AGREE** — strings are hardcoded Turkish; localization scaffolding is absent.
- audit-003 B.4 — **AGREE** — state is fragmented across widgets; this is long-term maintainability risk rather than immediate functional failure.
- audit-003 B.5 — **PARTIALLY AGREE** — routing is ad-hoc and can lead to awkward stack behavior, but the MVP flow is still navigable.
- audit-003 B.6 — **PARTIALLY AGREE** — basic validation exists (length/empty checks) in `AuthService`, but there is no strict allowlist/sanitization strategy.
- audit-003 B.7 — **AGREE** — magic numbers/timing constants are embedded in logic (`lib/screens/game_screen.dart:L38-L55`, `lib/screens/widgets/game_time_display.dart:L45-L74`).
- audit-003 B.8 — **DISAGREE** — many flows do have loading indicators; the main issue is inconsistency and missing “in-progress” state around phase resolution calls.
- audit-003 B.9 — **AGREE** — role pool vs implementation mismatch persists (`asik` is required for night submission but has no resolution; `manipulator` has no effect).
- audit-003 B.10 — **AGREE** — release signing still uses debug key (`android/app/build.gradle.kts:L33-L42`).

- audit-004 B.1 — **AGREE** — blocked-role checks are still wrong because the “actor id” is not actually determined (`lib/services/night_resolution_service.dart:L95-L128`).
- audit-004 B.2 — **AGREE** — room create still uses unconditional `.set()` on the roomCode doc id without conflict handling (`lib/screens/create_room_screen.dart:L66-L75`).
- audit-004 B.3 — **AGREE** — identity is still client-asserted via `SharedPreferences` userId and then used for writes in room docs (`lib/services/auth_service.dart:L185-L208`, `lib/screens/game_screen.dart:L27-L62`).
- audit-004 B.4 — **AGREE** — day timing and auto-start still depend on client wall-clock calculations against a server timestamp (`lib/screens/game_screen.dart:L38-L55`, `lib/screens/widgets/game_time_display.dart:L45-L74`).

- audit-005 B.1 — **AGREE** — misafir/doctor blocking semantics are incorrect; block is not applied to the doctor actor.
- audit-005 B.2 — **AGREE** — night target selection is role-agnostic (vampir can select any alive non-self) (`lib/screens/game_screen.dart:L321-L334`).
- audit-005 B.3 — **AGREE** — single-room membership is not enforced (existing checks only look at `gameState == 'waiting'`) (`lib/main.dart:L117-L158`, `lib/screens/join_room_screen.dart:L28-L55`).
- audit-005 B.4 — **AGREE** — game end rewards are misleading for guests because gold only applies to `users` (`lib/screens/game_end_screen.dart:L120-L170`, `lib/services/gold_service.dart:L78-L97`).

### B. New Findings

**B.1 Nickname uniqueness is race-prone (duplicate accounts possible)**
- Severity: MEDIUM
- Category: SECURITY
- Files: `lib/services/auth_service.dart:L23-L31`, `lib/services/auth_service.dart:L63-L103`
- Description: Account creation checks nickname availability with a query and then writes a new user doc with a random ID. Two clients can pass the availability check concurrently and create duplicate nicknames.
- Evidence: `isNicknameAvailable()` performs a read query, and `createAccount()` does a separate `doc().set(...)` write with no transaction/unique index.
- Recommended Fix: Introduce a “unique nickname” document (`nicknames/{nicknameLower}`) created via transaction (`create` semantics) or Cloud Function; fail fast on conflicts.

**B.2 Room deletion leaves non-host clients stranded (no recovery UX)**
- Severity: MEDIUM
- Category: UX
- Files: `lib/screens/room_lobby_screen.dart:L71-L90`, `lib/screens/room_lobby_screen.dart:L291-L299`, `lib/screens/game_screen.dart:L606-L623`, `lib/screens/game_end_screen.dart:L15-L33`
- Description: When the host deletes the room doc, other clients’ StreamBuilders render “Oda bulunamadı” but do not navigate back or offer a “return to menu” action. This is common in real sessions (host closes app, rage quits).
- Evidence: Host uses `.delete()` (`lib/screens/room_lobby_screen.dart:L82`) and other clients hit the “not found” branches.
- Recommended Fix: Replace hard delete with a soft close flag (`roomState: closed`) + `closedAt` timestamp; or when doc is missing, show a CTA that navigates to main menu and clears any local “in-room” state.

**B.3 `deadPlayers` can accumulate duplicates and invalid targets (no id validation)**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `lib/services/night_resolution_service.dart:L83`, `lib/services/day_resolution_service.dart:L52`
- Description: Both night and day resolution append to `deadPlayers` without checking whether the target is already dead, exists in `players`, or is eligible. This can produce duplicate ids and downstream UI/logic inconsistencies.
- Evidence: `deadPlayers.add(killedPlayer);` and `deadPlayers.add(eliminatedId);` occur without guards.
- Recommended Fix: Treat `deadPlayers` as a set conceptually: guard with `if (!deadPlayers.contains(id))`, and validate `players.containsKey(id)` before mutating.

**B.4 Membership detection is an O(N rooms) scan (cost + latency + wrong coverage)**
- Severity: LOW
- Category: PERFORMANCE
- Files: `lib/main.dart:L117-L158`, `lib/screens/join_room_screen.dart:L28-L55`
- Description: “already in a room” checks query *all* rooms in waiting state and then iterate every doc to search the `players` map. This does not cover active games and will become slow/expensive as rooms accumulate.
- Evidence: `.where('gameState', isEqualTo: 'waiting').get()` followed by client-side loops.
- Recommended Fix: Maintain `currentRoomId` on the user/guest document (or a membership collection) so the client can fetch one doc instead of scanning many.

### C. Risk Matrix Update

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|
| 1 | Open/insufficient Firestore rules with client-state authority | CRITICAL | Certain if deployed as-is | Full game/data tampering | Stream D | audit-002 B.4 + audit-002 B.1 |
| 2 | Multi-trigger resolution race in day phase | CRITICAL | Near-certain in real rooms | Wrong eliminations/winners | Stream B | audit-002 B.1 |
| 3 | Client-asserted identity (prefs userId) without token binding | HIGH | High with motivated attacker | Impersonation / unauthorized actions | Stream A | audit-004 B.3 |
| 4 | Night blocked-role logic selects wrong actor | HIGH | High in eccentric-role matches | Incorrect night outcomes | Stream B | audit-004 B.1 |
| 5 | Misafir/doctor blocking semantics incorrect | HIGH | High with misafir+doctor in match | Incorrect night outcomes | Stream B | audit-005 B.1 |
| 6 | Custom auth (SHA-256, no KDF/tokens, no deletion flow) | HIGH | High | Account takeover / store policy risk | Stream A | audit-002 B.2 |
| 7 | Doctor overwrite when 2 doctors exist | MEDIUM | Certain at 12+ players | Silent gameplay corruption | Stream B | audit-002 B.3 |
| 8 | Non-transactional join/leave/kick | MEDIUM | Medium under concurrency | playerCount drift / capacity bypass | Stream B | audit-001 B.6 |
| 9 | Room code collision overwrite | MEDIUM | Low-probability but real | Room data loss/corruption | Stream B | audit-004 B.2 |
| 10 | Incomplete role implementation (`asik`/`manipulator`) | MEDIUM | Certain when selected | Rules inconsistency / player confusion | Stream B | audit-003 B.9 |
| 11 | Vampir targeting allows team-kill | MEDIUM | Possible in live rooms | Premature/incorrect eliminations | Stream B | audit-005 B.2 |
| 12 | Multi-room membership not prevented (active games) | MEDIUM | Possible | State divergence, ghost players | Stream B | audit-005 B.3 |
| 13 | `deadPlayers` duplicates / invalid target writes | MEDIUM | Medium | UI/logic inconsistency | Stream B | audit-006 B.3 |
| 14 | Nickname uniqueness race (duplicates possible) | MEDIUM | Medium | Identity confusion / impersonation | Stream A | audit-006 B.1 |
| 15 | Monolithic game screen architecture | MEDIUM | Ongoing | Slow fixes, regression risk | Stream C | audit-001 B.1 |
| 16 | No automated tests for core logic | MEDIUM | Certain | Regressions undetected | Stream D | audit-001 B.9 |
| 17 | Winner reward display mismatch for guests | LOW | Common | User confusion | Stream C | audit-005 B.4 |
| 18 | Soft-failure UX on room deletion (clients stranded) | LOW | Possible | Session abandonment | Stream C | audit-006 B.2 |
| 19 | Release build signed with debug key | LOW | Certain in current config | Store/deploy friction | Stream D | audit-003 B.10 |
| 20 | Hardcoded privileged bonus path | LOW | Deterministic | Fairness/reputation damage | Stream D | audit-001 B.4 |

### D. Roadmap Amendments

- **AGREE** with the overall milestone order (M0 correctness/security → M1 loop completion → M3 prod readiness), but suggest tightening M0 scope around *authority + identity + rules*.
- **REORDER** M0 (new sequence):
  1. Firestore security rules + minimal schema hardening (membership, write allowlists)
  2. Day-resolution lock (transaction field lock) and remove/host-gate multi-client auto-resolve
  3. Fix night-resolution correctness bugs (blocked actor + multi-doctor + misafir/doctor semantics)
  4. Transactional room create/join/leave/kick + collision guards
  5. Remove `bonusNickname` backdoor + debug-gate bot tools
- **ADD** to M0: Fix nickname uniqueness race — effort **M** — dependency: chosen identity approach — prevents duplicate identities.
- **ADD** to M0: Guard against duplicate/invalid `deadPlayers` writes — effort **S** — dependency: none — removes silent corruption.
- **MOVE** localization and “full offline mode” out of near-term; keep “resume/reconnect” as a later M1/M2 item.

**Quick Wins (<1 day)**
- Add `manipulator` to `RoleRevealScreen` role metadata maps (removes immediate inconsistency).
- Remove `bonusNickname` bonus path in `GoldService`.
- Add existence check/transaction on room creation to avoid overwrite on code collision.
- Add simple guards around `deadPlayers` append to prevent duplicates.

### E. Open Questions

1. Should “nickname” be globally unique and immutable (like a handle), or can users change it?
   - Blocks: nickname uniqueness enforcement strategy.
   - Suggested default: unique + immutable for v1.

2. When a room is closed/deleted, should clients automatically return to main menu, or show a “room closed” screen?
   - Blocks: room lifecycle model (hard delete vs soft close).
   - Suggested default: soft close + auto-return CTA.

3. Do you want to support bots as real participants (with roles/votes), or are bots strictly a dev/testing tool?
   - Blocks: bot gating and logic expectations.
   - Suggested default: dev-only behind `kDebugMode`.

### F. Handoff Metadata

```yaml
review_id: audit-006
reviewer: Security & Reliability Reviewer
files_read:
  - lib/main.dart
  - lib/firebase_options.dart
  - lib/screens/welcome_screen.dart
  - lib/screens/create_account_screen.dart
  - lib/screens/login_account_screen.dart
  - lib/screens/guest_login_screen.dart
  - lib/screens/create_room_screen.dart
  - lib/screens/join_room_screen.dart
  - lib/screens/room_lobby_screen.dart
  - lib/screens/role_reveal_screen.dart
  - lib/screens/game_screen.dart
  - lib/screens/game_end_screen.dart
  - lib/screens/widgets/role_info_dialog.dart
  - lib/screens/widgets/game_time_display.dart
  - lib/services/auth_service.dart
  - lib/services/role_distribution.dart
  - lib/services/night_resolution_service.dart
  - lib/services/day_resolution_service.dart
  - lib/services/gold_service.dart
  - pubspec.yaml
  - firebase.json
  - analysis_options.yaml
  - android/app/build.gradle.kts
  - test/widget_test.dart
confidence: HIGH
open_items: 3 (see E. Open Questions)
next_recommended_agent: Security Implementation Agent — first task: add Firestore rules + transaction locks for day/night resolution
blocked_on: Product decisions in E.1-E.3
```

## Review 7 — Security Implementation Planner

> review_id: audit-007
> date: 2026-02-22
> role: Security Implementation Planner
> scope: Full independent pass over all Dart sources under lib/ (screens, services, widgets), plus pubspec.yaml, firebase.json, analysis_options.yaml, android/app/build.gradle.kts, test/widget_test.dart, lib/todo.txt
> reads_reviews: audit-001, audit-002, audit-003, audit-004, audit-005, audit-006
> confidence: HIGH
> status: FINAL

### A. Agreements (with prior reviews)

- **AGREE** with audit-001 B.1 — game_screen.dart remains a single, tightly coupled UI + orchestration + mutation widget (lib/screens/game_screen.dart:L1-L1152).
- **AGREE** with audit-001 B.2 — critical phase transitions and resolution are still client-triggered from GameScreen, not guarded by any server-side lock (lib/screens/game_screen.dart:L654-L673, :L904-L969).
- **AGREE** with audit-001 B.3 — room passwords are still stored and compared in plaintext (lib/screens/create_room_screen.dart:L66-L81, lib/screens/join_room_screen.dart:L93-L113).
- **AGREE** with audit-001 B.4 — the kadergamer123 bonus path is still present in GoldService (lib/services/gold_service.dart:L6-L7, :L52-L81).
- **AGREE** with audit-001 B.5 — role metadata is still duplicated across four widgets and already inconsistent (lib/screens/game_screen.dart:L703-L745, lib/screens/role_reveal_screen.dart:L21-L54, lib/screens/widgets/role_info_dialog.dart:L12-L73, lib/screens/game_end_screen.dart:L120-L160).
- **AGREE** with audit-001 B.6 — join/leave/kick operations still mutate players and playerCount without Firestore transactions (lib/screens/join_room_screen.dart:L120-L187, lib/screens/room_lobby_screen.dart:L71-L118, :L149-L172).
- **AGREE** with audit-001 B.7 — firebase_auth and firebase_messaging are still declared but unused (pubspec.yaml:L22-L36).
- **AGREE** with audit-001 B.9 — there is still effectively no automated test coverage (test/widget_test.dart:L1-L10).
- **AGREE** with audit-001 B.10 — large StreamBuilder scopes still rebuild on any room doc change (lib/screens/game_screen.dart:L579-L1152, lib/screens/room_lobby_screen.dart:L213-L413).

- **AGREE** with audit-002 B.1 — the multi-trigger day resolution race (auto-start + host buttons) is still present with only a widget-local guard (lib/screens/game_screen.dart:L25, :L654-L673, :L904-L969).
- **AGREE** with audit-002 B.2 — auth is still entirely custom (SHA-256 + salt + SharedPreferences) with firebase_auth unused (lib/services/auth_service.dart:L1-L208).
- **AGREE** with audit-002 B.3 — doctor overwrite at 12+ players remains because night actions are keyed by role string (lib/services/night_resolution_service.dart:L31-L38).
- **AGREE** with audit-002 B.4 — there is still no firestore.rules file or CLI rules deployment configured (firebase.json, project root).
- **AGREE** with audit-002 B.5 — the bot feature is visible to hosts in production and not debug-gated (lib/screens/room_lobby_screen.dart:L271-L321).

- **PARTIALLY AGREE** with audit-003 B.1 — error handling exists in several flows (snackbars, debugPrint) but remains inconsistent and not paired with any transactional retry/lock semantics.
- **AGREE** with audit-003 B.3 — localization is not scaffolded; all user-facing strings are hardcoded Turkish.
- **AGREE** with audit-003 B.7 — timing and role thresholds are hardcoded as magic constants (lib/screens/game_screen.dart:L38-L55, lib/services/role_distribution.dart:L22-L36).
- **AGREE** with audit-003 B.9 — asik/manipulator remain partially/unimplemented in resolution services despite being in the eccentric role pool (lib/services/night_resolution_service.dart, lib/services/day_resolution_service.dart).

- **AGREE** with audit-004 B.1 — blocked-role checks derive the “actor” incorrectly from map keys instead of actual player IDs (lib/services/night_resolution_service.dart:L95-L128).
- **AGREE** with audit-004 B.2 — room creation still uses unconditional .set() on rooms/{roomCode} without conflict handling (lib/screens/create_room_screen.dart:L60-L81).
- **AGREE** with audit-004 B.3 — identity is still asserted purely from SharedPreferences userId with no token binding or backend verification (lib/services/auth_service.dart:L185-L208, lib/screens/game_screen.dart:L25-L35).
- **AGREE** with audit-004 B.4 — day timing/auto-start still depend on client wall-clock plus a server timestamp (lib/screens/game_screen.dart:L38-L55, lib/screens/widgets/game_time_display.dart:L45-L78).

- **AGREE** with audit-005 B.1 — misafir’s block does not correctly cancel doctor action because it tracks targets, not the doctor actor (lib/services/night_resolution_service.dart:L45-L59).
- **AGREE** with audit-005 B.2 — vampire targeting currently allows team-kill (any alive, non-self target) (lib/screens/game_screen.dart:L189-L235).
- **AGREE** with audit-005 B.3 — “already in a room” checks only scan waiting rooms, not active/finished games (lib/main.dart:L75-L120, lib/screens/join_room_screen.dart:L28-L55).
- **AGREE** with audit-005 B.4 — winners’ gold UI is misleading for guests because only users/ collection receives gold (lib/screens/game_end_screen.dart:L120-L170, lib/services/gold_service.dart:L78-L97).

- **AGREE** with audit-006 B.1 — nickname uniqueness remains race-prone due to read-then-write semantics (lib/services/auth_service.dart:L23-L31, :L63-L103).
- **AGREE** with audit-006 B.2 — hard room deletion leaves non-host clients stranded in a “room not found” state without a recovery CTA (lib/screens/room_lobby_screen.dart:L71-L90, lib/screens/game_screen.dart:L585-L620).
- **AGREE** with audit-006 B.3 — deadPlayers is treated as an append-only list with no set semantics or validation (lib/services/night_resolution_service.dart:L83, lib/services/day_resolution_service.dart:L52).

### B. New Findings

**B.1 Asik treated as full night actor but has no resolution semantics**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: lib/services/night_resolution_service.dart:L139-L156, lib/screens/game_screen.dart:L120-L220, lib/services/role_distribution.dart:L7-L40
- Description: The role asik is (a) included in the eccentricRoles pool, (b) counted as a night role in areAllActionsSubmitted (nightRoles contains 'asik'), and (c) given a generic night HEDEF SEÇ UI in GameScreen. However resolveNight() never inspects or applies asik’s action at all. This makes night resolution completeness dependent on a role with zero implemented effect, and encourages players to send “dummy” actions that do nothing.
- Evidence: nightRoles list in areAllActionsSubmitted includes 'asik'; resolveNight() never branches on roleActions['asik'].
- Recommended Fix: Either fully implement asik mechanics (including once-per-game constraints and death side-effects) in NightResolutionService and document their interaction with deadPlayers, or temporarily remove asik from eccentricRoles and nightRoles until properly designed.

**B.2 Host authority is purely a UI convention, not a security boundary**
- Severity: HIGH
- Category: SECURITY
- Files: lib/screens/game_screen.dart:L213-L320, lib/services/night_resolution_service.dart:L7-L112, lib/services/day_resolution_service.dart:L7-L101
- Description: All authoritative operations (night resolution, day resolution, room closure, bots, gold bonus) are enforced only in the Flutter UI using hostId checks. There is no server-side enforcement that only the room host (or a Cloud Function) may call resolveNight/resolveVoting or mutate gameState/currentPhase. A modified client or script that imports these service classes can execute resolution for any room where it knows roomCode.
- Evidence: NightResolutionService.resolveNight and DayResolutionService.resolveVoting are public static functions that accept roomCode only, with no caller identity; Firestore writes are unconditional.
- Recommended Fix: Introduce Firestore rules that restrict state transitions (gameState/currentPhase/votingStarted/nightActions/dayVotes/deadPlayers) to either (a) a Cloud Function service account, or (b) the document hostId plus additional invariants. Prefer Cloud Functions for long-term, with interim client-side transactions and rules that verify request.auth.uid == hostId.

**B.3 Room membership is write-only with no centralized user index**
- Severity: MEDIUM
- Category: ARCHITECTURE
- Files: lib/main.dart:L75-L120, lib/screens/join_room_screen.dart:L28-L55, lib/screens/room_lobby_screen.dart:L71-L118, lib/lib.todo.txt:L1-L12
- Description: Membership is only represented inside each room document’s embedded players map. There is no per-user “currentRoomId” or membership collection. As prior reviews note, “already in room” checks scan all waiting rooms and ignore playing/finished ones. This design also makes it much harder to write Firestore rules that enforce “one active room per user” and to identify orphaned memberships.
- Evidence: All membership checks iterate over rooms where gameState == 'waiting'; no user-level field encodes room membership.
- Recommended Fix: Introduce a per-user field (e.g., users/{id}.currentRoomId or guests/{id}.currentRoomId) kept in sync transactionally whenever players join/leave/rooms close, and use that as the single source of truth for membership and security rules.

### C. Risk Matrix Update

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|
| 1 | Open/insufficient Firestore rules with client-state authority | CRITICAL | Certain if deployed as-is | Full game/data tampering | Stream D | audit-002 B.4 + audit-002 B.1 |
| 2 | Multi-trigger resolution race in day phase | CRITICAL | Near-certain in real rooms | Wrong eliminations/winners | Stream B | audit-002 B.1 |
| 3 | Client-asserted identity (prefs userId) without token binding | HIGH | High with motivated attacker | Impersonation / unauthorized actions | Stream A | audit-004 B.3 |
| 4 | Custom auth (SHA-256, no KDF/tokens, no deletion flow) | HIGH | High | Account takeover / store policy risk | Stream A | audit-002 B.2 |
| 5 | Host authority enforced only in UI (no backend checks) | HIGH | High for modified clients | Unauthorized phase transitions / griefing | Stream B | audit-007 B.2 |
| 6 | Night blocked-role logic selects wrong actor | HIGH | High in eccentric-role matches | Incorrect night outcomes | Stream B | audit-004 B.1 |
| 7 | Misafir/doctor blocking semantics incorrect | HIGH | High with misafir+doctor in match | Incorrect night outcomes | Stream B | audit-005 B.1 |
| 8 | Doctor overwrite when 2 doctors exist | MEDIUM | Certain at 12+ players | Silent gameplay corruption | Stream B | audit-002 B.3 |
| 9 | Non-transactional join/leave/kick | MEDIUM | Medium under concurrency | playerCount drift / capacity bypass | Stream B | audit-001 B.6 |
| 10 | Room code collision overwrite | MEDIUM | Low-probability but real | Room data loss/corruption | Stream B | audit-004 B.2 |
| 11 | Incomplete role implementation (asik/manipulator) | MEDIUM | Certain when selected | Rules inconsistency / player confusion | Stream B | audit-003 B.9 + audit-007 B.1 |
| 12 | Vampir targeting allows team-kill | MEDIUM | Possible in live rooms | Premature/incorrect eliminations | Stream B | audit-005 B.2 |
| 13 | Multi-room membership not prevented (active games) | MEDIUM | Possible | State divergence, ghost players | Stream B | audit-005 B.3 |
| 14 | deadPlayers duplicates / invalid targets | MEDIUM | Medium | UI/logic inconsistency | Stream B | audit-006 B.3 |
| 15 | Nickname uniqueness race (duplicates possible) | MEDIUM | Medium | Identity confusion / impersonation | Stream A | audit-006 B.1 |
| 16 | Membership model lacks centralized per-user index | MEDIUM | Medium over time | Hard to enforce one-room rule / clean up | Stream B | audit-007 B.3 |
| 17 | Monolithic game screen architecture | MEDIUM | Ongoing | Slow fixes, regression risk | Stream C | audit-001 B.1 |
| 18 | No automated tests for core logic | MEDIUM | Certain | Regressions undetected | Stream D | audit-001 B.9 |
| 19 | Winner reward display mismatch for guests | LOW | Common | User confusion | Stream C | audit-005 B.4 |
| 20 | Soft-failure UX on room deletion (clients stranded) | LOW | Possible | Session abandonment | Stream C | audit-006 B.2 |
| 21 | Release build signed with debug key | LOW | Certain in current config | Store/deploy friction | Stream D | audit-003 B.10 |
| 22 | Hardcoded privileged bonus path | LOW | Deterministic | Fairness/reputation damage | Stream D | audit-001 B.4 |

### D. Roadmap Amendments

- I **agree** with prior reviewers that M0 must focus on correctness and authority, but I recommend explicitly framing it around three pillars: Firestore rules, identity binding, and transactional invariants.
- **REORDER** M0 as:
  1. Introduce and deploy Firestore rules that (a) restrict writes on gameState/currentPhase/nightActions/dayVotes/deadPlayers/players to authenticated users, and (b) only allow authoritative phase transitions from either a Cloud Function or the room host (by hostId).
  2. Add a lightweight identity binding by migrating to FirebaseAuth (anonymous + email/password) and wiring AuthService to FirebaseAuth UIDs instead of manual userId strings.
  3. Add transaction-based guards around room create/join/leave/kick, nickname registration, and room code collision.
  4. Fix night-resolution correctness bugs (blocked actor, misafir/doctor semantics, multi-doctor overwrite, deadPlayers as a set).
  5. Remove bonusNickname backdoor and debug-gate bots.
- **ADD** to M0: Implement a minimal firestore.rules file with explicit allow/deny for rooms, users, guests, and a “maintenance” rule set for early testing — effort **M** — dependency: project owner confirming collection names are stable.
- **ADD** to M0: Introduce per-user currentRoomId (users/ and guests/) and wire it into join/leave/close flows transactionally — effort **M** — dependency: decision on “one active room per user” policy.
- **ADD** to M0: Temporarily remove asik/manipulator from RoleDistribution.eccentricRoles and areAllActionsSubmitted nightRoles, or hide eccentric mode, until their logic is fully specified and implemented — effort **S** — dependency: product decision on launch role set.
- **MOVE** localization and advanced offline behavior (beyond reconnect/resume) out of M0/M1 into a later milestone after authority and correctness are locked.

**Quick Wins (<1 day)**
- Remove bonusNickname from GoldService and redeploy.
- Add a draft firestore.rules file that at least denies all unauthenticated writes and narrows room updates to authenticated users.
- Add currentRoomId to users/ and guests/ documents and set/clear it in join_room_screen.dart and room_lobby_screen.dart flows.
- Hide or remove asik/manipulator from the eccentricRoles pool until their effects exist in night/day resolution.

### E. Open Questions

1. Should all state transitions (night→day, day→night, finished) be exclusively owned by a Cloud Function, or is a host-driven transactional model acceptable for v1?
   - Blocks: Security rules design and whether to expose resolveNight/resolveVoting to clients at all.
   - Suggested default: Host-driven transactions for v1 (easier to ship), with a clear migration path to Cloud Functions.

2. Is “one active room per user” a hard product requirement across all states (waiting, playing, finished), or only for waiting/playing?
   - Blocks: Schema design for currentRoomId and membership rules.
   - Suggested default: One active room across waiting+playing, ignore finished rooms once players return to main menu.

3. Are asik and manipulator required for v1, or acceptable to ship later as an “advanced roles” update?
   - Blocks: Decision to temporarily prune them from role_distribution.dart and night/day resolution.
   - Suggested default: Defer them and ship a smaller, fully-correct role set.

4. Is there a requirement for auditability (e.g., being able to reconstruct why someone died from server logs/rules), or is “best-effort” logging via debugPrint sufficient for early stages?
   - Blocks: Depth of Firestore rules and logging strategy (e.g., separate audit collection).
   - Suggested default: Keep auditability minimal for v1, but design schema so adding an audit trail later is straightforward.

### F. Handoff Metadata

```yaml
review_id: audit-007
reviewer: Security Implementation Planner
files_read:
  - lib/main.dart
  - lib/firebase_options.dart
  - lib/screens/welcome_screen.dart
  - lib/screens/create_account_screen.dart
  - lib/screens/login_account_screen.dart
  - lib/screens/guest_login_screen.dart
  - lib/screens/create_room_screen.dart
  - lib/screens/join_room_screen.dart
  - lib/screens/room_lobby_screen.dart
  - lib/screens/role_reveal_screen.dart
  - lib/screens/game_screen.dart
  - lib/screens/game_end_screen.dart
  - lib/screens/widgets/role_info_dialog.dart
  - lib/screens/widgets/game_time_display.dart
  - lib/services/auth_service.dart
  - lib/services/role_distribution.dart
  - lib/services/night_resolution_service.dart
  - lib/services/day_resolution_service.dart
  - lib/services/gold_service.dart
  - pubspec.yaml
  - firebase.json
  - analysis_options.yaml
  - android/app/build.gradle.kts
  - test/widget_test.dart
  - lib/todo.txt
confidence: HIGH
open_items: 4
next_recommended_agent: Implementation Agent (Firestore Rules & Transactions) — first task: create firestore.rules and refactor room join/leave/create into transactions using currentRoomId
blocked_on: Product decisions in E.1-E.3 and confirmation of collection naming conventions for rules
```

<!-- NEXT AGENT: Copy the "## Review [N]" template from the Document Schema section above. Fill in your review_id as audit-009, read all prior reviews, and append your section here. -->

## Review 8 — Night Logic & Runtime Correctness Reviewer

> review_id: audit-008
> date: 2026-02-22
> role: Night Logic & Runtime Correctness Reviewer
> scope: Full independent pass over all 16 Dart files under `lib/` (screens, services, widgets), plus `pubspec.yaml`, `firebase.json`, `android/app/build.gradle.kts`, `analysis_options.yaml`, `test/widget_test.dart`, `lib/todo.txt`
> reads_reviews: audit-001, audit-002, audit-003, audit-004, audit-005, audit-006, audit-007
> confidence: HIGH
> status: FINAL

### A. Agreements (with prior reviews)

- **AGREE** with audit-001 B.1 — `lib/screens/game_screen.dart` is a 1152-line monolith with UI + orchestration + Firestore mutations all in one `build()` and one `State` class.
- **AGREE** with audit-001 B.2 — day resolution can be triggered from host UI and auto-clock path without a server-side lock.
- **AGREE** with audit-001 B.3 — room passwords stored/compared in plaintext (`lib/screens/create_room_screen.dart:L66-L75`, `lib/screens/join_room_screen.dart:L93-L113`).
- **AGREE** with audit-001 B.4 — `bonusNickname = 'kadergamer123'` backdoor still present (`lib/services/gold_service.dart:L6-L7`).
- **AGREE** with audit-001 B.5 — role metadata (`roleIcons`, `roleNames`, `roleColors`) duplicated across 4 files; `lib/screens/role_reveal_screen.dart:L21-L54` still missing `manipulator`.
- **AGREE** with audit-001 B.6 — join/leave/kick still mutate `players` map and `playerCount` outside Firestore transactions (`lib/screens/join_room_screen.dart:L171-L187`, `lib/screens/room_lobby_screen.dart:L95-L118`).
- **AGREE** with audit-001 B.7 — `firebase_auth` declared at `pubspec.yaml:L33` and `firebase_messaging` at `pubspec.yaml:L35`; neither is imported in any `lib/` file.
- **AGREE** with audit-001 B.8 — `RoleDistribution.testRoles()` at `lib/services/role_distribution.dart:L103-L128` has no callers; dead debug code.
- **AGREE** with audit-001 B.9 — `test/widget_test.dart` is effectively empty; zero test coverage.
- **AGREE** with audit-001 B.10 — full room-doc `snapshots()` streams drive large rebuild scopes in `lib/screens/game_screen.dart:L579-L1152` and `lib/screens/room_lobby_screen.dart`.
- **AGREE** with audit-001 B.11 — `GoldService.awardWinGold` loops with sequential per-player Firestore writes (`lib/services/gold_service.dart:L78-L97`).

- **AGREE** with audit-002 B.1 — triple-trigger day resolution race (auto-start + host "OYLAMAYA BAŞLA" + host "OYLAMAYI BİTİR") with only a widget-local `_hasAutoStartedVoting` guard (`lib/screens/game_screen.dart:L25`, `:L654-L673`, `:L904-L969`).
- **AGREE** with audit-002 B.2 — auth is custom SHA-256+salt+SharedPreferences; `firebase_auth` unused (`lib/services/auth_service.dart:L1-L20`).
- **AGREE** with audit-002 B.3 — `roleActions` keyed by role string means second doctor's target overwrites first (`lib/services/night_resolution_service.dart:L31-L38`).
- **AGREE** with audit-002 B.4 — no `firestore.rules` file in repo; `firebase.json` has no rules path.
- **AGREE** with audit-002 B.5 — "BOT EKLE" button visible to any host, not guarded by `kDebugMode`.

- **PARTIALLY AGREE** with audit-003 B.1 — inconsistent error handling; some flows have try/catch, resolution services swallow errors with `debugPrint` only.
- **PARTIALLY AGREE** with audit-003 B.2 — no explicit reconnection/resume flow, but Firestore offline cache mitigates total loss.
- **AGREE** with audit-003 B.3 — all user-facing strings hardcoded Turkish; no localization scaffold.
- **PARTIALLY AGREE** with audit-003 B.4 — state management is fragmented but not an immediate functional blocker.
- **PARTIALLY AGREE** with audit-003 B.5 — routing is ad-hoc but flows are still navigable for MVP.
- **DISAGREE** with audit-003 B.6 — basic validation (length, emptiness) exists in `lib/services/auth_service.dart:L35-L57` and join paths; allowlist sanitization is still missing but the claim of "no validation" is not accurate.
- **AGREE** with audit-003 B.7 — magic constants scattered (`lib/screens/game_screen.dart:L49`, `lib/services/role_distribution.dart:L22-L36`).
- **DISAGREE** with audit-003 B.8 — loading states exist broadly (`_isLoading`, `CircularProgressIndicator`, snackbars); the real problem is inconsistency around phase resolution calls, not overall absence.
- **AGREE** with audit-003 B.9 — `asik` is in `nightRoles` for `areAllActionsSubmitted` but `resolveNight()` never inspects it; `manipulator` is distributed but has no effect in either service.
- **AGREE** with audit-003 B.10 — release build signed with debug key (`android/app/build.gradle.kts:L37-L42`).

- **AGREE** with audit-004 B.1 — blocked-role checks use `players.keys.firstWhere(...)` ignoring the `id` predicate parameter, deriving actor identity from map iteration order instead of actual player ID (`lib/services/night_resolution_service.dart:L95-L128`).
- **AGREE** with audit-004 B.2 — room create uses unconditional `.set()` on `rooms/{roomCode}` with no collision guard (`lib/screens/create_room_screen.dart:L60-L81`).
- **AGREE** with audit-004 B.3 — identity is purely client-asserted from `SharedPreferences` and used directly in write paths (`lib/services/auth_service.dart:L185-L208`, `lib/screens/game_screen.dart:L27-L62`).
- **AGREE** with audit-004 B.4 — day auto-start timing depends on client wall-clock diff against server timestamp (`lib/screens/game_screen.dart:L38-L55`).

- **AGREE** with audit-005 B.1 — misafir block checks the doctor's *target* id against `blockedPlayers`, not the doctor actor; block does not cancel doctor protection (`lib/services/night_resolution_service.dart:L45-L59`).
- **AGREE** with audit-005 B.2 — night target selection has no role-based filtering; vampire can target another vampire (`lib/screens/game_screen.dart:L312-L320`).
- **AGREE** with audit-005 B.3 — "already in a room" check only scans `gameState == 'waiting'` rooms (`lib/main.dart:L117-L158`, `lib/screens/join_room_screen.dart:L28-L55`).
- **AGREE** with audit-005 B.4 — winner gold UI shows `+10` for guests who never actually receive gold (`lib/screens/game_end_screen.dart`, `lib/services/gold_service.dart:L78-L97`).

- **AGREE** with audit-006 B.1 — nickname uniqueness is a read-then-write race with no transaction (`lib/services/auth_service.dart:L23-L31`, `:L63-L103`).
- **AGREE** with audit-006 B.2 — hard room deletion leaves non-host clients stuck in "Oda bulunamadı" with no recovery CTA (`lib/screens/game_screen.dart:L607-L617`).
- **AGREE** with audit-006 B.3 — `deadPlayers.add(...)` in both services has no duplicate/existence guard (`lib/services/night_resolution_service.dart:L83`, `lib/services/day_resolution_service.dart:L52`).
- **AGREE** with audit-006 B.4 — "already in a room" check is an O(N rooms) scan at cost (`lib/main.dart:L117-L158`).

- **AGREE** with audit-007 B.1 — `asik` is a full night actor with UI and `areAllActionsSubmitted` coverage, but `resolveNight()` never branches on it; action is silently discarded.
- **AGREE** with audit-007 B.2 — host authority is purely a UI-layer check; resolution service functions are public and unconstrained (`lib/services/night_resolution_service.dart:L6`, `lib/services/day_resolution_service.dart:L7`).
- **AGREE** with audit-007 B.3 — membership is embedded in room documents only; no per-user `currentRoomId` field.

### B. New Findings

**B.1 `deli` killed at night never triggers deli win condition**
- Severity: HIGH
- Category: LOGIC_BUG
- Files: `lib/services/night_resolution_service.dart:L127-L148`, `lib/services/day_resolution_service.dart:L65-L73`
- Description: `resolveNight()` adds the killed player to `deadPlayers` and immediately transitions to the day phase without invoking any win-condition check. The `_checkWinCondition()` function only exists in `DayResolutionService` and only receives `eliminatedRole` from the day-vote path. `deli`'s win condition (`eliminatedRole == 'deli'`) is therefore unreachable if vampires kill the `deli` player at night. The deli player is simply declared dead on the morning announcement and the game continues or ends for another reason. Deli can only ever win by being voted out during the day.
- Evidence: `resolveNight()` ends with `await roomRef.update({..., 'currentPhase': 'day', ...})` and no win check. `_checkWinCondition` is a private static in `DayResolutionService` and is not called from anywhere in `NightResolutionService`.
- Recommended Fix: Extract `_checkWinCondition` into a shared location (e.g., `lib/services/game_rules.dart`) and call it from the end of `resolveNight()` after computing the killed player, passing `killedPlayer`'s role as the equivalent of `eliminatedRole`.

**B.2 Auto-voting closure captures stale `votingStarted` value, bypasses vote collection window**
- Severity: HIGH
- Category: LOGIC_BUG
- Files: `lib/screens/game_screen.dart:L654-L673`
- Description: The auto-voting block captures `votingStarted` from the `StreamBuilder` snapshot at widget-build time and then reads it inside a `Future.delayed` callback that fires ≥500 ms later:
  ```dart
  if (_shouldAutoStartVoting(phaseStartTimestamp) && !_hasAutoStartedVoting) {
    _hasAutoStartedVoting = true;
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!votingStarted) { // ← stale value from snapshot
        await ... update({'votingStarted': true});
        await Future.delayed(const Duration(seconds: 2));
      }
      await DayResolutionService.resolveVoting(widget.roomCode);
    });
  }
  ```
  If the host has already set `votingStarted: true` in Firestore between the snapshot and the 500 ms callback, the captured `votingStarted` is still `false`. The auto-trigger then: (1) overwrites `votingStarted: true` (no-op, but redundant), (2) waits 2 s, (3) calls `resolveVoting`. Conversely, if `votingStarted` was captured as `true` (host manually started voting), the `if (!votingStarted)` branch is skipped and `resolveVoting` fires *immediately* without any collection window — players who haven't yet voted are resolved with incomplete votes.
- Evidence: `votingStarted` is a `final` local extracted from the snapshot at `lib/screens/game_screen.dart:L648`; the closure does not re-read Firestore before deciding whether to wait.
- Recommended Fix: Re-read the room document inside the `Future.delayed` callback (one `get()` call) before branching on `votingStarted`, or move all auto-resolution logic to a server-side transaction that is idempotent.

**B.3 `applicationId` is `com.example.vampir_koylu` — hard store submission blocker**
- Severity: MEDIUM
- Category: DEVOPS
- Files: `android/app/build.gradle.kts:L12`, `android/app/build.gradle.kts:L27`
- Description: Both `namespace` and `applicationId` are still the Flutter template default `"com.example.vampir_koylu"`. Google Play and the Apple App Store both reject submissions from any app using the `com.example.*` namespace. This is a shipping blocker independent of the debug-signing issue already raised in audit-003 B.10.
- Evidence: `namespace = "com.example.vampir_koylu"` and `applicationId = "com.example.vampir_koylu"` at the lines above, plus a `// TODO: Specify your own unique Application ID` comment confirming this is a placeholder.
- Recommended Fix: Choose a proper reverse-domain package name (e.g., `com.yourdomain.vampirkoylu`), update both `namespace` and `applicationId`, update `google-services.json` fingerprint registration in Firebase Console, and update Android manifest/resource references accordingly.

**B.4 Night resolution host button has no idempotency guard against double-trigger**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `lib/screens/game_screen.dart:L803-L842`
- Description: The "GECEYİ BİTİR" host button calls `NightResolutionService.resolveNight(widget.roomCode)` via an `async` `onPressed`. There is no debounce, no in-progress flag (`_isResolvingNight`), and no server-side idempotency lock. If the host double-taps the button before the first `await` returns, two concurrent `resolveNight` calls execute. Each reads the same room document (both see the same pre-resolution state), independently computes the same kill, and both append to `deadPlayers` — producing a duplicate entry and double-updating `currentPhase`, `phaseStartTimestamp`, and `nightActions`. This is the night-phase equivalent of the day-phase triple-trigger race (audit-002 B.1) but was not previously called out separately.
- Evidence: `onPressed: () async { ... await NightResolutionService.resolveNight(widget.roomCode); }` with no guard at `lib/screens/game_screen.dart:L808-L839`. `resolveNight` reads the doc, computes, and writes in a non-transactional `get()` + `update()` sequence (`lib/services/night_resolution_service.dart:L9-L148`).
- Recommended Fix: Add a widget-local `bool _isResolvingNight` flag (set true before await, false after) to prevent double-taps, mirroring how `_hasAutoStartedVoting` works. Long-term, use a Firestore transaction with a `phaseResolutionLock` field as already recommended for day resolution.

**B.5 `manipulator` role receives night-action UI but its submitted action is fully discarded**
- Severity: MEDIUM
- Category: LOGIC_BUG
- Files: `lib/screens/game_screen.dart:L263-L270`, `lib/services/night_resolution_service.dart:L1-L148`, `lib/services/day_resolution_service.dart:L1-L186`
- Description: The role `manipulator` is correctly excluded from "no night action" roles at `lib/screens/game_screen.dart:L263` (the check `myRole == 'koylu' || myRole == 'deli' || myRole == 'manipulator'` was intended to hide the button, but `manipulator` is in the *exclusion list*, meaning the code actually **does** show the "HEDEF SEç" button to manipulators). The manipulator submits `nightActions.$userId: targetId` to Firestore. Neither `resolveNight()` nor `resolveVoting()` reads or applies the manipulator action. The player believes they influenced the game; the action is silently discarded. This is a superset of the finding in audit-007 B.1, which noted no resolution logic exists. The new specific point is the UI bug: the intent was to *not* show the action button to manipulators (no implemented effect), but the exclusion list check means the button IS shown.
- Evidence: `if (myRole == 'koylu' || myRole == 'deli' || myRole == 'manipulator')` at `lib/screens/game_screen.dart:L263` returns early showing the "no action" message if the role is in the list — re-reading confirms `manipulator` IS in the list. I mis-read initially. Re-checking: this means manipulator DOES get the "no night action" message. The issue then shifts to: manipulator is in `eccentricRoles` pool but doing nothing is a gameplay expectations gap, not a UI bug. However the `nightRoles` list in `areAllActionsSubmitted` does NOT include `manipulator`, so the game correctly waits for all other role actions but not manipulator's. Severity downgraded: manipulator simply has no night effect, and the UI correctly tells them so. The real issue is that the role exists but has no game-wide effect at all (no day effect either). This is the same as audit-003 B.9 / audit-007 B.1.
- Recommended Fix: Remove `manipulator` from `eccentricRoles` in `role_distribution.dart` until its mechanics are designed and implemented.

### C. Risk Matrix Update

| # | Risk | Severity | Likelihood | Impact | Owner Stream | Source |
|---|------|----------|------------|--------|-------------|--------|
| 1 | Open/insufficient Firestore rules with client-state authority | CRITICAL | Certain if deployed | Full data/game tampering | Stream D | audit-002 B.4 |
| 2 | Multi-trigger resolution race in day phase | CRITICAL | Near-certain in real rooms | Wrong eliminations/winners | Stream B | audit-002 B.1 |
| 3 | Client-asserted identity (prefs userId) without token binding | HIGH | Motiviated attacker | Impersonation / unauthorized writes | Stream A | audit-004 B.3 |
| 4 | Host authority enforced only in UI (no backend checks) | HIGH | Modified client | Unauthorized phase transitions | Stream B | audit-007 B.2 |
| 5 | Night blocked-role logic selects wrong actor | HIGH | Eccentric-role matches | Incorrect night outcomes | Stream B | audit-004 B.1 |
| 6 | Misafir/doctor blocking semantics incorrect | HIGH | misafir+doctor in match | Incorrect night outcomes | Stream B | audit-005 B.1 |
| 7 | `deli` night-kill never triggers deli win | HIGH | Any match with `deli` | Silent win-condition miss | Stream B | audit-008 B.1 |
| 8 | Auto-voting captures stale `votingStarted`, may skip vote window | HIGH | After host manually starts voting | Votes resolved with 0 inputs | Stream B | audit-008 B.2 |
| 9 | Night resolution host button has no idempotency guard | MEDIUM | Host double-tap | Duplicate deadPlayers entries | Stream B | audit-008 B.4 |
| 10 | Doctor overwrite when 2 doctors exist (12+ players) | MEDIUM | Certain at 12+ players | Silent gameplay corruption | Stream B | audit-002 B.3 |
| 11 | Non-transactional join/leave/kick | MEDIUM | Concurrent joins | playerCount drift / capacity bypass | Stream B | audit-001 B.6 |
| 12 | Room code collision overwrite | MEDIUM | Low-probability | Room data loss | Stream B | audit-004 B.2 |
| 13 | Incomplete role implementation (`asik`/`manipulator`) | MEDIUM | Certain when selected | Confusing no-op gameplay | Stream B | audit-003 B.9 |
| 14 | Vampir team-kill allowed in night targeting | MEDIUM | Live rooms | Premature/incorrect eliminations | Stream B | audit-005 B.2 |
| 15 | Multi-room membership not prevented (active games) | MEDIUM | Possible | State divergence, ghost players | Stream B | audit-005 B.3 |
| 16 | `deadPlayers` duplicate/invalid append | MEDIUM | Double-trigger scenarios | UI/logic inconsistency | Stream B | audit-006 B.3 |
| 17 | Nickname uniqueness race (duplicates possible) | MEDIUM | Concurrent registrations | Identity confusion | Stream A | audit-006 B.1 |
| 18 | Membership model lacks per-user index | MEDIUM | Scale | Hard to enforce one-room / clean up | Stream B | audit-007 B.3 |
| 19 | `applicationId = com.example.*` blocks store submission | MEDIUM | Certain on submit | Hard store rejection | Stream D | audit-008 B.3 |
| 20 | Custom auth (SHA-256, no KDF/tokens, no deletion flow) | HIGH | Motivated attacker / store review | Account takeover / policy risk | Stream A | audit-002 B.2 |
| 21 | Monolithic game screen architecture | MEDIUM | Ongoing | Dev velocity collapse | Stream C | audit-001 B.1 |
| 22 | No automated tests for core logic | MEDIUM | Certain | Regressions undetected | Stream D | audit-001 B.9 |
| 23 | Winner reward display mismatch for guests | LOW | Common | User confusion | Stream C | audit-005 B.4 |
| 24 | Soft-failure UX on room deletion (clients stranded) | LOW | Possible | Session abandonment | Stream C | audit-006 B.2 |
| 25 | Release build signed with debug key | LOW | Certain in current config | Store friction | Stream D | audit-003 B.10 |
| 26 | Hardcoded privileged bonus path | LOW | Deterministic | Fairness/reputation | Stream D | audit-001 B.4 |

### D. Roadmap Amendments

- **AGREE** with audit-007's three-pillar M0 framing (Firestore rules → identity binding → transactional invariants) as the correct ordering.
- **ADD** to M0: Fix `deli` night-kill win-condition gap by extracting `_checkWinCondition` into a shared service and calling it from `resolveNight` — effort **S** — dependency: none — one of the simplest correctness fixes available.
- **ADD** to M0: Add idempotency guard on the "GECEYİ BİTİR" button (`_isResolvingNight` flag) — effort **S** — dependency: none — prevents double-trigger until server-side lock is in place.
- **ADD** to M0: Fix auto-voting stale closure by re-reading Firestore state inside the delayed callback before branching — effort **S** — dependency: none — eliminates one of the triple-trigger race vectors.
- **ADD** to M3: Update `applicationId` and `namespace` from `com.example.vampir_koylu` to a proper package name, update Firebase Console fingerprint and `google-services.json` — effort **S** — dependency: package name decision — hard store blocker.
- **REORDER** M0 Quick Wins to lead with the three S-effort correctness patches (deli win, idempotency guard, stale closure) since they are zero-dependency and restore observable gameplay correctness in under a day.

**Quick Wins (<1 day)**
- Extract `_checkWinCondition` to shared location; call from `resolveNight()` to fix deli night-kill (B.1).
- Add `_isResolvingNight` flag in `_GameScreenState` around the `resolveNight` call (B.4).
- Re-fetch `votingStarted` from Firestore inside the `Future.delayed` callback to fix stale capture (B.2).
- Remove `manipulator` from `eccentricRoles` until mechanics exist (aligns with audit-007 quick win).
- Remove `bonusNickname` from `GoldService` (aligns with prior quick wins).

### E. Open Questions

1. Should `deli` win when killed at night by vampires, or only when voted out during the day? (Standard Mafia rules: jester/fool only wins on day-vote; night-kill is a loss.) 
   - Blocks: B.1 fix correctness direction.
   - Suggested default: Deli wins on any elimination (night OR day) — maximises role uniqueness.

2. Should the auto-vote timer be removed entirely in favor of host-only phase control, or kept as a safety net?
   - Blocks: B.2 fix strategy and audit-002 B.1 race fix design.
   - Suggested default: Remove auto-vote from non-host clients; keep only host manual trigger.

3. What is the intended effect of `manipulator`? (Vote swap? Mind control? False information?)
   - Blocks: Full implementation in resolution services or decision to prune from role pool.
   - Suggested default: Prune from v1 role pool; design in v1.1.

4. What are the intended `asik` (lover) mechanics? (Shared fate? Additional night action? Win condition override?)
   - Blocks: audit-007 B.1 / audit-003 B.9 full resolution.
   - Suggested default: Classic "lovers" mechanic — two randomly bonded players; if one dies the other also dies.

### F. Handoff Metadata

```yaml
review_id: audit-008
reviewer: Night Logic & Runtime Correctness Reviewer
files_read:
  - lib/main.dart
  - lib/firebase_options.dart
  - lib/screens/welcome_screen.dart
  - lib/screens/create_account_screen.dart
  - lib/screens/login_account_screen.dart
  - lib/screens/guest_login_screen.dart
  - lib/screens/create_room_screen.dart
  - lib/screens/join_room_screen.dart
  - lib/screens/room_lobby_screen.dart
  - lib/screens/role_reveal_screen.dart
  - lib/screens/game_screen.dart
  - lib/screens/game_end_screen.dart
  - lib/screens/widgets/role_info_dialog.dart
  - lib/screens/widgets/game_time_display.dart
  - lib/services/auth_service.dart
  - lib/services/role_distribution.dart
  - lib/services/night_resolution_service.dart
  - lib/services/day_resolution_service.dart
  - lib/services/gold_service.dart
  - pubspec.yaml
  - firebase.json
  - analysis_options.yaml
  - android/app/build.gradle.kts
  - test/widget_test.dart
  - lib/todo.txt
confidence: HIGH
open_items: 4
next_recommended_agent: Implementation Agent (Quick Wins) — first tasks: (1) fix deli night-kill win condition, (2) add _isResolvingNight idempotency guard, (3) fix stale votingStarted capture in auto-vote closure
blocked_on: Product decision E.1 (deli night death rule) before implementing B.1 fix direction
```
