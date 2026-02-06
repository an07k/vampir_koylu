import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NightResolutionService {
  // GECE ÇÖZÜMLEMESI
  static Future<void> resolveNight(String roomCode) async {
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
      final nightActions =
          Map<String, dynamic>.from(roomData['nightActions'] ?? {});
      final deadPlayers = List<String>.from(roomData['deadPlayers'] ?? []);
      final nightNumber = roomData['nightNumber'] ?? 1;

      debugPrint('🌙 Gece $nightNumber çözümleniyor...');

      // Canlı oyuncular
      final alivePlayers =
          players.keys.where((id) => !deadPlayers.contains(id)).toList();

      // Rol-hedef mapping
      final roleActions = <String, String>{};
      for (var playerId in nightActions.keys) {
        final playerRole = players[playerId]?['role'];
        if (playerRole != null) {
          roleActions[playerRole] = nightActions[playerId];
        }
      }

      // VAMPİR HEDEF SEÇİMİ (en çok oy alan)
      String? vampirTarget;
      final vampirVotes = <String, int>{};
      for (var playerId in nightActions.keys) {
        if (players[playerId]?['role'] == 'vampir') {
          final target = nightActions[playerId];
          vampirVotes[target] = (vampirVotes[target] ?? 0) + 1;
        }
      }
      if (vampirVotes.isNotEmpty) {
        vampirTarget = vampirVotes.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // MİSAFİR ENGELLEMESİ
      final misafirTarget = roleActions['misafir'];
      final blockedPlayers = <String>{};
      if (misafirTarget != null) {
        blockedPlayers.add(misafirTarget);
        debugPrint('🏠 Misafir $misafirTarget\'i engelledi');
      }

      // DOKTOR KORUMASI
      final doktorTarget = roleActions['doktor'];
      final protectedPlayer =
          (doktorTarget != null && !blockedPlayers.contains(doktorTarget))
              ? doktorTarget
              : null;

      if (protectedPlayer != null) {
        debugPrint('🏥 Doktor $protectedPlayer\'i korudu');
      }

      // VAMPİR ÖLDÜRME
      String? killedPlayer;
      if (vampirTarget != null) {
        // Vampirler engellenmemişse ve hedef korunmamışsa
        final vampirsBlocked = alivePlayers
            .where((id) => players[id]?['role'] == 'vampir')
            .any((id) => blockedPlayers.contains(id));

        if (!vampirsBlocked && vampirTarget != protectedPlayer) {
          killedPlayer = vampirTarget;
          deadPlayers.add(killedPlayer);
          debugPrint('🧛 Vampirler $killedPlayer\'i öldürdü');
        } else if (vampirTarget == protectedPlayer) {
          debugPrint('🏥 Doktor $vampirTarget\'i kurtardı!');
        }
      }

      // DETEKTİF SORUŞTURMA
      String? dedektifResult;
      final dedektifTarget = roleActions['dedektif'];
      if (dedektifTarget != null &&
          !blockedPlayers.contains(
              players.keys.firstWhere((id) => roleActions['dedektif'] != null,
                  orElse: () => ''))) {
        final targetRole = players[dedektifTarget]?['role'];
        dedektifResult = targetRole;
        debugPrint('🔍 Detektif $dedektifTarget\'in rolünü öğrendi: $targetRole');
      }

      // POLİS NÖBET
      List<String>? polisVisitors;
      final polisTarget = roleActions['polis'];
      if (polisTarget != null &&
          !blockedPlayers.contains(
              players.keys.firstWhere((id) => roleActions['polis'] != null,
                  orElse: () => ''))) {
        // Polis'in izlediği eve kim gitti?
        polisVisitors = nightActions.entries
            .where((entry) =>
                entry.value == polisTarget &&
                players[entry.key]?['role'] != 'polis')
            .map((e) => e.key)
            .toList();
        debugPrint('👮 Polis $polisTarget\'i izledi: $polisVisitors');
      }

      // TAKİPÇİ
      String? takipciResult;
      final takipciTarget = roleActions['takipci'];
      if (takipciTarget != null &&
          !blockedPlayers.contains(
              players.keys.firstWhere((id) => roleActions['takipci'] != null,
                  orElse: () => ''))) {
        // Takipçinin izlediği kişi nereye gitti?
        takipciResult = nightActions[takipciTarget];
        debugPrint(
            '👣 Takipçi $takipciTarget\'i takip etti: hedef $takipciResult');
      }

      // SONUÇLARI KAYDET
      await roomRef.update({
        'deadPlayers': deadPlayers,
        'currentPhase': 'day',
        'phaseTime': '09:00',
        'phaseStartTimestamp': FieldValue.serverTimestamp(), // Zaman akışı başlasın
        'nightActions': {}, // Sıfırla
        'nightResults': {
          'nightNumber': nightNumber,
          'killed': killedPlayer,
          'dedektif_target': dedektifTarget,
          'dedektif_result': dedektifResult,
          'polis_target': polisTarget,
          'polis_visitors': polisVisitors,
          'takipci_target': takipciTarget,
          'takipci_result': takipciResult,
        },
      });

      debugPrint('✅ Gece $nightNumber çözümlendi. Gündüz fazına geçildi.');
    } catch (e) {
      debugPrint('❌ Gece çözümleme hatası: $e');
    }
  }

  // TÜM AKSIYONLAR GÖNDERİLDİ Mİ?
  static Future<bool> areAllActionsSubmitted(String roomCode) async {
    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomCode)
          .get();

      if (!roomDoc.exists) return false;

      final roomData = roomDoc.data()!;
      final players = Map<String, dynamic>.from(roomData['players'] ?? {});
      final nightActions =
          Map<String, dynamic>.from(roomData['nightActions'] ?? {});
      final deadPlayers = List<String>.from(roomData['deadPlayers'] ?? []);

      // Canlı oyuncular (BOTLARI ÇIKAR)
      final alivePlayers = players.keys
          .where((id) => !deadPlayers.contains(id) && !id.startsWith('bot_'))
          .toList();

      // Gece aksiyonu olan roller
      final nightRoles = [
        'vampir',
        'doktor',
        'dedektif',
        'misafir',
        'polis',
        'takipci',
        'asik'
      ];

      // Aksiyon göndermesi gereken GERÇEK oyuncular
      final requiredPlayers = alivePlayers.where((id) {
        final role = players[id]?['role'];
        return nightRoles.contains(role);
      }).toList();

      // Eğer gerçek oyuncu yoksa direkt true dön
      if (requiredPlayers.isEmpty) {
        debugPrint('⚠️ Gece aksiyonu gereken gerçek oyuncu yok, geçiliyor');
        return true;
      }

      // Herkes gönderdi mi?
      final allSubmitted =
          requiredPlayers.every((id) => nightActions.containsKey(id));

      debugPrint(
          '📊 ${nightActions.length}/${requiredPlayers.length} gerçek oyuncu aksiyon gönderdi');

      return allSubmitted;
    } catch (e) {
      debugPrint('❌ Aksiyon kontrol hatası: $e');
      return false;
    }
  }
}
