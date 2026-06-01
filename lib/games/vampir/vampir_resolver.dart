import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../game_definition.dart';
import '../../services/gold_service.dart';
import '../../services/statistics_service.dart';
import '../../services/role_distribution.dart';
import 'vampir_match.dart';

/// Host-authoritative Vampir Köylü logic on the seat-based schema.
///
/// Roles live in matches/{matchId}/private/{seatId} (host-written so opponents
/// can't read each other's roles). Player night targets / day votes live in
/// matches/{matchId}/actions/{seatId} (owner-writable). The host reads both to
/// resolve a phase and writes the public match doc + private docs back.
class VampirResolver implements GameResolver {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _matchRef(String code, String matchId) =>
      _db.collection('rooms').doc(code).collection('matches').doc(matchId);

  CollectionReference<Map<String, dynamic>> _privateCol(String code, String matchId) =>
      _matchRef(code, matchId).collection('private');

  CollectionReference<Map<String, dynamic>> _actionsCol(String code, String matchId) =>
      _matchRef(code, matchId).collection('actions');

  bool _isBot(String seatId) => seatId.startsWith('bot_');

  // ---- start ---------------------------------------------------------------

  @override
  Future<void> startMatch(MatchContext ctx, List<String> seatIds) async {
    final gameMode = (ctx.config['gameMode'] as String?) ?? 'classic';
    final roles = RoleDistribution.assignRoles(seatIds, gameMode);
    final vampireTeam =
        roles.entries.where((e) => e.value == 'vampir').map((e) => e.key).toList();

    final batch = _db.batch();
    final matchRef = _matchRef(ctx.roomCode, ctx.matchId);
    batch.set(matchRef, {
      'gameId': 'vampir',
      'gameMode': gameMode,
      'phase': VampirPhase.night,
      'nightNumber': 1,
      'voteRound': 0,
      'votingStarted': false,
      'phaseTime': '21:00',
      'phaseStartTimestamp': FieldValue.serverTimestamp(),
      'seatIds': seatIds,
      'deadSeats': <String>[],
      'startedAt': FieldValue.serverTimestamp(),
    });
    roles.forEach((seatId, role) {
      batch.set(_privateCol(ctx.roomCode, ctx.matchId).doc(seatId), {
        'role': role,
        'asikKinlendi': false,
        'dedektifUsed': false,
        'selfProtectUsed': false,
        // Teammates are written into each vampire's own private doc so they can
        // identify each other without being able to read others' roles.
        if (role == 'vampir') 'team': vampireTeam,
      });
    });
    await batch.commit();
    debugPrint('🧛 Vampir match started: ${roles.length} roles assigned');
  }

  // ---- player actions ------------------------------------------------------

  Future<void> submitNight(
    String code,
    String matchId,
    String seatId,
    String target,
    int nightNumber,
  ) {
    return _actionsCol(code, matchId).doc(seatId).set({
      'nightTarget': target,
      'nightRound': nightNumber,
    }, SetOptions(merge: true));
  }

  Future<void> submitVote(
    String code,
    String matchId,
    String seatId,
    String target,
    int voteRound,
  ) {
    return _actionsCol(code, matchId).doc(seatId).set({
      'dayVote': target,
      'voteRound': voteRound,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> submitAction(
    MatchContext ctx,
    String seatId,
    Map<String, dynamic> action,
  ) async {
    await _actionsCol(ctx.roomCode, ctx.matchId)
        .doc(seatId)
        .set(action, SetOptions(merge: true));
  }

  @override
  Future<void> resolvePhase(MatchContext ctx) async {
    final snap = await _matchRef(ctx.roomCode, ctx.matchId).get();
    final match = VampirMatch.fromDoc(snap);
    if (match.phase == VampirPhase.night) {
      await resolveNight(ctx.roomCode, ctx.matchId);
    } else if (match.phase == VampirPhase.day) {
      await resolveDay(ctx.roomCode, ctx.matchId);
    }
  }

  // ---- data fetch helpers --------------------------------------------------

  Future<Map<String, Map<String, dynamic>>> _fetchPrivate(
      String code, String matchId) async {
    final qs = await _privateCol(code, matchId).get();
    return {for (final d in qs.docs) d.id: d.data()};
  }

  /// seatId -> nightTarget for the given night.
  Future<Map<String, String>> _fetchNightTargets(
      String code, String matchId, int nightNumber) async {
    final qs = await _actionsCol(code, matchId).get();
    final out = <String, String>{};
    for (final d in qs.docs) {
      final data = d.data();
      if (data['nightRound'] == nightNumber && data['nightTarget'] is String) {
        out[d.id] = data['nightTarget'] as String;
      }
    }
    return out;
  }

  /// seatId -> dayVote for the given vote round.
  Future<Map<String, String>> _fetchVotes(
      String code, String matchId, int voteRound) async {
    final qs = await _actionsCol(code, matchId).get();
    final out = <String, String>{};
    for (final d in qs.docs) {
      final data = d.data();
      if (data['voteRound'] == voteRound && data['dayVote'] is String) {
        out[d.id] = data['dayVote'] as String;
      }
    }
    return out;
  }

  // ---- bots ----------------------------------------------------------------

  Future<void> autoSubmitBotNight(String code, String matchId) async {
    final snap = await _matchRef(code, matchId).get();
    final match = VampirMatch.fromDoc(snap);
    final priv = await _fetchPrivate(code, matchId);
    final rnd = Random();
    final alive = match.seatIds.where((s) => match.isAlive(s)).toList();

    for (final seatId in match.seatIds) {
      if (!_isBot(seatId) || !match.isAlive(seatId)) continue;
      final role = priv[seatId]?['role'];
      if (!vampirNightRoles.contains(role)) continue;
      final targets = alive.where((s) => s != seatId).toList();
      if (targets.isEmpty) continue;
      await submitNight(code, matchId, seatId,
          targets[rnd.nextInt(targets.length)], match.nightNumber);
    }
  }

  Future<void> autoSubmitBotVotes(String code, String matchId) async {
    final snap = await _matchRef(code, matchId).get();
    final match = VampirMatch.fromDoc(snap);
    final rnd = Random();
    final alive = match.seatIds.where((s) => match.isAlive(s)).toList();

    for (final seatId in match.seatIds) {
      if (!_isBot(seatId) || !match.isAlive(seatId)) continue;
      final targets = alive.where((s) => s != seatId).toList();
      if (targets.isEmpty) continue;
      await submitVote(code, matchId, seatId,
          targets[rnd.nextInt(targets.length)], match.voteRound);
    }
  }

  /// Whether every real (non-bot) seat that owes a night action has submitted.
  Future<bool> areAllNightActionsSubmitted(String code, String matchId) async {
    final snap = await _matchRef(code, matchId).get();
    final match = VampirMatch.fromDoc(snap);
    final priv = await _fetchPrivate(code, matchId);
    final targets = await _fetchNightTargets(code, matchId, match.nightNumber);

    final required = match.seatIds.where((seatId) {
      if (_isBot(seatId) || !match.isAlive(seatId)) return false;
      final p = priv[seatId];
      final role = p?['role'];
      if (role == 'asik') {
        final hasTarget = p?['asikTarget'] != null;
        final isKinlendi = p?['asikKinlendi'] == true;
        return !(hasTarget && !isKinlendi);
      }
      if (role == 'dedektif') {
        return p?['dedektifUsed'] != true;
      }
      return vampirNightRoles.contains(role);
    }).toList();

    if (required.isEmpty) return true;
    return required.every((seatId) => targets.containsKey(seatId));
  }

  // ---- night resolution ----------------------------------------------------

  Future<void> resolveNight(String code, String matchId) async {
    final matchRef = _matchRef(code, matchId);
    final snap = await matchRef.get();
    final match = VampirMatch.fromDoc(snap);
    final priv = await _fetchPrivate(code, matchId);
    final nightActions = await _fetchNightTargets(code, matchId, match.nightNumber);
    final deadSeats = [...match.deadSeats];
    final nightNumber = match.nightNumber;

    String roleOf(String? id) => (id == null ? null : priv[id]?['role']) ?? '';

    final alive = match.seatIds.where((s) => !deadSeats.contains(s)).toList();

    // role -> actor / target (doctor handled separately, can be multiple)
    final roleActors = <String, String>{};
    final roleTargets = <String, String>{};
    final doctorActions = <String, String>{};
    for (final seatId in nightActions.keys) {
      final r = roleOf(seatId);
      if (r.isEmpty) continue;
      if (r == 'doktor') {
        doctorActions[seatId] = nightActions[seatId]!;
      } else {
        roleActors[r] = seatId;
        roleTargets[r] = nightActions[seatId]!;
      }
    }

    // private doc updates to apply at the end: seatId -> field map
    final privUpdates = <String, Map<String, dynamic>>{};
    void privSet(String seatId, String field, dynamic value) {
      (privUpdates[seatId] ??= {})[field] = value;
    }

    // Âşık permanent target (first pick)
    final asikActorId = roleActors['asik'];
    final asikTarget = roleTargets['asik'];
    final existingAsikTarget = asikActorId != null
        ? (priv[asikActorId]?['asikTarget'] as String?)
        : null;
    if (asikActorId != null &&
        asikTarget != null &&
        existingAsikTarget == null) {
      privSet(asikActorId, 'asikTarget', asikTarget);
      priv[asikActorId] = {...?priv[asikActorId], 'asikTarget': asikTarget};
    }

    // Vampire target = most-voted among vampire night actions
    String? vampirTarget;
    final vampirVotes = <String, int>{};
    for (final seatId in nightActions.keys) {
      if (roleOf(seatId) == 'vampir') {
        final t = nightActions[seatId]!;
        vampirVotes[t] = (vampirVotes[t] ?? 0) + 1;
      }
    }
    if (vampirVotes.isNotEmpty) {
      vampirTarget =
          vampirVotes.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    // Misafir blocks the visited seat
    final misafirTarget = roleTargets['misafir'];
    final blocked = <String>{};
    if (misafirTarget != null) blocked.add(misafirTarget);

    // Doctor protection (unless that doctor is blocked)
    final protectedSeats = <String>{};
    for (final docId in doctorActions.keys) {
      if (!blocked.contains(docId)) {
        protectedSeats.add(doctorActions[docId]!);
      }
    }

    // Vampire kill
    String? killedSeat;
    if (vampirTarget != null) {
      final vampirsBlocked = alive
          .where((id) => roleOf(id) == 'vampir')
          .any((id) => blocked.contains(id));
      if (!vampirsBlocked && !protectedSeats.contains(vampirTarget)) {
        killedSeat = vampirTarget;
        deadSeats.add(killedSeat);
      }
    }

    // Kinlendi âşık night kill
    String? kinlendiKill;
    if (asikActorId != null && !deadSeats.contains(asikActorId)) {
      final isKinlendi = priv[asikActorId]?['asikKinlendi'] == true;
      final kinlendiTarget =
          isKinlendi ? (roleTargets['asik'] ?? existingAsikTarget) : null;
      if (isKinlendi &&
          kinlendiTarget != null &&
          !deadSeats.contains(kinlendiTarget)) {
        if (!protectedSeats.contains(kinlendiTarget)) {
          kinlendiKill = kinlendiTarget;
          deadSeats.add(kinlendiTarget);
        }
        deadSeats.add(asikActorId);
      }
    }

    // Âşık target died this night?
    String? asikEffect;
    final savedTarget = asikActorId != null
        ? (priv[asikActorId]?['asikTarget'] as String?)
        : null;
    if (asikActorId != null &&
        savedTarget != null &&
        !deadSeats.contains(asikActorId) &&
        kinlendiKill != savedTarget) {
      final newlyDead = !match.deadSeats.contains(savedTarget) &&
          deadSeats.contains(savedTarget);
      if (killedSeat == savedTarget || kinlendiKill == savedTarget || newlyDead) {
        final tRole = roleOf(savedTarget);
        if (tRole == 'vampir') {
          deadSeats.add(asikActorId);
          asikEffect = 'intihar';
        } else if (tRole == 'deli') {
          asikEffect = 'deli_devir';
        } else {
          asikEffect = 'kinlendi';
        }
      }
    }

    // Win check after night kills
    if (killedSeat != null || kinlendiKill != null) {
      final winner = _checkWin(priv, match.seatIds, deadSeats, null);
      if (winner != null) {
        await _endGame(code, matchId, match, winner, deadSeats);
        return;
      }
    }

    // Detective investigation (one-time use)
    String? dedektifResult;
    final dedektifTarget = roleTargets['dedektif'];
    final dedektifActorId = roleActors['dedektif'];
    if (dedektifTarget != null &&
        dedektifActorId != null &&
        !blocked.contains(dedektifActorId)) {
      dedektifResult = roleOf(dedektifTarget);
      privSet(dedektifActorId, 'dedektifUsed', true);
      privSet(dedektifActorId, 'dedektifResult', dedektifResult);
      privSet(dedektifActorId, 'dedektifResultTarget', dedektifTarget);
    }

    // Police watch
    List<String>? polisVisitors;
    final polisTarget = roleTargets['polis'];
    final polisActorId = roleActors['polis'];
    if (polisTarget != null &&
        polisActorId != null &&
        !blocked.contains(polisActorId)) {
      polisVisitors = nightActions.entries
          .where((e) => e.value == polisTarget && roleOf(e.key) != 'polis')
          .map((e) => e.key)
          .toList();
    }

    // Takipçi
    String? takipciResult;
    final takipciTarget = roleTargets['takipci'];
    final takipciActorId = roleActors['takipci'];
    if (takipciTarget != null &&
        takipciActorId != null &&
        !blocked.contains(takipciActorId)) {
      takipciResult = nightActions[takipciTarget];
    }

    // Âşık state changes
    if (asikEffect == 'kinlendi') {
      privSet(asikActorId!, 'asikKinlendi', true);
    } else if (asikEffect == 'deli_devir') {
      privSet(asikActorId!, 'role', 'deli');
    }
    if (priv[asikActorId]?['asikKinlendi'] == true && kinlendiKill != null) {
      privSet(asikActorId!, 'asikKinlendi', false);
    }

    final matchUpdates = <String, dynamic>{
      'deadSeats': deadSeats,
      'phase': VampirPhase.day,
      'phaseTime': '09:00',
      'votingStarted': true,
      'voteRound': match.voteRound + 1,
      'nightResults': {
        'nightNumber': nightNumber,
        'killed': killedSeat,
        'dedektif_target': dedektifTarget,
        'dedektif_result': dedektifResult,
        'polis_target': polisTarget,
        'polis_visitors': polisVisitors,
        'takipci_target': takipciTarget,
        'takipci_result': takipciResult,
        'asik_effect': asikEffect,
        'kinlendi_kill': kinlendiKill,
      },
      'lastEliminated': FieldValue.delete(),
      'lastTie': FieldValue.delete(),
    };

    final batch = _db.batch();
    batch.update(matchRef, matchUpdates);
    privUpdates.forEach((seatId, fields) {
      batch.set(_privateCol(code, matchId).doc(seatId), fields,
          SetOptions(merge: true));
    });
    await batch.commit();
    debugPrint('✅ Night $nightNumber resolved');
  }

  // ---- day (voting) resolution ---------------------------------------------

  Future<void> resolveDay(String code, String matchId) async {
    final matchRef = _matchRef(code, matchId);
    final snap = await matchRef.get();
    final match = VampirMatch.fromDoc(snap);
    final priv = await _fetchPrivate(code, matchId);
    final votes = await _fetchVotes(code, matchId, match.voteRound);
    final deadSeats = [...match.deadSeats];

    String roleOf(String? id) => (id == null ? null : priv[id]?['role']) ?? '';

    final voteCounts = <String, int>{};
    for (final target in votes.values) {
      voteCounts[target] = (voteCounts[target] ?? 0) + 1;
    }

    if (voteCounts.isEmpty) {
      await matchRef.update({
        'votingStarted': false,
        'phaseStartTimestamp': FieldValue.serverTimestamp(),
      });
      return;
    }

    final maxVotes = voteCounts.values.reduce((a, b) => a > b ? a : b);
    final victims = voteCounts.entries.where((e) => e.value == maxVotes).toList();

    if (victims.length > 1) {
      // Tie -> new voting round
      await matchRef.update({
        'votingStarted': true,
        'voteRound': match.voteRound + 1,
        'lastTie': {
          'tiedPlayerIds': victims.map((e) => e.key).toList(),
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
      return;
    }

    final eliminatedId = victims.first.key;
    final eliminatedRole = roleOf(eliminatedId);
    deadSeats.add(eliminatedId);

    final winner = _checkWin(priv, match.seatIds, deadSeats, eliminatedRole);
    if (winner != null) {
      await _endGame(code, matchId, match, winner, deadSeats);
      return;
    }

    // Âşık daytime-elimination effect
    final privUpdates = <String, Map<String, dynamic>>{};
    for (final seatId in match.seatIds.where((s) => !deadSeats.contains(s))) {
      if (roleOf(seatId) == 'asik' &&
          priv[seatId]?['asikTarget'] == eliminatedId) {
        if (eliminatedRole == 'vampir') {
          deadSeats.add(seatId);
          privUpdates[seatId] = {'asikEffect': 'intihar_gunduz'};
        } else if (eliminatedRole != 'deli') {
          privUpdates[seatId] = {'asikKinlendi': true};
        }
      }
    }

    if (privUpdates.isNotEmpty) {
      final w2 = _checkWin(priv, match.seatIds, deadSeats, null);
      if (w2 != null) {
        await _endGame(code, matchId, match, w2, deadSeats);
        return;
      }
    }

    final batch = _db.batch();
    batch.update(matchRef, {
      'deadSeats': deadSeats,
      'votingStarted': false,
      'phaseStartTimestamp': FieldValue.serverTimestamp(),
      'lastEliminated': {
        'id': eliminatedId,
        'timestamp': FieldValue.serverTimestamp(),
      },
    });
    privUpdates.forEach((seatId, fields) {
      batch.set(_privateCol(code, matchId).doc(seatId), fields,
          SetOptions(merge: true));
    });
    await batch.commit();
    debugPrint('☀️ Day vote resolved: $eliminatedId eliminated');
  }

  Future<void> advanceToNight(String code, String matchId) async {
    final snap = await _matchRef(code, matchId).get();
    final nightNumber = snap.data()?['nightNumber'] ?? 1;
    await _matchRef(code, matchId).update({
      'phase': VampirPhase.night,
      'phaseTime': '21:00',
      'nightNumber': nightNumber + 1,
      'votingStarted': false,
    });
  }

  // ---- win conditions ------------------------------------------------------

  String? _checkWin(
    Map<String, Map<String, dynamic>> priv,
    List<String> seatIds,
    List<String> deadSeats,
    String? eliminatedRole,
  ) {
    if (eliminatedRole == 'deli') return 'deli';

    final alive = seatIds.where((s) => !deadSeats.contains(s));
    int vampir = 0, town = 0;
    for (final id in alive) {
      if (priv[id]?['role'] == 'vampir') {
        vampir++;
      } else {
        town++;
      }
    }
    if (vampir == 0) return 'koylu';
    if (vampir >= town) return 'vampir';
    return null;
  }

  Future<void> _endGame(
    String code,
    String matchId,
    VampirMatch match,
    String winner,
    List<String> deadSeats,
  ) async {
    final winnerIds = <String>[];
    final priv = await _fetchPrivate(code, matchId);
    String roleOf(String id) => priv[id]?['role'] ?? '';

    if (winner == 'deli') {
      for (final id in match.seatIds) {
        if (roleOf(id) == 'deli') {
          winnerIds.add(id);
          break;
        }
      }
    } else if (winner == 'vampir') {
      for (final id in match.seatIds) {
        if (!deadSeats.contains(id) && roleOf(id) == 'vampir') winnerIds.add(id);
      }
    } else if (winner == 'koylu') {
      for (final id in match.seatIds) {
        if (!deadSeats.contains(id) && roleOf(id) != 'vampir') winnerIds.add(id);
      }
    }

    // Gold + stats only make sense for real seats whose seatId == a user uid
    // (multi-phone). Services already skip bot_ ids; guard empty list.
    final realWinners = winnerIds.where((id) => !_isBot(id)).toList();
    if (realWinners.isNotEmpty) {
      await GoldService.awardWinGold(realWinners);
    }
    final realPlayers = match.seatIds.where((id) => !_isBot(id)).toList();
    if (realPlayers.isNotEmpty) {
      await StatisticsService.recordGameResult(
        winnerIds: realWinners,
        allPlayerIds: realPlayers,
      );
    }

    final finalRoles = {
      for (final id in match.seatIds) id: roleOf(id),
    };

    await _matchRef(code, matchId).update({
      'phase': VampirPhase.finished,
      'winner': winner,
      'winnerIds': winnerIds,
      'deadSeats': deadSeats,
      'finalRoles': finalRoles,
    });
    debugPrint('🏆 Match finished. Winner: $winner ($winnerIds)');
  }
}
