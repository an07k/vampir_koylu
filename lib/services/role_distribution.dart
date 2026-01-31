import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class RoleDistribution {
  // EGZANTRİK ROL HAVUZU
  static final List<String> eccentricRoles = [
    'asik',      // Âşık
    'deli',      // Deli
    'dedektif',  // Detektif
    'misafir',   // Misafir
    'polis',     // Polis
    'takipci',   // Takipçi
  ];

  // ROL DAĞILIMI HESAPLA
  static Map<String, int> calculateRoles(int playerCount, String gameMode) {
    final roles = <String, int>{};

    // Vampir sayısı = oyuncu / 3 (aşağı yuvarla)
    roles['vampir'] = (playerCount / 3).toInt();

    // Doktor sayısı
    roles['doktor'] = playerCount >= 12 ? 2 : 1;

    // Egzantrik rol sayısı
    int eccentricCount = 0;
    if (gameMode == 'eccentric') {
      if (playerCount >= 10) {
        eccentricCount = 2;
      } else if (playerCount >= 7) {
        eccentricCount = 1;
      }
    }
    roles['egzantrik'] = eccentricCount;

    // Köylü = kalan
    roles['koylu'] =
        playerCount - roles['vampir']! - roles['doktor']! - eccentricCount;

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

// TEST ETMEK İÇİN
  static void testRoles() {
  debugPrint('\n========== ROL DAĞILIMI TEST ==========\n');

  for (int i = 6; i <= 15; i++) {
    // Klasik mod test
    final classicRoles = calculateRoles(i, 'classic');
    debugPrint('--- $i Kişi (Klasik) ---');
    debugPrint('Vampir:    ${classicRoles['vampir']}');
    debugPrint('Doktor:    ${classicRoles['doktor']}');
    debugPrint('Köylü:     ${classicRoles['koylu']}');
    debugPrint('');

    // Egzantrik mod test
    final eccentricRoles = calculateRoles(i, 'eccentric');
    final selectedRoles = selectEccentricRoles(eccentricRoles['egzantrik']!);
    debugPrint('--- $i Kişi (Egzantrik) ---');
    debugPrint('Vampir:    ${eccentricRoles['vampir']}');
    debugPrint('Doktor:    ${eccentricRoles['doktor']}');
    debugPrint('Egzantrik: ${eccentricRoles['egzantrik']} → $selectedRoles');
    debugPrint('Köylü:     ${eccentricRoles['koylu']}');
    debugPrint('');
  }

  debugPrint('========================================\n');
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
