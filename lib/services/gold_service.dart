import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GoldService {
  static const int winReward = 10;

  // GOLD EKLE
  static Future<void> addGold(String userId, int amount) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'gold': FieldValue.increment(amount)});

      debugPrint('✅ Gold eklendi: $userId +$amount');
    } catch (e) {
      debugPrint('❌ Gold ekleme hatası: $e');
    }
  }

  // GOLD AL
  static Future<int> getGold(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return 0;
      return (doc.data()!['gold'] as int?) ?? 0;
    } catch (e) {
      debugPrint('❌ Gold alma hatası: $e');
      return 0;
    }
  }

  // KAZANANLARA GOLD VER
  static Future<void> awardWinGold(List<String> winnerIds) async {
    try {
      for (final userId in winnerIds) {
        if (userId.startsWith('bot_')) continue;

        // Users koleksiyonunda var mı kontrol (guest olmayan)
        final playerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (playerDoc.exists) {
          await addGold(userId, winReward);
        }
      }

      debugPrint('✅ Kazanma gold dağıtıldı');
    } catch (e) {
      debugPrint('❌ Kazanma gold hatası: $e');
    }
  }
}
