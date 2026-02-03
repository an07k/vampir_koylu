import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GoldService {
  static const int winReward = 10;
  static const int hostBonus = 5;
  static const String bonusNickname = 'kadergamer123';

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

  // OYU BAŞLAMA BONUSU — Host @kadergamer123 ise herkese 5 gold
  static Future<void> awardGameStartBonus(String roomCode) async {
    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomCode)
          .get();

      if (!roomDoc.exists) return;

      final roomData = roomDoc.data()!;
      final hostId = roomData['hostId'] as String;

      // Host'un nickname'ini kontrol et
      final hostDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(hostId)
          .get();

      if (!hostDoc.exists) return;
      final hostNickname = hostDoc.data()!['nickname'] as String;

      if (hostNickname != bonusNickname) return;

      // Host kadergamer123 → tüm real oyunculara bonus ver
      final players = roomData['players'] as Map<String, dynamic>;

      for (final playerId in players.keys) {
        // Bot ve host hariç
        if (playerId.startsWith('bot_') || playerId == hostId) continue;

        // Users koleksiyonunda var mı kontrol (guest olmayan)
        final playerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(playerId)
            .get();

        if (playerDoc.exists) {
          await addGold(playerId, hostBonus);
        }
      }

      debugPrint('✅ kadergamer123 bonus dağıtıldı');
    } catch (e) {
      debugPrint('❌ Bonus dağıtım hatası: $e');
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
