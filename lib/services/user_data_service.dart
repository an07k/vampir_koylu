import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'gold_service.dart';

class UserDataService {
  /// Load complete user data including gold balance
  /// Returns null if user is not logged in
  static Future<Map<String, dynamic>?> loadUserData() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) return null;

    final isGuest = user['isGuest'] ?? false;
    int gold = 0;

    // Load gold only for registered users
    if (!isGuest) {
      try {
        gold = await GoldService.getGold(user['userId']);
      } catch (e) {
        print('Error loading gold: $e');
        gold = 0;
      }
    }

    return {
      ...user,
      'gold': gold,
    };
  }

  /// Check if user already has an active room
  /// Returns room ID if found, null otherwise
  static Future<String?> getUserActiveRoom(String userId) async {
    try {
      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('gameState', isEqualTo: 'waiting')
          .get();

      for (var doc in roomsSnapshot.docs) {
        final players = doc.data()['players'] as Map<String, dynamic>?;
        if (players?.containsKey(userId) ?? false) {
          return doc.id;
        }
      }
      return null;
    } catch (e) {
      print('Error checking active room: $e');
      return null;
    }
  }
}
