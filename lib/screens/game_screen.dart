import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/night_resolution_service.dart';
import '../services/day_resolution_service.dart';
import 'widgets/role_info_dialog.dart';
import 'widgets/game_time_display.dart';
import 'widgets/dead_chat_sheet.dart';
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
  bool _hasAutoVotedBots = false;
  String? _lastShownEliminatedId; // Popup için: hangi elimeyi zaten gösterdik
  int? _lastShownNightResultsNumber; // Gece sonucu popup'ı için
  bool _hasAutoActedBotsNight = false;
  int? _lastShownTieTimestamp; // Beraberlik popup'ı için

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

  void _showEliminatedPopup(String name) {
    final messages = [
      '$name köyden kovuldu!',
      '$name infaz edildi!',
      '$name karşı köye gönderildi!',
      '$name halk mahkemesinde yargılandı!',
      '$name köyün adaletine kurban gitti!',
      '$name ipini çekti!',
      '$name köy meydanında hesap verdi!',
    ];
    final message = messages[Random().nextInt(messages.length)];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚖️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'OYLAMA SONUCU',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('TAMAM',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNightResultPopup(String? killedName, {Map<String, dynamic>? nightResults}) {
    final String emoji;
    final String title;
    final List<String> messages = [];

    if (killedName != null) {
      emoji = '🩸';
      title = 'SABAH HABERLERİ';
      final deathMessages = [
        '$killedName evinde ölü bulundu.',
        '$killedName tahtalı köye gitti.',
        '$killedName sabah ezanını duymadı.',
        'Sabah $killedName\'den ses çıkmadı.',
        '$killedName geceyi atlatamadı.',
        '$killedName köy meydanında ölü bulundu.',
        '$killedName\'in şansı bu gece tükendi.',
      ];
      messages.add(deathMessages[Random().nextInt(deathMessages.length)]);
    } else {
      emoji = '🌙';
      title = 'SABAH HABERLERİ';
      final peaceMessages = [
        'Bu gece kimse ölmedi.',
        'Köy huzurla uyudu.',
        'Vampirler bu gece boş döndü.',
        'Köy bir gece daha ayakta.',
        'Bu sabah herkes gözlerini açtı.',
      ];
      messages.add(peaceMessages[Random().nextInt(peaceMessages.length)]);
    }

    // ÂŞIK EFEKTLERİ
    if (nightResults != null) {
      final asikEffect = nightResults['asik_effect'] as String?;
      final kinlendiKill = nightResults['kinlendi_kill'] as String?;

      if (asikEffect == 'intihar') {
        messages.add('💔 Âşık aşkının ölümüne dayanamayıp intihar etti!');
      } else if (asikEffect == 'kinlendi') {
        messages.add('💔 Âşık sevgilisini yitirdi ve kinlendi...');
      } else if (asikEffect == 'deli_devir') {
        messages.add('💔 Âşık sevgilisini yitirdi ve deli oldu!');
      }

      if (kinlendiKill != null) {
        final kinlendiName = (nightResults['kinlendi_name'] as String?) ?? 'bilinmeyen';
        messages.add('🔥 Kinlendi âşık $kinlendiName\'i intikam için öldürdü!');
      }
    }

    final message = messages.join('\n');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: killedName != null ? Colors.red.shade300 : Colors.green.shade300,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: killedName != null
                    ? Colors.red.shade900
                    : Colors.green.shade900,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('TAMAM',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTiePopup(List<String> tiedPlayers) {
    final tieMessages = [
      'Oylar ayrılı, kimse öldürülemedi!',
      'Berabere kalmış oylar!',
      'Köy ikiye bölündü!',
      'Oy sayımında çetin bir beraberlik!',
      'Halk karar veremiyor!',
    ];
    final message = tieMessages[Random().nextInt(tieMessages.length)];
    final playerList = tiedPlayers.join(' ve ');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚖️', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'OYLAMA SONUCU',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playerList,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade900,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('TAMAM',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeadChat(String roomCode, Map<String, dynamic> players) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DeadChatSheet(
        roomCode: roomCode,
        userId: _userId!,
        players: players,
      ),
    );
  }

  // ODAYI KAPAT (Sadece host)
  void _showCloseRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Odayı Kapat',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Odayı kapatmak istediğinize emin misiniz? Tüm oyuncular odadan çıkacak.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL',
                style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final navigator = Navigator.of(context);
              await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomCode)
                  .delete();
              if (mounted) {
                navigator.pushNamedAndRemoveUntil(
                    '/main-menu', (route) => false);
              }
            },
            child: const Text('KAPAT',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // BOT OY ATIŞ (Sadece host tetikler)
  Future<void> _submitBotVotes(
    Map<String, dynamic> players,
    List<String> deadPlayers,
  ) async {
    final aliveBots = players.keys
        .where((id) => id.startsWith('bot_') && !deadPlayers.contains(id))
        .toList();

    if (aliveBots.isEmpty) return;

    final random = Random();
    for (final botId in aliveBots) {
      final possibleTargets = players.keys
          .where((id) => id != botId && !deadPlayers.contains(id))
          .toList();
      if (possibleTargets.isEmpty) continue;

      final targetId = possibleTargets[random.nextInt(possibleTargets.length)];
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .update({'dayVotes.$botId': targetId});
    }
  }

  // BOT GECE AKSİYONU (Sadece host tetikler)
  Future<void> _submitBotNightActions(
    Map<String, dynamic> players,
    List<String> deadPlayers,
  ) async {
    const nightRoles = ['vampir', 'doktor', 'dedektif', 'misafir', 'polis', 'takipci', 'asik'];
    final nightRoleBots = players.keys.where((id) {
      if (!id.startsWith('bot_')) return false;
      if (deadPlayers.contains(id)) return false;
      return nightRoles.contains(players[id]?['role']);
    }).toList();

    if (nightRoleBots.isEmpty) return;

    final random = Random();
    for (final botId in nightRoleBots) {
      final possibleTargets = players.keys
          .where((id) => id != botId && !deadPlayers.contains(id))
          .toList();
      if (possibleTargets.isEmpty) continue;

      final targetId = possibleTargets[random.nextInt(possibleTargets.length)];
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .update({'nightActions.$botId': targetId});
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
  Future<void> _submitNightAction(String targetId, {Map<String, dynamic>? extraUpdates}) async {
    if (_userId == null) return;

    try {
      final updates = <String, dynamic>{'nightActions.$_userId': targetId};
      if (extraUpdates != null) updates.addAll(extraUpdates);
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomCode)
          .update(updates);

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
    Color roleColor, {
    Map<String, dynamic> Function(String targetId)? extraUpdates,
  }) {
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
                        _submitNightAction(targetId, extraUpdates: extraUpdates?.call(targetId));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha:0.1),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.red),
              ),
              child: const Text(
                '💀 Öldün — Oyunu izleyebilirsin',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showDeadChat(
                  widget.roomCode,
                  players,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A1A1A),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
                icon: const Text('💀', style: TextStyle(fontSize: 16)),
                label: const Text(
                  'ÖLÜLER SOHBETİ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // GECE FAZI
    if (currentPhase == 'night') {
      // ÂŞIK ÖZEL KONTROL
      if (myRole == 'asik') {
        final asikTarget = players[_userId]?['asikTarget'];
        final isKinlendi = players[_userId]?['asikKinlendi'] == true;

        if (asikTarget != null && !isKinlendi) {
          // Hedef seçildi, bekliyoruz
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.pink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.pink),
              ),
              child: const Text(
                '💘 Aşığını seçtiniz. Kaderinizi bekliyorsunuz...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.pink,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else if (isKinlendi) {
          // Kinlendi kill UI
          if (hasSubmitted) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  '✓ Kurbanını seçtin. Intikamın alınacak...',
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

          final availableTargets = players.keys
              .where((id) => id != _userId && !deadPlayers.contains(id))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  _showTargetSelection(
                    availableTargets,
                    players,
                    deadPlayers,
                    roleColor,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  '💔 KİNLENDİ — Kurbanını Seç',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          );
        } else {
          // Henüz seçmemiş: aşık seçim UI
          if (hasSubmitted) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
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

          final availableTargets = players.keys
              .where((id) => id != _userId && !deadPlayers.contains(id))
              .toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
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
                  'Aşığını Seç 💘',
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
      }

      // Gece aksiyonu olmayan roller
      if (myRole == 'koylu' || myRole == 'deli' || myRole == 'manipulator') {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha:0.2),
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
              color: Colors.green.withValues(alpha:0.2),
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
              final selfProtectUsed = players[_userId]?['selfProtectUsed'] == true;
              // Doktor kendini bir kez koruyabilir, diğer roller kendini seçemez
              final availableTargets = players.keys.where((id) {
                if (id == _userId) return myRole == 'doktor' && !selfProtectUsed;
                return !deadPlayers.contains(id);
              }).toList();

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
                extraUpdates: myRole == 'doktor'
                    ? (targetId) => targetId == _userId
                        ? {'players.$_userId.selfProtectUsed': true}
                        : {}
                    : null,
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
    // Oylama bitti, serbest zaman
    if (!votingStarted) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha:0.2),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.indigo),
          ),
          child: const Text(
            '💬 Serbest zaman\nKonuşabilir, tartışabilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.indigo,
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
            color: Colors.orange.withValues(alpha:0.2),
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
                        backgroundColor: Colors.white.withValues(alpha:0.1),
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
          final lastEliminated = roomData['lastEliminated'] as Map<String, dynamic>?;
          final nightResults = roomData['nightResults'] as Map<String, dynamic>?;

          // Gece sonucu popup'ı - yeni bir gece çözümü varsa göster
          if (nightResults != null) {
            final nightResultNumber = nightResults['nightNumber'] as int?;
            if (nightResultNumber != null && nightResultNumber != _lastShownNightResultsNumber) {
              _lastShownNightResultsNumber = nightResultNumber;
              final killedId = nightResults['killed'] as String?;
              String? killedName;
              if (killedId != null) {
                killedName = players[killedId]?['username'] as String?;
              }
              // Kinlendi kill için oyuncu adı ekle
              final kinlendiKill = nightResults['kinlendi_kill'] as String?;
              if (kinlendiKill != null && nightResults['kinlendi_name'] == null) {
                nightResults['kinlendi_name'] = players[kinlendiKill]?['username'] as String?;
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showNightResultPopup(killedName, nightResults: nightResults);
              });
            }
          }

          // Kim öldü popup'ı - yeni bir eliminasyon varsa göster
          if (lastEliminated != null) {
            final eliminatedId = lastEliminated['id'] as String?;
            if (eliminatedId != null && eliminatedId != _lastShownEliminatedId) {
              _lastShownEliminatedId = eliminatedId;
              final eliminatedName = lastEliminated['name'] as String? ?? '?';
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _showEliminatedPopup(eliminatedName);
              });
            }
          }

          // Beraberlik popup'ı - yeni bir beraberlik varsa göster
          final lastTie = roomData['lastTie'] as Map<String, dynamic>?;
          if (lastTie != null) {
            final tieTimestamp = (lastTie['timestamp'] as Timestamp?)?.millisecondsSinceEpoch;
            if (tieTimestamp != null && tieTimestamp != _lastShownTieTimestamp) {
              _lastShownTieTimestamp = tieTimestamp;
              final tiedPlayers = List<String>.from(lastTie['tiedPlayers'] ?? []);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && tiedPlayers.isNotEmpty) _showTiePopup(tiedPlayers);
              });
            }
          }

          // Serbest zaman 22:00'da otomatik geceye geç
          if (currentPhase == 'day' && !votingStarted && phaseStartTimestamp != null) {
            if (_shouldAutoStartVoting(phaseStartTimestamp) && !_hasAutoStartedVoting) {
              _hasAutoStartedVoting = true;
              Future.delayed(const Duration(milliseconds: 500), () async {
                await DayResolutionService.advanceToNight(widget.roomCode);
              });
            }
          } else if (currentPhase != 'day') {
            _hasAutoStartedVoting = false;
          }

          // Bot gece aksiyonları - gece başladığında host otomatik gönderir
          if (currentPhase == 'night' && hostId == _userId && !_hasAutoActedBotsNight) {
            _hasAutoActedBotsNight = true;
            Future.delayed(const Duration(milliseconds: 500), () async {
              await _submitBotNightActions(players, deadPlayers);
            });
          } else if (currentPhase == 'day') {
            _hasAutoActedBotsNight = false;
          }

          // Bot oylaması - oylama başladığında host otomatik bot oylarını gönderir
          if (currentPhase == 'day' && votingStarted && hostId == _userId && !_hasAutoVotedBots) {
            _hasAutoVotedBots = true;
            Future.delayed(const Duration(milliseconds: 300), () async {
              await _submitBotVotes(players, deadPlayers);
            });
          } else if (!votingStarted) {
            _hasAutoVotedBots = false;
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
                  const Color(0xFF8B0000).withValues(alpha:0.3),
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
                                  phaseStartTimestamp: currentPhase == 'day' && !votingStarted
                                      ? phaseStartTimestamp
                                      : null,
                                  staticTime: currentPhase == 'day' && votingStarted
                                      ? '09:00'
                                      : phaseTime,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white24),

                  // HOST: Odayı Kapat seçeneği
                  if (hostId == _userId)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: _showCloseRoomDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade300,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                          ),
                          icon: const Icon(Icons.close, size: 14),
                          label: const Text(
                            'ODAYI KAPAT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // HOST KONTROL PANELİ (Gece fazında)
                  if (currentPhase == 'night' && hostId == _userId)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha:0.2),
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

                              if (!mounted) return;

                              if (!allSubmitted) {
                                // ignore: use_build_context_synchronously
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

                              if (!mounted) return;

                              // ignore: use_build_context_synchronously
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gece çözümlendi! Gündüz başladı.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
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

                  // HOST KONTROL PANELİ (Gündüz fazında)
                  if (currentPhase == 'day' && hostId == _userId)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: votingStarted
                            ? Colors.orange.withValues(alpha:0.2)
                            : Colors.indigo.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: votingStarted ? Colors.orange : Colors.indigo,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield,
                                color: votingStarted ? Colors.orange : Colors.indigo,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                votingStarted ? 'OYLAMA AŞAMASI' : 'SERBEST ZAMAN',
                                style: TextStyle(
                                  color: votingStarted ? Colors.orange : Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            votingStarted
                                ? '${dayVotes.length} / ${players.keys.where((id) => !deadPlayers.contains(id)).length} oyuncu oy verdi'
                                : 'Serbest zaman — 22:00\'da gece başlayacak.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () async {
                              if (votingStarted) {
                                // Oylamayı sonuçlandır → serbest zamana geç
                                await DayResolutionService.resolveVoting(widget.roomCode);
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Oylama sonuçlandı! Serbest zaman başladı.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                // Serbest zamanı bitir → geceye geç
                                await DayResolutionService.advanceToNight(widget.roomCode);
                                if (!mounted) return;
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gece başladı!'),
                                    backgroundColor: Colors.purple,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: votingStarted ? Colors.red : Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              votingStarted ? 'OYLAMAYI BİTİR' : 'GECEYİ BAŞLAT',
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
                      color: myRoleColor.withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: myRoleColor.withValues(alpha:0.5),
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
                          Text(
                            'OYUNCULAR (${players.length - deadPlayers.length}/${players.length} Canlı)',
                            style: const TextStyle(
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
                                // Canlılar önce, ölüler sona
                                final sortedIds = (players.keys.toList()
                                  ..sort((a, b) => (deadPlayers.contains(a) ? 1 : 0)
                                      .compareTo(deadPlayers.contains(b) ? 1 : 0)));
                                final playerId = sortedIds[index];
                                final playerData = players[playerId];
                                final isDead = deadPlayers.contains(playerId);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha:0.05),
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
                                              ? Colors.red.withValues(alpha:0.2)
                                              : Colors.green.withValues(alpha:0.2),
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
