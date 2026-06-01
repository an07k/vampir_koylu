import 'package:cloud_firestore/cloud_firestore.dart';
import '../games/game_definition.dart';
import 'seat.dart';

class RoomStatus {
  static const lobby = 'lobby';
  static const inMatch = 'in_match';
  static const finished = 'finished';
}

/// Game-agnostic lobby document at `rooms/{roomCode}`. The `seats` map holds
/// only public info; secret state lives under `matches/{matchId}/private`.
class Room {
  final String roomCode;
  final String gameId;
  final String hostUid;
  final PlayMode mode;
  final String status;
  final int maxSeats;
  final bool hasPassword;
  final Map<String, Seat> seats;
  final Map<String, dynamic> config;
  final String? currentMatchId;

  const Room({
    required this.roomCode,
    required this.gameId,
    required this.hostUid,
    required this.mode,
    required this.status,
    required this.maxSeats,
    required this.hasPassword,
    required this.seats,
    required this.config,
    this.currentMatchId,
  });

  int get seatCount => seats.length;
  bool get isFull => seatCount >= maxSeats;

  factory Room.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawSeats = Map<String, dynamic>.from(data['seats'] ?? {});
    final seats = rawSeats.map(
      (id, v) => MapEntry(id, Seat.fromMap(id, Map<String, dynamic>.from(v))),
    );
    return Room(
      roomCode: doc.id,
      gameId: data['gameId'] ?? '',
      hostUid: data['hostUid'] ?? '',
      mode: PlayModeId.fromId(data['mode'] ?? 'multi'),
      status: data['status'] ?? RoomStatus.lobby,
      maxSeats: data['maxSeats'] ?? 0,
      hasPassword: data['hasPassword'] ?? false,
      seats: seats,
      config: Map<String, dynamic>.from(data['config'] ?? {}),
      currentMatchId: data['currentMatchId'],
    );
  }
}
