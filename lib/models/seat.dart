/// A seat in a room. In multi-phone mode `seatId == deviceUid` (the player's
/// uid). In single-phone mode the host creates seats with generated ids and
/// every `deviceUid` equals the host uid.
class Seat {
  final String seatId;
  final String displayName;
  final String avatarColor;
  final String deviceUid;
  final bool isHost;

  const Seat({
    required this.seatId,
    required this.displayName,
    required this.avatarColor,
    required this.deviceUid,
    this.isHost = false,
  });

  Map<String, dynamic> toMap() => {
        'displayName': displayName,
        'avatarColor': avatarColor,
        'deviceUid': deviceUid,
        'isHost': isHost,
      };

  factory Seat.fromMap(String seatId, Map<String, dynamic> map) => Seat(
        seatId: seatId,
        displayName: map['displayName'] ?? '',
        avatarColor: map['avatarColor'] ?? '#DC143C',
        deviceUid: map['deviceUid'] ?? '',
        isHost: map['isHost'] ?? false,
      );
}
