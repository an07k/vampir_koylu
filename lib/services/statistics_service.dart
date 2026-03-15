import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StatisticsService {
  /// Oyun bitince tüm kayıtlı oyuncuların istatistiklerini güncelle
  static Future<void> recordGameResult({
    required List<String> winnerIds,
    required List<String> allPlayerIds,
  }) async {
    for (final userId in allPlayerIds) {
      if (userId.startsWith('bot_')) continue;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!userDoc.exists) continue;

      final isWinner = winnerIds.contains(userId);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'totalGames': FieldValue.increment(1),
          if (isWinner) 'wins': FieldValue.increment(1),
          if (!isWinner) 'losses': FieldValue.increment(1),
        });
      } catch (e) {
        debugPrint('❌ İstatistik güncellenemedi ($userId): $e');
      }
    }
  }
}
