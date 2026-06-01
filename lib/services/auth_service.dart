import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Firebase Auth based authentication.
///
/// - Guests       -> Firebase Anonymous Auth
/// - Accounts     -> Firebase Email/Password (email derived from nickname)
///
/// Every user (guest or account) has a profile document at `users/{uid}`.
/// The Firebase Auth uid IS the userId used throughout the app.
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Nicknames are not real emails; we derive a stable synthetic email so we
  /// can use Firebase Email/Password while keeping the nickname-based UX.
  /// Firebase enforces email uniqueness -> nickname uniqueness comes for free.
  static const String _emailDomain = 'vampirkoylu.app';

  static String _nicknameToEmail(String nickname) =>
      '${nickname.trim().toLowerCase()}@$_emailDomain';

  // CREATE ACCOUNT
  static Future<Map<String, dynamic>> createAccount({
    required String nickname,
    required String displayName,
    required String password,
    required String avatarColor,
  }) async {
    final n = nickname.trim();
    final d = displayName.trim();

    // VALIDATION
    if (n.isEmpty) return {'success': false, 'error': 'Nickname boş olamaz'};
    if (n.length < 3) {
      return {'success': false, 'error': 'Nickname en az 3 karakter olmalı'};
    }
    if (n.length > 20) {
      return {'success': false, 'error': 'Nickname en fazla 20 karakter olmalı'};
    }
    if (d.isEmpty) return {'success': false, 'error': 'Oyun ismi boş olamaz'};
    if (d.length < 2) {
      return {'success': false, 'error': 'Oyun ismi en az 2 karakter olmalı'};
    }
    if (d.length > 15) {
      return {'success': false, 'error': 'Oyun ismi en fazla 15 karakter olmalı'};
    }
    if (password.length < 6) {
      // Firebase requires >= 6 chars for email/password.
      return {'success': false, 'error': 'Şifre en az 6 karakter olmalı'};
    }

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: _nicknameToEmail(n),
        password: password,
      );
      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'nickname': n,
        'nicknameLower': n.toLowerCase(),
        'displayName': d,
        'avatarColor': avatarColor,
        'isGuest': false,
        'createdAt': FieldValue.serverTimestamp(),
        'totalGames': 0,
        'wins': 0,
        'losses': 0,
        'gold': 0,
      });

      return {
        'success': true,
        'userId': uid,
        'nickname': n,
        'displayName': d,
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return {'success': false, 'error': 'Bu nickname zaten alınmış'};
      }
      if (e.code == 'weak-password') {
        return {'success': false, 'error': 'Şifre çok zayıf'};
      }
      debugPrint('❌ createAccount error: ${e.code}');
      return {'success': false, 'error': e.message ?? e.code};
    } catch (e) {
      debugPrint('❌ createAccount error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String nickname,
    required String password,
  }) async {
    final n = nickname.trim();
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: _nicknameToEmail(n),
        password: password,
      );
      final uid = cred.user!.uid;
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};

      return {
        'success': true,
        'userId': uid,
        'nickname': data['nickname'] ?? n,
        'displayName': data['displayName'],
        'avatarColor': data['avatarColor'],
      };
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return {'success': false, 'error': 'Hesap bulunamadı veya şifre yanlış'};
      }
      if (e.code == 'wrong-password') {
        return {'success': false, 'error': 'Yanlış şifre'};
      }
      debugPrint('❌ login error: ${e.code}');
      return {'success': false, 'error': e.message ?? e.code};
    } catch (e) {
      debugPrint('❌ login error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // GUEST LOGIN (anonymous)
  static Future<Map<String, dynamic>> guestLogin({
    required String displayName,
    required String avatarColor,
  }) async {
    final d = displayName.trim();
    if (d.isEmpty) return {'success': false, 'error': 'İsim boş olamaz'};
    if (d.length < 2) {
      return {'success': false, 'error': 'İsim en az 2 karakter olmalı'};
    }
    if (d.length > 15) {
      return {'success': false, 'error': 'İsim en fazla 15 karakter olmalı'};
    }

    try {
      final cred = await _auth.signInAnonymously();
      final uid = cred.user!.uid;

      await _db.collection('users').doc(uid).set({
        'displayName': d,
        'avatarColor': avatarColor,
        'isGuest': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'userId': uid,
        'displayName': d,
        'isGuest': true,
      };
    } catch (e) {
      debugPrint('❌ guestLogin error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // UPDATE DISPLAY NAME
  static Future<Map<String, dynamic>> updateDisplayName({
    required String userId,
    required String newDisplayName,
  }) async {
    final d = newDisplayName.trim();
    if (d.isEmpty) return {'success': false, 'error': 'İsim boş olamaz'};
    if (d.length < 2) {
      return {'success': false, 'error': 'İsim en az 2 karakter olmalı'};
    }
    if (d.length > 15) {
      return {'success': false, 'error': 'İsim en fazla 15 karakter olmalı'};
    }

    try {
      await _db.collection('users').doc(userId).update({'displayName': d});
      return {'success': true};
    } catch (e) {
      debugPrint('❌ updateDisplayName error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get current logged-in user.
  /// Returns null if no user is logged in.
  /// Map: userId, isGuest, displayName, nickname?, avatarColor
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;

    try {
      final doc = await _db.collection('users').doc(fbUser.uid).get();
      if (!doc.exists) {
        // Auth session without a profile doc -> stale, sign out.
        await logout();
        return null;
      }

      final data = doc.data()!;
      final isGuest = data['isGuest'] ?? fbUser.isAnonymous;
      return {
        'userId': fbUser.uid,
        'isGuest': isGuest,
        'displayName': data['displayName'],
        'nickname': isGuest ? null : data['nickname'],
        'avatarColor': data['avatarColor'],
      };
    } catch (e) {
      debugPrint('❌ getCurrentUser error: $e');
      return null;
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    await _auth.signOut();
  }
}
