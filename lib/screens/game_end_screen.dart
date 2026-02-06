import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameEndScreen extends StatelessWidget {
  final String roomCode;

  const GameEndScreen({
    super.key,
    required this.roomCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Oda bulunamadı',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final winner = roomData['winner'] ?? 'unknown';
          final winnerIds = List<String>.from(roomData['winnerIds'] ?? []);
          final players = Map<String, dynamic>.from(roomData['players'] ?? {});

          // Kazanan ekip bilgisi
          final winnerInfo = _getWinnerInfo(winner);

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1A1A),
                  winnerInfo['color'].withOpacity(0.3),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Konfeti veya kazanma ikonu
                  Text(
                    winnerInfo['icon'],
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 20),

                  // Kazanan başlık
                  Text(
                    winnerInfo['title'],
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: winnerInfo['color'],
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    winnerInfo['subtitle'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Kazanan oyuncular
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: winnerInfo['color'].withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '🏆 KAZANANLAR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: winnerInfo['color'],
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...winnerIds.map((playerId) {
                          final playerData = players[playerId];
                          if (playerData == null) return const SizedBox.shrink();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(
                                      playerData['avatarColor']
                                          .replaceFirst('#', '0xFF'),
                                    )),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      playerData['username'][0].toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    playerData['username'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.amber,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text(
                                        '💰 +10',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Ana menüye dön
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: winnerInfo['color'],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'ANA MENÜ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getWinnerInfo(String winner) {
    switch (winner) {
      case 'vampir':
        return {
          'icon': '🧛',
          'title': 'VAMPİRLER KAZANDI!',
          'subtitle': 'Karanlık galip geldi...',
          'color': const Color(0xFFDC143C),
        };
      case 'koylu':
        return {
          'icon': '👨‍🌾',
          'title': 'KÖYLÜLER KAZANDI!',
          'subtitle': 'Köy kurtarıldı!',
          'color': const Color(0xFF32CD32),
        };
      case 'deli':
        return {
          'icon': '🤪',
          'title': 'DELİ KAZANDI!',
          'subtitle': 'Kaos her şeyi ele geçirdi!',
          'color': const Color(0xFFFF8C00),
        };
      default:
        return {
          'icon': '❓',
          'title': 'OYUN BİTTİ',
          'subtitle': 'Bilinmeyen sonuç',
          'color': Colors.grey,
        };
    }
  }
}
