import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'gold_service.dart';

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

      // Her rol için actor ve hedef bul (doktor çoklu olabilir)
      final roleActors = <String, String>{}; // role → actorId
      final roleTargets = <String, String>{}; // role → target
      final doctorActions = <String, String>{}; // doctorActorId → target

      for (var playerId in nightActions.keys) {
        final playerRole = players[playerId]?['role'];
        if (playerRole == null) continue;

        if (playerRole == 'doktor') {
          doctorActions[playerId] = nightActions[playerId] as String;
        } else {
          roleActors[playerRole] = playerId;
          roleTargets[playerRole] = nightActions[playerId] as String;
        }
      }

      // ÂŞIK HEDEF KALICI KAYDI (ilk seç)
      final asikActorId = roleActors['asik'];
      final asikTarget = roleTargets['asik'];
      String? existingAsikTarget;
      if (asikActorId != null) {
        existingAsikTarget = players[asikActorId]?['asikTarget'] as String?;
      }

      if (asikActorId != null &&
          asikTarget != null &&
          existingAsikTarget == null) {
        // İlk kez seçiyor, players map'ini güncelle
        players[asikActorId] = Map<String, dynamic>.from(players[asikActorId]!);
        (players[asikActorId] as Map)['asikTarget'] = asikTarget;
      }

      // VAMPİR HEDEF SEÇİMİ (en çok oy alan)
      String? vampirTarget;
      final vampirVotes = <String, int>{};
      for (var playerId in nightActions.keys) {
        if (players[playerId]?['role'] == 'vampir') {
          final target = nightActions[playerId] as String;
          vampirVotes[target] = (vampirVotes[target] ?? 0) + 1;
        }
      }
      if (vampirVotes.isNotEmpty) {
        vampirTarget = vampirVotes.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      // MİSAFİR ENGELLEMESİ — misafirin ziyaret ettiği oyuncu aksiyon yapamaz
      final misafirTarget = roleTargets['misafir'];
      final blockedPlayers = <String>{};
      if (misafirTarget != null) {
        blockedPlayers.add(misafirTarget);
        debugPrint('🏠 Misafir $misafirTarget\'i engelledi');
      }

      // DOKTOR KORUMASI — her doktor için kontrol et, doktor kendisi engellenmemişse koruma geçerli
      final protectedPlayers = <String>{};
      for (var doktorActorId in doctorActions.keys) {
        if (!blockedPlayers.contains(doktorActorId)) {
          final target = doctorActions[doktorActorId]!;
          protectedPlayers.add(target);
          debugPrint('🏥 Doktor $doktorActorId, $target\'i korudu');
        }
      }

      // VAMPİR ÖLDÜRME
      String? killedPlayer;
      if (vampirTarget != null) {
        final vampirsBlocked = alivePlayers
            .where((id) => players[id]?['role'] == 'vampir')
            .any((id) => blockedPlayers.contains(id));

        if (!vampirsBlocked && !protectedPlayers.contains(vampirTarget)) {
          killedPlayer = vampirTarget;
          deadPlayers.add(killedPlayer);
          debugPrint('🧛 Vampirler $killedPlayer\'i öldürdü');
        } else if (protectedPlayers.contains(vampirTarget)) {
          debugPrint('🏥 Doktor $vampirTarget\'i kurtardı!');
        }
      }

      // KİNLENDİ ÂŞIK GECE ÖLDÜRMESI (asik önceki geceden kinlendi ise)
      String? kinlendiKill;
      if (asikActorId != null && !deadPlayers.contains(asikActorId)) {
        final isKinlendi = players[asikActorId]?['asikKinlendi'] == true;
        // kinlendi ise bu gece nightActions'tan hedef al (gece aksiyonu)
        final kinlendiTarget =
            isKinlendi ? (roleTargets['asik'] ?? existingAsikTarget) : null;
        if (isKinlendi &&
            kinlendiTarget != null &&
            !deadPlayers.contains(kinlendiTarget)) {
          if (!protectedPlayers.contains(kinlendiTarget)) {
            kinlendiKill = kinlendiTarget;
            deadPlayers.add(kinlendiTarget);
            debugPrint('💔 Kinlendi âşık $kinlendiTarget\'i öldürdü');
          }
          // Asık her şekilde ölür (kinlendi kill sonrası)
          deadPlayers.add(asikActorId);
          debugPrint('💔 Kinlendi âşık $asikActorId ölüyor');
        }
      }

      // ÂŞIK HEDEFİ ÖLDÜ MÜ? (bu gece)
      String? asikEffect; // 'intihar' | 'kinlendi' | 'deli_devir' | null
      final savedTarget = asikActorId != null
          ? (players[asikActorId]?['asikTarget'] as String?)
          : null;
      if (asikActorId != null &&
          savedTarget != null &&
          !deadPlayers.contains(asikActorId) &&
          kinlendiKill != savedTarget) {
        // Hedef bu gece öldü mü?
        if (killedPlayer == savedTarget || kinlendiKill == savedTarget) {
          // Hedef bu gece öldü, etki belirle
          final targetRole = players[savedTarget]?['role'];
          if (targetRole == 'vampir') {
            deadPlayers.add(asikActorId);
            asikEffect = 'intihar';
            debugPrint('💔 Âşık $asikActorId vampir sevgilisini öldürtüp intihar etti');
          } else if (targetRole == 'deli') {
            asikEffect = 'deli_devir';
            debugPrint('💔 Âşık $asikActorId deli sevgilisini yitirdi, deli oldu');
          } else {
            asikEffect = 'kinlendi';
            debugPrint('💔 Âşık $asikActorId masum sevgilisini yitirdi, kinlendi');
          }
        } else if (!List<String>.from(roomData['deadPlayers'] ?? [])
            .contains(savedTarget) &&
            deadPlayers.contains(savedTarget)) {
          // Hedef bu resolüsyonda yeni öldü
          final targetRole = players[savedTarget]?['role'];
          if (targetRole == 'vampir') {
            deadPlayers.add(asikActorId);
            asikEffect = 'intihar';
            debugPrint('💔 Âşık $asikActorId vampir sevgilisini kaybetti (dış sebep)');
          } else if (targetRole == 'deli') {
            asikEffect = 'deli_devir';
            debugPrint('💔 Âşık $asikActorId deli sevgilisini kaybetti');
          } else {
            asikEffect = 'kinlendi';
            debugPrint('💔 Âşık $asikActorId sevgilisini kaybetti');
          }
        }
      }

      // GECE ÖLDÜRMESINDEN SONRA KAZANMA KONTROLÜ
      if (killedPlayer != null) {
        final winner = _checkWinCondition(players, deadPlayers);
        if (winner != null) {
          debugPrint('🏆 Gece öldürmesiyle oyun bitti! Kazanan: $winner');
          await _endGame(roomRef, winner, players, deadPlayers);
          return;
        }
      }

      // DETEKTİF SORUŞTURMA
      String? dedektifResult;
      final dedektifTarget = roleTargets['dedektif'];
      final dedektifActorId = roleActors['dedektif'];
      if (dedektifTarget != null &&
          dedektifActorId != null &&
          !blockedPlayers.contains(dedektifActorId)) {
        dedektifResult = players[dedektifTarget]?['role'];
        debugPrint('🔍 Detektif $dedektifTarget\'in rolünü öğrendi: $dedektifResult');
      }

      // POLİS NÖBET
      List<String>? polisVisitors;
      final polisTarget = roleTargets['polis'];
      final polisActorId = roleActors['polis'];
      if (polisTarget != null &&
          polisActorId != null &&
          !blockedPlayers.contains(polisActorId)) {
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
      final takipciTarget = roleTargets['takipci'];
      final takipciActorId = roleActors['takipci'];
      if (takipciTarget != null &&
          takipciActorId != null &&
          !blockedPlayers.contains(takipciActorId)) {
        takipciResult = nightActions[takipciTarget] as String?;
        debugPrint('👣 Takipçi $takipciTarget\'i takip etti: hedef $takipciResult');
      }

      // ÂŞIK GÜNCELLEMELERİ
      final updates = <String, dynamic>{
        'deadPlayers': deadPlayers,
        'currentPhase': 'day',
        'phaseTime': '09:00',
        'votingStarted': true, // Sabah oylaması direkt başlasın
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
          'asik_effect': asikEffect,
          'kinlendi_kill': kinlendiKill,
        },
      };

      // Asık hedef ilk kez kaydedildiyse updates'e ekle
      if (asikActorId != null &&
          existingAsikTarget == null &&
          asikTarget != null) {
        updates['players.$asikActorId.asikTarget'] = asikTarget;
      }

      // Asık kinlendi efekti
      if (asikEffect == 'kinlendi') {
        updates['players.$asikActorId.asikKinlendi'] = true;
      } else if (asikEffect == 'deli_devir') {
        updates['players.$asikActorId.role'] = 'deli';
      }

      // Kinlendi kullanıldıysa temizle
      if (players[asikActorId]?['asikKinlendi'] == true && kinlendiKill != null) {
        updates['players.$asikActorId.asikKinlendi'] = false;
      }

      // SONUÇLARI KAYDET
      await roomRef.update(updates);

      debugPrint('✅ Gece $nightNumber çözümlendi. Gündüz fazına geçildi.');
    } catch (e) {
      debugPrint('❌ Gece çözümleme hatası: $e');
    }
  }

  // KAZANMA KOŞULU KONTROL
  static String? _checkWinCondition(
    Map<String, dynamic> players,
    List<String> deadPlayers,
  ) {
    final alivePlayers =
        players.keys.where((id) => !deadPlayers.contains(id)).toList();

    int vampirCount = 0;
    int townCount = 0;
    for (var id in alivePlayers) {
      if (players[id]?['role'] == 'vampir') {
        vampirCount++;
      } else {
        townCount++;
      }
    }

    if (vampirCount == 0) return 'koylu';
    if (vampirCount >= townCount) return 'vampir';
    return null;
  }

  // OYUNU BİTİR
  static Future<void> _endGame(
    DocumentReference roomRef,
    String winner,
    Map<String, dynamic> players,
    List<String> deadPlayers,
  ) async {
    final winnerIds = <String>[];
    if (winner == 'vampir') {
      for (var id in players.keys) {
        if (!deadPlayers.contains(id) && players[id]?['role'] == 'vampir') {
          winnerIds.add(id);
        }
      }
    } else if (winner == 'koylu') {
      for (var id in players.keys) {
        if (!deadPlayers.contains(id) && players[id]?['role'] != 'vampir') {
          winnerIds.add(id);
        }
      }
    }

    await GoldService.awardWinGold(winnerIds);

    await roomRef.update({
      'gameState': 'finished',
      'winner': winner,
      'winnerIds': winnerIds,
      'currentPhase': 'finished',
      'deadPlayers': deadPlayers,
    });

    debugPrint('🏆 Oyun bitti (gece). Kazanan: $winner, Kazananlar: $winnerIds');
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
        if (role == 'asik') {
          // Asık: hedef zaten seçmişse veya kinlendi değilse aksiyonsuz geçebilir
          final hasTarget = players[id]?['asikTarget'] != null;
          final isKinlendi = players[id]?['asikKinlendi'] == true;
          return !(hasTarget && !isKinlendi);
        }
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
