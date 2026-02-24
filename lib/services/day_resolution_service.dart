import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'gold_service.dart';

class DayResolutionService {
  // GÜNDÜZ OYLAMASI SONUÇLANDIR
  static Future<void> resolveVoting(String roomCode) async {
    try {
      final roomRef =
          FirebaseFirestore.instance.collection('rooms').doc(roomCode);
      final roomDoc = await roomRef.get();

      if (!roomDoc.exists) {
        debugPrint('❌ Oda bulunamadı');
        return;
      }

      final roomData = roomDoc.data()!;
      final players = Map<String, dynamic>.from(roomData['players'] ?? {});
      final dayVotes = Map<String, dynamic>.from(roomData['dayVotes'] ?? {});
      final deadPlayers = List<String>.from(roomData['deadPlayers'] ?? []);

      debugPrint('☀️ Gündüz oylaması sonuçlandırılıyor...');

      // OY SAYIMI
      final voteCounts = <String, int>{};
      for (var targetId in dayVotes.values) {
        voteCounts[targetId] = (voteCounts[targetId] ?? 0) + 1;
      }

      if (voteCounts.isEmpty) {
        debugPrint('⚠️ Hiç oy yok, kimse öldürülmedi');
        await roomRef.update({
          'dayVotes': {},
          'votingStarted': false,
          'phaseStartTimestamp': FieldValue.serverTimestamp(),
        });
        return;
      }

      // EN ÇOK OY ALAN
      final maxVotes = voteCounts.values.reduce((a, b) => a > b ? a : b);
      final victims =
          voteCounts.entries.where((e) => e.value == maxVotes).toList();

      if (victims.length > 1) {
        debugPrint('⚠️ Berabere! Kimse öldürülmedi: ${victims.map((e) => e.key).join(', ')}');
        await roomRef.update({
          'dayVotes': {},
          'votingStarted': false,
          'phaseStartTimestamp': FieldValue.serverTimestamp(),
        });
        return;
      }

      // ÖLDÜRÜLEN OYUNCU
      final eliminatedId = victims.first.key;
      final eliminatedRole = players[eliminatedId]?['role'];
      deadPlayers.add(eliminatedId);

      debugPrint('☠️ $eliminatedId ($eliminatedRole) oylama ile öldürüldü');

      // KAZANMA KONTROLÜ
      final winner = _checkWinCondition(players, deadPlayers, eliminatedRole);

      if (winner != null) {
        debugPrint('🏆 Oyun bitti! Kazanan: $winner');
        await _endGame(roomRef, winner, players, deadPlayers);
        return;
      }

      // OYUN DEVAM EDİYOR - SERBEST ZAMANA GEÇ
      await roomRef.update({
        'deadPlayers': deadPlayers,
        'dayVotes': {},
        'votingStarted': false,
        'phaseStartTimestamp': FieldValue.serverTimestamp(),
        'lastEliminated': {
          'id': eliminatedId,
          'name': players[eliminatedId]?['username'] ?? '?',
          'timestamp': FieldValue.serverTimestamp(),
        },
      });
    } catch (e) {
      debugPrint('❌ Oylama çözümleme hatası: $e');
    }
  }

  // KAZANMA KOŞULU KONTROL
  static String? _checkWinCondition(
    Map<String, dynamic> players,
    List<String> deadPlayers,
    String? eliminatedRole,
  ) {
    // DELİ KAZANDI MI?
    if (eliminatedRole == 'deli') {
      return 'deli';
    }

    // CANLI OYUNCULAR
    final alivePlayers =
        players.keys.where((id) => !deadPlayers.contains(id)).toList();

    // VAMPİR VE KÖYLÜ SAYISI
    int vampirCount = 0;
    int townCount = 0;

    for (var playerId in alivePlayers) {
      final role = players[playerId]?['role'];
      if (role == 'vampir') {
        vampirCount++;
      } else {
        townCount++;
      }
    }

    debugPrint('📊 Canlı: $vampirCount vampir, $townCount köylü/diğer');

    // KÖYLÜ KAZANDI MI? (Tüm vampirler öldü)
    if (vampirCount == 0) {
      return 'koylu';
    }

    // VAMPİR KAZANDI MI? (Vampir sayısı >= köylü sayısı)
    if (vampirCount >= townCount) {
      return 'vampir';
    }

    // OYUN DEVAM
    return null;
  }

  // OYUNU BİTİR
  static Future<void> _endGame(
    DocumentReference roomRef,
    String winner,
    Map<String, dynamic> players,
    List<String> deadPlayers,
  ) async {
    // KAZANAN OYUNCULARI BUL
    final winnerIds = <String>[];

    if (winner == 'deli') {
      // Deli tek başına kazandı
      for (var playerId in players.keys) {
        if (players[playerId]?['role'] == 'deli') {
          winnerIds.add(playerId);
          break;
        }
      }
    } else if (winner == 'vampir') {
      // Tüm canlı vampirler kazandı
      for (var playerId in players.keys) {
        if (!deadPlayers.contains(playerId) &&
            players[playerId]?['role'] == 'vampir') {
          winnerIds.add(playerId);
        }
      }
    } else if (winner == 'koylu') {
      // Tüm canlı köylüler ve diğer roller kazandı
      for (var playerId in players.keys) {
        if (!deadPlayers.contains(playerId) &&
            players[playerId]?['role'] != 'vampir') {
          winnerIds.add(playerId);
        }
      }
    }

    debugPrint('🎉 Kazananlar: $winnerIds');

    // GOLD ÖDÜLÜ VER
    await GoldService.awardWinGold(winnerIds);

    // OYUN DURUMUNU GÜNCELLE
    await roomRef.update({
      'gameState': 'finished',
      'winner': winner,
      'winnerIds': winnerIds,
      'currentPhase': 'finished',
    });
  }

  // YENİ GECEYE GEÇ (host butonu veya 22:00 auto-start)
  static Future<void> advanceToNight(String roomCode) async {
    final roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(roomCode);
    final roomDoc = await roomRef.get();
    if (!roomDoc.exists) return;

    final nightNumber = roomDoc.data()?['nightNumber'] ?? 1;

    await roomRef.update({
      'currentPhase': 'night',
      'phaseTime': '21:00',
      'nightNumber': nightNumber + 1,
      'dayVotes': {},
      'nightActions': {},
      'votingStarted': false,
    });

    debugPrint('🌙 Gece ${nightNumber + 1} başladı');
  }
}
