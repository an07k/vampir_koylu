import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/night_resolution_service.dart';
import '../services/day_resolution_service.dart';
import 'widgets/role_info_dialog.dart';
import 'widgets/game_time_display.dart';
import 'game_end_screen.dart';

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
  bool _hasAutoStartedVoting = false;

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

  bool _shouldAutoStartVoting(Timestamp? phaseStartTimestamp) {
    if (phaseStartTimestamp == null) return false;

    final now = DateTime.now();
    final phaseStart = phaseStartTimestamp.toDate();
    final elapsedSeconds = now.difference(phaseStart).inSeconds;
    final elapsedGameMinutes = (elapsedSeconds / 3 * 5).toInt();

    // 09:00 to 22:00 = 13 hours = 780 game minutes
    return elapsedGameMinutes >= 780;
  }

  void _showRoleInfo(String role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => RoleInfoDialog(role: role),
    );
  }

  // GECE AKSİYONU SUBMIT
  Future<void> _submitNightAction(String targetId) async {
    if (_userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .update({
        'nightActions.$_userId': targetId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aksiyon gönderildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // GÜNDÜZ OYLAMASI SUBMIT
  Future<void> _submitDayVote(String targetId) async {
    if (_userId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .update({
        'dayVotes.$_userId': targetId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oy gönderildi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // HEDEF SEÇİM DİYALOGU
  void _showTargetSelection(
    List<String> availableTargets,
    Map<String, dynamic> players,
    List<String> deadPlayers,
    Color roleColor,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'HEDEF SEÇ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: roleColor,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: availableTargets.length,
                itemBuilder: (context, index) {
                  final targetId = availableTargets[index];
                  final targetData = players[targetId];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _submitNightAction(targetId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
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
                          const SizedBox(width: 15),
                          Text(
                            targetData['username'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AKSİYON BUTONU OLUŞTUR
  Widget _buildActionButton(
    String currentPhase,
    String myRole,
    List<String> deadPlayers,
    Map<String, dynamic> nightActions,
    int nightNumber,
    Map<String, dynamic> players,
    Color roleColor,
    Map<String, dynamic> dayVotes,
    bool votingStarted,
  ) {
    if (_userId == null) {
      return const SizedBox.shrink();
    }

    final isAlive = !deadPlayers.contains(_userId);
    final hasSubmitted = nightActions.containsKey(_userId);

    // Ölü oyuncular aksiyon yapamaz
    if (!isAlive) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.red),
          ),
          child: const Text(
            'Öldün - Oyunu izleyebilirsin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // GECE FAZI
    if (currentPhase == 'night') {
      // Gece aksiyonu olmayan roller
      if (myRole == 'koylu' || myRole == 'deli' || myRole == 'manipulator') {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue),
            ),
            child: const Text(
              '🌙 Gece fazında bir aksiyonun yok. Sabahı bekle...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      // Aksiyon gönderilmiş
      if (hasSubmitted) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green),
            ),
            child: const Text(
              '✓ Aksiyonun gönderildi. Diğer oyuncular bekleniyor...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.green,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      // Aksiyon gönderilmemiş - hedef seçim butonu
      return Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              // Hedef seçilebilecek oyuncular (canlı, kendisi değil)
              final availableTargets = players.keys
                  .where((id) => id != _userId && !deadPlayers.contains(id))
                  .toList();

              if (availableTargets.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Seçilebilecek hedef yok!'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              _showTargetSelection(
                availableTargets,
                players,
                deadPlayers,
                roleColor,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: roleColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'HEDEF SEÇ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }

    // GÜNDÜZ FAZI - OYLAMA
    // Oylama başlamadıysa bekle
    if (!votingStarted) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.blue),
          ),
          child: const Text(
            '💬 Tartışma devam ediyor...\nOylama henüz başlamadı.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.blue,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final hasVoted = dayVotes.containsKey(_userId);

    if (hasVoted) {
      final myVoteTarget = dayVotes[_userId];
      final targetName = players[myVoteTarget]?['username'] ?? 'Bilinmeyen';

      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.orange),
          ),
          child: Column(
            children: [
              const Text(
                '✓ Oyunu verdin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hedef: $targetName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton(
          onPressed: () {
            _showDayVoteDialog(players, deadPlayers);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            '☀️ OYLAMA YAP',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // GÜNDÜZ OYLAMA DİYALOGU
  void _showDayVoteDialog(
    Map<String, dynamic> players,
    List<String> deadPlayers,
  ) {
    final alivePlayers = players.keys
        .where((id) => !deadPlayers.contains(id) && id != _userId)
        .toList();

    if (alivePlayers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Oylanabilecek kimse yok!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2A2A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '☀️ KİME OY VERİYORSUN?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Oylar herkese açık görünecek!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: alivePlayers.length,
                itemBuilder: (context, index) {
                  final targetId = alivePlayers[index];
                  final targetData = players[targetId];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _submitDayVote(targetId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.1),
                        padding: const EdgeInsets.all(15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
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
                          const SizedBox(width: 15),
                          Text(
                            targetData['username'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
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
          final gameState = roomData['gameState'] ?? 'waiting';

          // OYUN BİTTİ Mİ? - GameEndScreen'e yönlendir
          if (gameState == 'finished') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => GameEndScreen(roomCode: widget.roomCode),
                ),
              );
            });
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC143C)),
            );
          }

          final players = roomData['players'] as Map<String, dynamic>;
          final currentPhase = roomData['currentPhase'] ?? 'night';
          final phaseTime = roomData['phaseTime'] ?? '21:00';
          final phaseStartTimestamp = roomData['phaseStartTimestamp'] as Timestamp?;
          final myRole = players[_userId]?['role'] ?? 'unknown';
          final deadPlayers = List<String>.from(roomData['deadPlayers'] ?? []);
          final nightActions =
              Map<String, dynamic>.from(roomData['nightActions'] ?? {});
          final nightNumber = roomData['nightNumber'] ?? 1;
          final hostId = roomData['hostId'];
          final dayVotes = Map<String, dynamic>.from(roomData['dayVotes'] ?? {});
          final votingStarted = roomData['votingStarted'] ?? false;

          // Auto-start voting at 22:00 (only once)
          if (currentPhase == 'day' && phaseStartTimestamp != null) {
            if (_shouldAutoStartVoting(phaseStartTimestamp) && !_hasAutoStartedVoting) {
              _hasAutoStartedVoting = true;
              // Start voting and then resolve after a short delay
              Future.delayed(const Duration(milliseconds: 500), () async {
                // First, start voting if not started
                if (!votingStarted) {
                  await FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(widget.roomCode)
                      .update({'votingStarted': true});

                  // Wait a bit for players to vote
                  await Future.delayed(const Duration(seconds: 2));
                }

                // Then resolve
                await DayResolutionService.resolveVoting(widget.roomCode);
              });
            }
          } else {
            // Reset flag when not in day phase
            _hasAutoStartedVoting = false;
          }

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
            'manipulator': '🎭',
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
            'manipulator': 'MANİPÜLATÖR',
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
            'manipulator': const Color(0xFF8A2BE2),
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
                                GameTimeDisplay(
                                  phaseStartTimestamp: currentPhase == 'day'
                                      ? phaseStartTimestamp
                                      : null,
                                  staticTime: phaseTime,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white24),

                  // HOST KONTROL PANELİ (Gece fazında)
                  if (currentPhase == 'night' && hostId == _userId)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.purple),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield, color: Colors.purple),
                              SizedBox(width: 10),
                              Text(
                                'HOST KONTROL PANELİ',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              final allSubmitted = await NightResolutionService
                                  .areAllActionsSubmitted(widget.roomCode);

                              if (!allSubmitted && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Henüz tüm oyuncular aksiyonlarını göndermedi!'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                                return;
                              }

                              // Geceyi çözümle
                              await NightResolutionService.resolveNight(
                                  widget.roomCode);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gece çözümlendi! Gündüz başladı.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'GECEYİ BİTİR',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // HOST KONTROL PANELİ (Gündüz fazında - Oy durumu)
                  if (currentPhase == 'day' && hostId == _userId)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.shield, color: Colors.orange),
                              SizedBox(width: 10),
                              Text(
                                'HOST KONTROL PANELİ',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (votingStarted)
                            Text(
                              '${dayVotes.length} / ${players.keys.where((id) => !deadPlayers.contains(id) && !id.startsWith('bot_')).length} oyuncu oy verdi',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            )
                          else
                            const Text(
                              'Oylama henüz başlamadı',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          const SizedBox(height: 5),
                          Text(
                            votingStarted
                                ? 'Oylamayı sonlandırabilirsin.'
                                : 'Oylamayı başlat veya 22:00\'ı bekle.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              if (!votingStarted) {
                                // Oylamayı başlat
                                await FirebaseFirestore.instance
                                    .collection('rooms')
                                    .doc(widget.roomCode)
                                    .update({'votingStarted': true});

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Oylama başladı! Oyuncular oy verebilir.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } else {
                                // Oylamayı sonuçlandır
                                await DayResolutionService.resolveVoting(
                                    widget.roomCode);

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Oylama sonuçlandırıldı!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: votingStarted
                                  ? Colors.red
                                  : Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              votingStarted ? 'OYLAMAYI BİTİR' : 'OYLAMAYA BAŞLA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

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
                                final isDead = deadPlayers.contains(playerId);

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
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              decoration: isDead
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      // Username
                                      Expanded(
                                        child: Text(
                                          playerData['username'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDead
                                                ? Colors.white38
                                                : Colors.white,
                                            decoration: isDead
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                      // Alive/Dead indicator
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDead
                                              ? Colors.red.withOpacity(0.2)
                                              : Colors.green.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color:
                                                isDead ? Colors.red : Colors.green,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          isDead ? 'Ölü' : 'Canlı',
                                          style: TextStyle(
                                            color:
                                                isDead ? Colors.red : Colors.green,
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

                  // AKSİYON BUTONU
                  _buildActionButton(
                    currentPhase,
                    myRole,
                    deadPlayers,
                    nightActions,
                    nightNumber,
                    players,
                    myRoleColor,
                    dayVotes,
                    votingStarted,
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
