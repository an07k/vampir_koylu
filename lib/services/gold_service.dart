import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class GoldService {
  static const int winReward = 10;

  /// Add gold to user's balance
  static Future<void> addGold(String userId, int amount) async {
    assert(userId.isNotEmpty, 'userId cannot be empty');
    assert(amount >= 0, 'amount must be non-negative');

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'gold': FieldValue.increment(amount)});

      debugPrint('✅ Gold added: $userId +$amount');
    } catch (e) {
      debugPrint('❌ Error adding gold to $userId: $e');
      rethrow;
    }
  }

  /// Get user's gold balance
  /// Returns 0 if user not found or on error
  static Future<int> getGold(String userId) async {
    assert(userId.isNotEmpty, 'userId cannot be empty');
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) {
        debugPrint('⚠️ User not found: $userId');
        return 0;
      }
      final gold = (doc.data()?['gold'] as int?) ?? 0;
      return gold;
    } catch (e) {
      debugPrint('❌ Error loading gold for $userId: $e');
      rethrow; // Allow caller to handle error
    }
  }

  /// Award gold to winners
  /// Skips bot accounts and guest users
  static Future<void> awardWinGold(List<String> winnerIds) async {
    assert(winnerIds.isNotEmpty, 'winnerIds cannot be empty');

    try {
      for (final userId in winnerIds) {
        // Skip bot accounts
        if (userId.startsWith('bot_')) continue;

        // Check if user exists in users collection (registered users only)
        final playerDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (playerDoc.exists) {
          try {
            await addGold(userId, winReward);
          } catch (e) {
            debugPrint('⚠️ Failed to award gold to $userId: $e');
            // Continue with other winners
          }
        }
      }

      debugPrint('✅ Win gold awarded to winners');
    } catch (e) {
      debugPrint('❌ Error awarding win gold: $e');
      rethrow;
    }
  }
}
