import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class RoleDistribution {
  // EGZANTRİK ROL HAVUZU
  static final List<String> eccentricRoles = [
    'asik',        // Âşık
    'deli',        // Deli
    'dedektif',    // Dedektif
    'misafir',     // Misafir
    'polis',       // Polis
    'takipci',     // Takipçi
    'manipulator', // Manipülatör
  ];

  // Normal mod vampir tablosu
  static const _normalVampirs = {
    4: 1, 5: 1, 6: 2, 7: 2, 8: 2, 9: 2,
    10: 3, 11: 3, 12: 3, 13: 3, 14: 4, 15: 4,
  };

  // Egzantrik mod vampir + egzantrik tablosu
  static const _eccentricTable = {
    7:  (v: 2, e: 1),
    8:  (v: 2, e: 2),
    9:  (v: 2, e: 2),
    10: (v: 2, e: 2),
    11: (v: 3, e: 2),
    12: (v: 3, e: 3),
    13: (v: 3, e: 3),
    14: (v: 3, e: 3),
    15: (v: 3, e: 4),
  };

  // ROL DAĞILIMI HESAPLA
  static Map<String, int> calculateRoles(int playerCount, String gameMode) {
    final roles = <String, int>{};

    roles['doktor'] = 1;

    if (gameMode == 'eccentric' && _eccentricTable.containsKey(playerCount)) {
      final entry = _eccentricTable[playerCount]!;
      roles['vampir'] = entry.v;
      roles['egzantrik'] = entry.e;
    } else {
      roles['vampir'] = _normalVampirs[playerCount] ?? (playerCount / 3).toInt();
      roles['egzantrik'] = 0;
    }

    roles['koylu'] = playerCount - roles['vampir']! - roles['doktor']! - roles['egzantrik']!;

    return roles;
  }

  // EGZANTRİK ROLLERI RASTGELE SEÇ
  static List<String> selectEccentricRoles(int count) {
    final random = Random();
    final available = List.from(eccentricRoles); // Kopi al
    final selected = <String>[];

    for (int i = 0; i < count; i++) {
      final index = random.nextInt(available.length);
      selected.add(available[index]);
      available.removeAt(index); // Aynı rol tekrar gelmesin
    }

    return selected;
  }

  // OYUNCULARA ROL ATAMA
  static Map<String, String> assignRoles(
      List<String> playerIds, String gameMode) {
    final playerCount = playerIds.length;
    final roles = calculateRoles(playerCount, gameMode);
    final eccentricRoleNames =
        selectEccentricRoles(roles['egzantrik']!);

    // Tüm rolleri liste olarak oluştur
    final roleList = <String>[];

    // Vampirler
    for (int i = 0; i < roles['vampir']!; i++) {
      roleList.add('vampir');
    }

    // Doktorlar
    for (int i = 0; i < roles['doktor']!; i++) {
      roleList.add('doktor');
    }

    // Egzantrik roller
    for (var role in eccentricRoleNames) {
      roleList.add(role);
    }

    // Köylüler
    for (int i = 0; i < roles['koylu']!; i++) {
      roleList.add('koylu');
    }

    // Listeyı karıştır
    roleList.shuffle(Random());

    // Oyunculara ata
    final assignedRoles = <String, String>{};
    for (int i = 0; i < playerIds.length; i++) {
      assignedRoles[playerIds[i]] = roleList[i];
    }

    return assignedRoles;
  }

  // FIRESTORE'A ROL KAYDET
  static Future<void> saveRoles(
      String roomCode, Map<String, String> assignedRoles) async {
    try {
      // Her oyuncunun rolünü güncelle
      final updates = <String, dynamic>{};
      assignedRoles.forEach((userId, role) {
        updates['players.$userId.role'] = role;
      });

      // Oyun durumunu güncelle
      updates['gameState'] = 'playing';
      updates['currentPhase'] = 'night'; // İlk faz gece
      updates['phaseTime'] = '21:00'; // İlk gece saati
      updates['nightNumber'] = 1; // İlk gece
      updates['deadPlayers'] = []; // Henüz kimse ölmedi
      updates['nightActions'] = {}; // Gece aksiyonları
      updates['nightResults'] = {}; // Gece sonuçları

      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomCode)
          .update(updates);

      debugPrint('✅ Roller atandı ve kaydedildi!');
    } catch (e) {
      debugPrint('❌ Rol kaydetme hatası: $e');
    }
  }
}
