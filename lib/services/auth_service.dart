import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // RANDOM SALT OLUŞTUR
  static String generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(saltBytes);
  }

  // ŞİFREYİ HASH'LE (salt + şifre)
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
  }

  // NICKNAME UNIQUE KONTROLÜ
  static Future<bool> isNicknameAvailable(String nickname) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: nickname)
        .get();
    return snapshot.docs.isEmpty;
  }

  // HESAP OLUŞTUR
  static Future<Map<String, dynamic>> createAccount({
    required String nickname,
    required String displayName,
    required String password,
    required String avatarColor,
  }) async {
    try {
      // VALİDASYON
      if (nickname.isEmpty) {
        return {'success': false, 'error': 'Nickname boş olamaz'};
      }
      if (nickname.length < 3) {
        return {'success': false, 'error': 'Nickname en az 3 karakter olmalı'};
      }
      if (nickname.length > 20) {
        return {'success': false, 'error': 'Nickname en fazla 20 karakter olmalı'};
      }
      if (displayName.isEmpty) {
        return {'success': false, 'error': 'Oyun ismi boş olamaz'};
      }
      if (displayName.length < 2) {
        return {'success': false, 'error': 'Oyun ismi en az 2 karakter olmalı'};
      }
      if (displayName.length > 15) {
        return {'success': false, 'error': 'Oyun ismi en fazla 15 karakter olmalı'};
      }
      if (password.length < 4) {
        return {'success': false, 'error': 'Şifre en az 4 karakter olmalı'};
      }

      // Nickname kullanılmış mı kontrol et
      final isAvailable = await isNicknameAvailable(nickname);
      if (!isAvailable) {
        return {'success': false, 'error': 'Bu nickname zaten alınmış'};
      }

      // Salt ve hash oluştur
      final salt = generateSalt();
      final hashedPassword = hashPassword(password, salt);

      // Firestore'a kaydet
      final docRef = FirebaseFirestore.instance.collection('users').doc();
      await docRef.set({
        'nickname': nickname,
        'displayName': displayName,
        'salt': salt,
        'password': hashedPassword,
        'avatarColor': avatarColor,
        'isGuest': false,
        'createdAt': FieldValue.serverTimestamp(),
        'totalGames': 0,
        'wins': 0,
        'losses': 0,
      });

      await saveUserId(docRef.id, false);
      return {
        'success': true,
        'userId': docRef.id,
        'nickname': nickname,
        'displayName': displayName,
      };
    } catch (e) {
      debugPrint('❌ Hesap oluşturma hatası: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // GİRİŞ YAP
  static Future<Map<String, dynamic>> login({
    required String nickname,
    required String password,
  }) async {
    try {
      // Nickname ile kullanıcıyı bul
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nickname', isEqualTo: nickname)
          .where('isGuest', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return {'success': false, 'error': 'Hesap bulunamadı'};
      }

      final doc = snapshot.docs.first;
      final userData = doc.data();
      final hashedInput = hashPassword(password, userData['salt']);

      if (hashedInput == userData['password']) {
        await saveUserId(doc.id, false);
        return {
          'success': true,
          'userId': doc.id,
          'nickname': userData['nickname'],
          'displayName': userData['displayName'],
          'avatarColor': userData['avatarColor'],
        };
      }

      return {'success': false, 'error': 'Yanlış şifre'};
    } catch (e) {
      debugPrint('❌ Giriş hatası: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // MİSAFİR GİRİŞ
  static Future<Map<String, dynamic>> guestLogin({
    required String displayName,
    required String avatarColor,
  }) async {
    try {
      // VALİDASYON
      if (displayName.isEmpty) {
        return {'success': false, 'error': 'İsim boş olamaz'};
      }
      if (displayName.length < 2) {
        return {'success': false, 'error': 'İsim en az 2 karakter olmalı'};
      }
      if (displayName.length > 15) {
        return {'success': false, 'error': 'İsim en fazla 15 karakter olmalı'};
      }

      final docRef = FirebaseFirestore.instance.collection('guests').doc();
      await docRef.set({
        'displayName': displayName,
        'avatarColor': avatarColor,
        'isGuest': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await saveUserId(docRef.id, true);
      return {
        'success': true,
        'userId': docRef.id,
        'displayName': displayName,
        'isGuest': true,
      };
    } catch (e) {
      debugPrint('❌ Misafir giriş hatası: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // OYUN İSMİNİ DEĞİŞTİR
  static Future<Map<String, dynamic>> updateDisplayName({
    required String userId,
    required String newDisplayName,
  }) async {
    try {
      // VALİDASYON
      if (newDisplayName.isEmpty) {
        return {'success': false, 'error': 'İsim boş olamaz'};
      }
      if (newDisplayName.length < 2) {
        return {'success': false, 'error': 'İsim en az 2 karakter olmalı'};
      }
      if (newDisplayName.length > 15) {
        return {'success': false, 'error': 'İsim en fazla 15 karakter olmalı'};
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'displayName': newDisplayName});

      return {'success': true};
    } catch (e) {
      debugPrint('❌ İsim değiştirme hatası: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // =========================================
  // LOCAL STORAGE (Session Management)
  // =========================================

  // USER ID KAYDET
  static Future<void> saveUserId(String userId, bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setBool('isGuest', isGuest);
  }

  // USER ID AL
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    final isGuest = prefs.getBool('isGuest') ?? false;

    if (userId == null) {
      return null;
    }

    try {
      // Firestore'dan kullanıcı bilgilerini al
      final collection = isGuest ? 'guests' : 'users';
      final doc = await FirebaseFirestore.instance
          .collection(collection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        // Kullanıcı silinmiş, local storage'ı temizle
        await logout();
        return null;
      }

      final data = doc.data()!;
      return {
        'userId': userId,
        'isGuest': isGuest,
        'displayName': data['displayName'],
        'nickname': isGuest ? null : data['nickname'],
        'avatarColor': data['avatarColor'],
      };
    } catch (e) {
      debugPrint('❌ Kullanıcı bilgisi alma hatası: $e');
      return null;
    }
  }

  // LOGOUT
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('isGuest');
  }
}