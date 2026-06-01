import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Vampir Köylü shared constants + match/private models for the new
/// seat-based schema:
///   rooms/{code}/matches/{matchId}              public match state (host-write)
///   rooms/{code}/matches/{matchId}/private/{s}  secret per-seat role/state
///   rooms/{code}/matches/{matchId}/actions/{s}  per-seat night target / vote
class VampirPhase {
  static const roleReveal = 'role_reveal';
  static const night = 'night';
  static const day = 'day';
  static const finished = 'finished';
}

/// Roles that act at night (submit a target). Used for "all submitted" checks.
const vampirNightRoles = [
  'vampir',
  'doktor',
  'dedektif',
  'misafir',
  'polis',
  'takipci',
  'asik',
];

const vampirRoleIcons = {
  'vampir': '🧛',
  'koylu': '👨‍🌾',
  'doktor': '🏥',
  'asik': '💘',
  'deli': '🤪',
  'dedektif': '🔍',
  'misafir': '🏠',
  'polis': '👮',
  'takipci': '👣',
  'manipulator': '🎭',
};

const vampirRoleColors = {
  'vampir': Color(0xFFDC143C),
  'koylu': Color(0xFF32CD32),
  'doktor': Color(0xFF1E90FF),
  'asik': Color(0xFFFF69B4),
  'deli': Color(0xFFFF8C00),
  'dedektif': Color(0xFFFFD700),
  'misafir': Color(0xFF9370DB),
  'polis': Color(0xFF00CED1),
  'takipci': Color(0xFFCD853F),
  'manipulator': Color(0xFF8A2BE2),
};

Color vampirRoleColor(String role) => vampirRoleColors[role] ?? Colors.white;
String vampirRoleIcon(String role) => vampirRoleIcons[role] ?? '❓';

/// Public match document. Holds everything that is NOT secret per-seat.
class VampirMatch {
  final String matchId;
  final String gameMode; // 'classic' | 'eccentric'
  final String phase;
  final int nightNumber;
  final int voteRound;
  final bool votingStarted;
  final String phaseTime;
  final Timestamp? phaseStartTimestamp;
  final List<String> seatIds;
  final List<String> deadSeats;
  final Map<String, dynamic>? nightResults;
  final Map<String, dynamic>? lastEliminated;
  final Map<String, dynamic>? lastTie;
  final String? winner;
  final List<String> winnerIds;
  final Map<String, String> finalRoles;

  const VampirMatch({
    required this.matchId,
    required this.gameMode,
    required this.phase,
    required this.nightNumber,
    required this.voteRound,
    required this.votingStarted,
    required this.phaseTime,
    required this.phaseStartTimestamp,
    required this.seatIds,
    required this.deadSeats,
    this.nightResults,
    this.lastEliminated,
    this.lastTie,
    this.winner,
    this.winnerIds = const [],
    this.finalRoles = const {},
  });

  bool isAlive(String seatId) => !deadSeats.contains(seatId);
  bool get isFinished => phase == VampirPhase.finished;

  factory VampirMatch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return VampirMatch(
      matchId: doc.id,
      gameMode: d['gameMode'] ?? 'classic',
      phase: d['phase'] ?? VampirPhase.night,
      nightNumber: d['nightNumber'] ?? 1,
      voteRound: d['voteRound'] ?? 0,
      votingStarted: d['votingStarted'] ?? false,
      phaseTime: d['phaseTime'] ?? '21:00',
      phaseStartTimestamp: d['phaseStartTimestamp'] as Timestamp?,
      seatIds: List<String>.from(d['seatIds'] ?? []),
      deadSeats: List<String>.from(d['deadSeats'] ?? []),
      nightResults: (d['nightResults'] as Map?)?.cast<String, dynamic>(),
      lastEliminated: (d['lastEliminated'] as Map?)?.cast<String, dynamic>(),
      lastTie: (d['lastTie'] as Map?)?.cast<String, dynamic>(),
      winner: d['winner'] as String?,
      winnerIds: List<String>.from(d['winnerIds'] ?? []),
      finalRoles: (d['finalRoles'] as Map?)?.map(
              (k, v) => MapEntry(k as String, v as String)) ??
          const {},
    );
  }
}

/// Secret per-seat state at matches/{matchId}/private/{seatId}.
class VampirPrivate {
  final String seatId;
  final String role;
  final String? asikTarget;
  final bool asikKinlendi;
  final bool dedektifUsed;
  final bool selfProtectUsed;
  final String? dedektifResult; // role string the detective learned
  final String? dedektifResultTarget; // seatId investigated
  final List<String> team; // vampire teammates (vampires only)

  const VampirPrivate({
    required this.seatId,
    required this.role,
    this.asikTarget,
    this.asikKinlendi = false,
    this.dedektifUsed = false,
    this.selfProtectUsed = false,
    this.dedektifResult,
    this.dedektifResultTarget,
    this.team = const [],
  });

  factory VampirPrivate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return VampirPrivate(
      seatId: doc.id,
      role: d['role'] ?? 'unknown',
      asikTarget: d['asikTarget'] as String?,
      asikKinlendi: d['asikKinlendi'] ?? false,
      dedektifUsed: d['dedektifUsed'] ?? false,
      selfProtectUsed: d['selfProtectUsed'] ?? false,
      dedektifResult: d['dedektifResult'] as String?,
      dedektifResultTarget: d['dedektifResultTarget'] as String?,
      team: List<String>.from(d['team'] ?? const []),
    );
  }
}
