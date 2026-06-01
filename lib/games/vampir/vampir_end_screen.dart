import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../constants/app_l10n.dart';
import '../../models/room.dart';
import '../../models/seat.dart';
import '../../services/room_service.dart';
import 'vampir_match.dart';

/// Shown once a Vampir Köylü match reaches the `finished` phase. Reads the
/// public match doc for the winner + revealed `finalRoles` (no private docs,
/// so it works under strict rules too) and the room for seat display names.
class VampirEndScreen extends StatelessWidget {
  final String roomCode;
  final String matchId;
  final String seatId;

  const VampirEndScreen({
    super.key,
    required this.roomCode,
    required this.matchId,
    required this.seatId,
  });

  Future<void> _leave(BuildContext context, Room room) async {
    if (seatId == room.hostUid) {
      await RoomService.closeRoom(roomCode);
    }
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/main-menu', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Room>(
      stream: RoomService.watchRoom(roomCode),
      builder: (context, roomSnap) {
        return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('rooms')
              .doc(roomCode)
              .collection('matches')
              .doc(matchId)
              .get(),
          builder: (context, matchSnap) {
            if (!matchSnap.hasData || !roomSnap.hasData) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Color(0xFFDC143C)),
                ),
              );
            }
            final room = roomSnap.data!;
            final match = VampirMatch.fromDoc(matchSnap.data!);
            return _buildResult(context, room, match);
          },
        );
      },
    );
  }

  Widget _buildResult(BuildContext context, Room room, VampirMatch match) {
    final seats = room.seats;
    final winner = match.winner ?? 'koylu';
    final iWon = match.winnerIds.contains(seatId);

    final (String title, String subtitle, Color color, String emoji) =
        switch (winner) {
      'vampir' => (
          AppL10n.vampireWin,
          AppL10n.vampireWinSub,
          const Color(0xFFDC143C),
          '🧛',
        ),
      'deli' => (
          AppL10n.madWin,
          AppL10n.madWinSub,
          const Color(0xFFFF8C00),
          '🤪',
        ),
      _ => (
          AppL10n.villagerWin,
          AppL10n.villagerWinSub,
          const Color(0xFF32CD32),
          '👨‍🌾',
        ),
    };

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF1A1A1A), color.withValues(alpha: 0.35)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              Text(emoji, style: const TextStyle(fontSize: 70)),
              const SizedBox(height: 10),
              Text(AppL10n.gameOver,
                  style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: color,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: (iWon ? Colors.amber : Colors.blueGrey)
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: iWon ? Colors.amber : Colors.blueGrey),
                ),
                child: Text(iWon ? AppL10n.youWon : AppL10n.youLost,
                    style: TextStyle(
                        color: iWon ? Colors.amber : Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(AppL10n.winners,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(child: _rolesList(match, seats)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _leave(context, room),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(AppL10n.mainMenu,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rolesList(VampirMatch match, Map<String, Seat> seats) {
    final ids = match.seatIds;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: ids.length,
      itemBuilder: (context, i) {
        final id = ids[i];
        final role = match.finalRoles[id] ?? 'koylu';
        final name = seats[id]?.displayName ?? id;
        final isDead = match.deadSeats.contains(id);
        final isWinner = match.winnerIds.contains(id);
        final color = vampirRoleColor(role);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Text(vampirRoleIcon(role), style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration:
                                isDead ? TextDecoration.lineThrough : null)),
                    Text(AppL10n.roleNames[role] ?? AppL10n.unknown,
                        style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (isWinner)
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Text('🏆', style: TextStyle(fontSize: 20)),
                ),
              Text(isDead ? '💀' : '❤️', style: const TextStyle(fontSize: 18)),
            ],
          ),
        );
      },
    );
  }
}
