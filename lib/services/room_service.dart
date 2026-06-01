import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../games/game_definition.dart';
import '../games/game_registry.dart';
import '../models/room.dart';
import '../models/seat.dart';

/// Game-agnostic room/lobby operations on the new seat-based schema.
class RoomService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _codeChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

  static String _genCode() {
    final r = Random();
    return List.generate(6, (_) => _codeChars[r.nextInt(_codeChars.length)]).join();
  }

  static String _genSeatId() {
    final r = Random();
    return 'seat_${List.generate(8, (_) => _codeChars[r.nextInt(_codeChars.length)]).join()}';
  }

  static DocumentReference<Map<String, dynamic>> roomRef(String code) =>
      _db.collection('rooms').doc(code);

  static Stream<Room> watchRoom(String code) =>
      roomRef(code).snapshots().map((d) => Room.fromDoc(d));

  /// Create a room. The host occupies the first seat (seatId == hostUid in both
  /// modes). Returns the room code, or throws on repeated collision.
  static Future<String> createRoom({
    required String gameId,
    required PlayMode mode,
    required int maxSeats,
    required String hostUid,
    required String hostDisplayName,
    required String hostAvatarColor,
    String? password,
    Map<String, dynamic> config = const {},
  }) async {
    final hostSeat = Seat(
      seatId: hostUid,
      displayName: hostDisplayName,
      avatarColor: hostAvatarColor,
      deviceUid: hostUid,
      isHost: true,
    );

    for (var attempt = 0; attempt < 5; attempt++) {
      final code = _genCode();
      final ref = roomRef(code);
      final ok = await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (snap.exists) return false;
        tx.set(ref, {
          'gameId': gameId,
          'hostUid': hostUid,
          'mode': mode.id,
          'status': RoomStatus.lobby,
          'maxSeats': maxSeats,
          'hasPassword': password != null && password.isNotEmpty,
          'password': (password != null && password.isNotEmpty) ? password : null,
          'seats': {hostUid: hostSeat.toMap()},
          'config': config,
          'currentMatchId': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
      if (ok) return code;
    }
    throw Exception('Oda oluşturulamadı (kod çakışması)');
  }

  /// Multi-phone: a remote player joins by adding their own seat (seatId == uid).
  /// Returns null on success, or an error message.
  static Future<String?> joinRoom({
    required String code,
    required String uid,
    required String displayName,
    required String avatarColor,
    String? password,
  }) async {
    final ref = roomRef(code);
    return _db.runTransaction<String?>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return 'Oda bulunamadı';
      final data = snap.data()!;

      if (data['status'] != RoomStatus.lobby) return 'Oyun zaten başladı';
      if ((data['password'] ?? '') != '' && data['password'] != password) {
        return 'Yanlış şifre';
      }
      final seats = Map<String, dynamic>.from(data['seats'] ?? {});
      if (seats.containsKey(uid)) return null; // already in
      if (seats.length >= (data['maxSeats'] ?? 0)) return 'Oda dolu';

      final seat = Seat(
        seatId: uid,
        displayName: displayName,
        avatarColor: avatarColor,
        deviceUid: uid,
      );
      tx.update(ref, {'seats.$uid': seat.toMap()});
      return null;
    });
  }

  /// Single-phone: the host adds a local seat (deviceUid == host uid).
  static Future<String?> addLocalSeat({
    required String code,
    required String hostUid,
    required String displayName,
    required String avatarColor,
  }) async {
    final ref = roomRef(code);
    return _db.runTransaction<String?>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return 'Oda bulunamadı';
      final data = snap.data()!;
      final seats = Map<String, dynamic>.from(data['seats'] ?? {});
      if (seats.length >= (data['maxSeats'] ?? 0)) return 'Oda dolu';

      final seatId = _genSeatId();
      final seat = Seat(
        seatId: seatId,
        displayName: displayName,
        avatarColor: avatarColor,
        deviceUid: hostUid,
      );
      tx.update(ref, {'seats.$seatId': seat.toMap()});
      return null;
    });
  }

  /// Remove a seat (leave / kick).
  static Future<void> removeSeat({required String code, required String seatId}) =>
      roomRef(code).update({'seats.$seatId': FieldValue.delete()});

  static Future<void> closeRoom(String code) => roomRef(code).delete();

  /// Host starts a match: creates the match doc, lets the game's resolver
  /// assign secret state, then flips the room into `in_match`.
  static Future<String> startMatch(String code) async {
    final snap = await roomRef(code).get();
    final room = Room.fromDoc(snap);
    final game = GameRegistry.byId(room.gameId);
    if (game == null) throw Exception('Bilinmeyen oyun: ${room.gameId}');

    final matchId = roomRef(code).collection('matches').doc().id;
    final ctx = MatchContext(
      roomCode: code,
      matchId: matchId,
      mode: room.mode,
      config: room.config,
    );

    final seatIds = room.seats.keys.toList();
    await game.resolver.startMatch(ctx, seatIds);

    await roomRef(code).update({
      'status': RoomStatus.inMatch,
      'currentMatchId': matchId,
    });
    debugPrint('✅ Match started: $code / $matchId');
    return matchId;
  }
}
