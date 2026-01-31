import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/role_distribution.dart';

class RoomLobbyScreen extends StatefulWidget {
  final String roomCode;

  const RoomLobbyScreen({
    super.key,
    required this.roomCode,
  });

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  final TextEditingController _chatController = TextEditingController();

  // ODAYI KAPAT DİALOG (Sadece Host)
  void _showCloseRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Odayı Kapat',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Odayı kapatmak istediğinize emin misiniz? Tüm oyuncular odadan atılacak ve oda silinecek.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İPTAL',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Dialog'u kapat
              await _closeRoom();
            },
            child: const Text(
              'KAPAT',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ODAYI KAPAT (Firestore'dan sil)
  Future<void> _closeRoom() async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .delete();

      debugPrint('✅ Oda kapatıldı: ${widget.roomCode}');

      if (mounted) {
        Navigator.pop(context); // Ana menüye dön
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oda kapatıldı'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Oda kapatma hatası: $e');
    }
  }

  // ODADAN AYRIL (Normal oyuncu)
  Future<void> _leaveRoom() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Oyuncuyu odadan çıkar
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .update({
        'players.$userId': FieldValue.delete(),
        'playerCount': FieldValue.increment(-1),
      });

      debugPrint('✅ Odadan ayrıldı');

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Odadan ayrılma hatası: $e');
    }
  }

  // OYUNU BAŞLAT (Rol dağıt ve oyunu başlat)
  Future<void> _startGame(String gameMode, List<String> playerIds) async {
    try {
      // Rolleri ata
      final assignedRoles = RoleDistribution.assignRoles(playerIds, gameMode);

      // Firestore'a kaydet
      await RoleDistribution.saveRoles(widget.roomCode, assignedRoles);

      debugPrint('✅ Oyun başlatıldı! Roller dağıtıldı.');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oyun başladı! Roller dağıtıldı.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Oyun başlatma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oyun başlatılamadı. Tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Oda: ${widget.roomCode}'),
        backgroundColor: const Color(0xFF8B0000),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomCode)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFDC143C),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text(
                'Oda bulunamadı',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final players = roomData['players'] as Map<String, dynamic>;
          final hostId = roomData['hostId'];
          final currentUserId = FirebaseAuth.instance.currentUser!.uid;
          final isHost = currentUserId == hostId;
          final playerCount = roomData['playerCount'];
          final maxPlayers = roomData['maxPlayers'];
          final gameMode = roomData['gameMode'];

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF8B0000).withOpacity(0.3),
                ],
              ),
            ),
            child: Column(
              children: [
                // ODA BİLGİLERİ
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Oda Kodu
                      Text(
                        widget.roomCode,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC143C),
                          letterSpacing: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Mod ve Oyuncu Sayısı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              gameMode == 'classic' ? 'Klasik' : 'Egzantrik',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '$playerCount/$maxPlayers Oyuncu',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white24),

                // OYUNCU LİSTESİ
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: players.length,
                    itemBuilder: (context, index) {
                      final playerId = players.keys.elementAt(index);
                      final playerData = players[playerId];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
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
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Username
                            Expanded(
                              child: Text(
                                playerData['username'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            // Host Badge
                            if (playerData['isHost'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFD700).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFFD700),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.stars,
                                      color: Color(0xFFFFD700),
                                      size: 16,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Host',
                                      style: TextStyle(
                                        color: Color(0xFFFFD700),
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
                    },
                  ),
                ),

                // BUTONLAR
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Oyunu Başlat (sadece host görür)
                      if (isHost)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: playerCount >= 4
                                ? () {
                                    final playerIds = players.keys.toList();
                                    _startGame(gameMode, playerIds);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF32CD32),
                              disabledBackgroundColor: Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'OYUNU BAŞLAT',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (isHost) const SizedBox(height: 10),

                      // Odadan Ayrıl / Odayı Kapat
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isHost) {
                              _showCloseRoomDialog();
                            } else {
                              _leaveRoom();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            isHost ? 'ODAYI KAPAT' : 'ODADAN AYRIL',
                            style: const TextStyle(
                              fontSize: 18,
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
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }
}