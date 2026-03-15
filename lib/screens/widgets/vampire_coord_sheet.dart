import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VampireCoordSheet extends StatelessWidget {
  final String roomCode;
  final String userId;
  final Map<String, dynamic> players;
  final List<String> deadPlayers;
  final Map<String, dynamic> vampireVotes;

  const VampireCoordSheet({
    super.key,
    required this.roomCode,
    required this.userId,
    required this.players,
    required this.deadPlayers,
    required this.vampireVotes,
  });

  Future<void> _vote(String targetId) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomCode)
        .update({'vampireVotes.$userId': targetId});
  }

  Future<void> _clearVote() async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomCode)
        .update({'vampireVotes.$userId': FieldValue.delete()});
  }

  @override
  Widget build(BuildContext context) {
    final myVote = vampireVotes[userId] as String?;

    // Vampir oyuncuları bul
    final vampireIds = players.keys
        .where((id) => players[id]?['role'] == 'vampir')
        .toList();

    // Hedef olabilecek canlı oyuncular (kendisi hariç)
    final targets = players.keys
        .where((id) => id != userId && !deadPlayers.contains(id))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A0000),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.red.shade900,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('🧛', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'VAMPİR KOORDİNASYONU',
                      style: TextStyle(
                        color: Color(0xFFDC143C),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Kimi yemek istediğini işaretle',
                  style: TextStyle(color: Colors.red, fontSize: 11),
                ),
              ],
            ),
          ),

          // Liste
          Expanded(
            child: Container(
              color: const Color(0xFF0D0000),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: targets.length,
                itemBuilder: (context, index) {
                  final targetId = targets[index];
                  final targetData = players[targetId];
                  final isMyVote = myVote == targetId;

                  // Bu oyuncuya oy veren vampirlerin isimleri
                  final votersNames = vampireIds
                      .where((vId) => vampireVotes[vId] == targetId && vId != userId)
                      .map((vId) => players[vId]?['username'] as String? ?? '?')
                      .toList();

                  return GestureDetector(
                    onTap: () => isMyVote ? _clearVote() : _vote(targetId),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isMyVote
                            ? Colors.red.shade900.withValues(alpha: 0.4)
                            : const Color(0xFF1A0000),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isMyVote
                              ? const Color(0xFFDC143C)
                              : Colors.red.shade900.withValues(alpha: 0.4),
                          width: isMyVote ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Color(int.parse(
                                targetData['avatarColor']
                                    .replaceFirst('#', '0xFF'),
                              )),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                targetData['username'][0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  targetData['username'],
                                  style: TextStyle(
                                    color: isMyVote
                                        ? const Color(0xFFDC143C)
                                        : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (votersNames.isNotEmpty)
                                  Text(
                                    '🧛 ${votersNames.join(', ')}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (isMyVote)
                            const Icon(Icons.check_circle,
                                color: Color(0xFFDC143C), size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
