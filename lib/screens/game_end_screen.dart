import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class GameEndScreen extends StatefulWidget {
  final String roomCode;

  const GameEndScreen({
    super.key,
    required this.roomCode,
  });

  @override
  State<GameEndScreen> createState() => _GameEndScreenState();
}

class _GameEndScreenState extends State<GameEndScreen> {
  String? _userId;
  bool _isClosingRoom = false;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final user = await AuthService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _userId = user['userId'];
      });
    }
  }

  Future<void> _closeRoomAndSaveHistory(Map<String, dynamic> roomData) async {
    if (_isClosingRoom) return;
    setState(() => _isClosingRoom = true);

    try {
      final players = Map<String, dynamic>.from(roomData['players'] ?? {});
      final deadPlayers = List<String>.from(roomData['deadPlayers'] ?? []);

      // Oyuncuların özet bilgisini hazırla
      final playerSummary = <String, dynamic>{};
      players.forEach((id, data) {
        playerSummary[id] = {
          'username': data['username'],
          'role': data['role'],
          'survived': !deadPlayers.contains(id),
        };
      });

      // game_history koleksiyonuna kaydet
      await FirebaseFirestore.instance.collection('game_history').add({
        'roomCode': widget.roomCode,
        'gameMode': roomData['gameMode'] ?? 'classic',
        'hostId': roomData['hostId'],
        'playerCount': players.length,
        'nightCount': (roomData['nightNumber'] ?? 1) - 1,
        'winner': roomData['winner'] ?? 'unknown',
        'winnerIds': roomData['winnerIds'] ?? [],
        'players': playerSummary,
        'endedAt': FieldValue.serverTimestamp(),
      });

      // rooms koleksiyonundan sil
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .delete();

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClosingRoom = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomCode)
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
          final hostId = roomData['hostId'];
          final isHost = _userId == hostId;

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
                  Text(
                    winnerInfo['icon'],
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 20),

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
                                  child: const Text(
                                    '💰 +10',
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Butonlar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        // HOST: Odayı Kapat butonu
                        if (isHost)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isClosingRoom
                                  ? null
                                  : () => _closeRoomAndSaveHistory(roomData),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade800,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              icon: _isClosingRoom
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.close, color: Colors.white),
                              label: Text(
                                _isClosingRoom ? 'Kapatılıyor...' : 'ODAYI KAPAT',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                        if (isHost) const SizedBox(height: 12),

                        // Herkes: Ana Menü butonu
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: winnerInfo['color'],
                              padding: const EdgeInsets.symmetric(vertical: 15),
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
                        ),
                      ],
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
}
