import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'widgets/role_info_dialog.dart';

class GameScreen extends StatefulWidget {
  final String roomCode;

  const GameScreen({
    super.key,
    required this.roomCode,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  String? _userId;

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

  void _showRoleInfo(String role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoleInfoDialog(role: role),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Oda: ${widget.roomCode}'),
        backgroundColor: const Color(0xFF8B0000),
        automaticallyImplyLeading: false,
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

          if (_userId == null) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC143C)),
            );
          }

          final roomData = snapshot.data!.data() as Map<String, dynamic>;
          final players = roomData['players'] as Map<String, dynamic>;
          final currentPhase = roomData['currentPhase'] ?? 'night';
          final phaseTime = roomData['phaseTime'] ?? '21:00';
          final myRole = players[_userId]?['role'] ?? 'unknown';

          // Rol bilgileri
          final roleIcons = {
            'vampir': '🧛',
            'koylu': '👨‍🌾',
            'doktor': '🏥',
            'asik': '💘',
            'deli': '🤪',
            'dedektif': '🔍',
            'misafir': '🏠',
            'polis': '👮',
            'takipci': '👣',
          };

          final roleNames = {
            'vampir': 'VAMPİR',
            'koylu': 'KÖYLÜ',
            'doktor': 'DOKTOR',
            'asik': 'ÂŞIK',
            'deli': 'DELİ',
            'dedektif': 'DETEKTİF',
            'misafir': 'MİSAFİR',
            'polis': 'POLİS',
            'takipci': 'TAKİPÇİ',
          };

          final roleColors = {
            'vampir': const Color(0xFFDC143C),
            'koylu': const Color(0xFF32CD32),
            'doktor': const Color(0xFF1E90FF),
            'asik': const Color(0xFFFF69B4),
            'deli': const Color(0xFFFF8C00),
            'dedektif': const Color(0xFFFFD700),
            'misafir': const Color(0xFF9370DB),
            'polis': const Color(0xFF00CED1),
            'takipci': const Color(0xFFCD853F),
          };

          final myRoleIcon = roleIcons[myRole] ?? '❓';
          final myRoleName = roleNames[myRole] ?? 'BILINMIYOR';
          final myRoleColor = roleColors[myRole] ?? Colors.white;

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
            child: SafeArea(
              child: Column(
                children: [
                  // FAZ BİLGİSİ
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Faz İkonu ve Saati
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentPhase == 'night' ? '🌙' : '☀️',
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentPhase == 'night' ? 'GECE' : 'GÜNDÜZ',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Saat: $phaseTime',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white24),

                  // ROL BİLGİSİ
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: myRoleColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: myRoleColor.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          myRoleIcon,
                          style: const TextStyle(fontSize: 50),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rolün',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                              Text(
                                myRoleName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: myRoleColor,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Rol Bilgisi Butonu
                        IconButton(
                          onPressed: () => _showRoleInfo(myRole),
                          icon: const Icon(
                            Icons.info_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Rol Bilgisi',
                        ),
                      ],
                    ),
                  ),

                  // OYUNCU LİSTESİ
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OYUNCULAR',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
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
                                            playerData['username'][0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 18,
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
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      // Alive/Dead indicator (placeholder)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        child: const Text(
                                          'Canlı',
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // AKSİYON BUTONU (Placeholder)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Rol aksiyonu
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Rol aksiyonları yakında!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: myRoleColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'AKSİYON',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
}
