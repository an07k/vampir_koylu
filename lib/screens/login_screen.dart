import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  Color _selectedColor = const Color(0xFFDC143C); // Varsayılan: Kırmızı
  bool _isLoading = false; // Yükleniyor durumu için

  // 6 renk paleti
  final List<Color> _avatarColors = [
    const Color(0xFFDC143C), // Kırmızı
    const Color(0xFF1E90FF), // Mavi
    const Color(0xFF32CD32), // Yeşil
    const Color(0xFF9370DB), // Mor
    const Color(0xFFFF8C00), // Turuncu
    const Color(0xFFFFD700), // Sarı
  ];

  // USERNAME VALIDATION
  String? _validateUsername(String username) {
    // Boş mu?
    if (username.isEmpty) {
      return 'Kullanıcı adı boş olamaz';
    }

    // 3-15 karakter arası mı?
    if (username.length < 3) {
      return 'En az 3 karakter olmalı';
    }
    if (username.length > 15) {
      return 'En fazla 15 karakter olmalı';
    }

    // Sadece harf ve rakam mı? (Türkçe karakterler dahil)
    final alphanumeric = RegExp(r'^[a-zA-ZığüşöçİĞÜŞÖÇ0-9]+$');
    if (!alphanumeric.hasMatch(username)) {
      return 'Sadece harf ve rakam kullanılabilir';
    }

    return null; // Hata yoksa null döner
  }

  // FIRESTORE'DA UNIQUE KONTROLÜ
  Future<bool> _isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      return querySnapshot.docs.isEmpty; // Boşsa kullanılabilir
    } catch (e) {
      debugPrint('❌ Username kontrol hatası: $e');
      return false;
    }
  }

  // LOGIN İŞLEMİ
  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();

    // 1. Validation kontrolü
    final error = _validateUsername(username);
    if (error != null) {
      _showErrorDialog(error);
      return;
    }

    // 2. Yükleniyor durumuna geç
    setState(() {
      _isLoading = true;
    });

    // 3. Unique kontrolü
    final isAvailable = await _isUsernameAvailable(username);
    if (!isAvailable) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Bu kullanıcı adı zaten alınmış 😢');
      return;
    }

    // 4. Buraya kadar geldiyse her şey OK!
    debugPrint('✅ Validation başarılı!');
    debugPrint('Username: $username');
    debugPrint('Color: $_selectedColor');

    // 5. Firebase Anonymous Auth ile giriş yap
    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final userId = userCredential.user!.uid;

      // 6. Kullanıcı bilgilerini Firestore'a kaydet
      final r = (_selectedColor.r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
      final g = (_selectedColor.g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
      final b = (_selectedColor.b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
      final colorHex = '$r$g$b';

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'username': username,
        'avatarColor': '#$colorHex',
        'createdAt': FieldValue.serverTimestamp(),
        'totalGames': 0,
        'wins': 0,
        'losses': 0,
      });

      debugPrint('✅ Firebase Auth başarılı! UserID: $userId');
      debugPrint('✅ Firestore kayıt başarılı!');

      // 7. Ana menüye yönlendir
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main-menu');
      }
    } catch (e) {
      debugPrint('❌ Firebase hata: $e');
      _showErrorDialog('Bir hata oluştu. Lütfen tekrar deneyin.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // HATA DIALOG
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text(
          'Hata',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'TAMAM',
              style: TextStyle(color: Color(0xFFDC143C)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF8B0000).withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const Icon(
                    Icons.nights_stay,
                    size: 80,
                    color: Color(0xFFDC143C),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'VAMPİR KÖYLÜ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Oyuna Katıl',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Seçili Avatar Önizlemesi
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _usernameController.text.isNotEmpty
                            ? _usernameController.text[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Renk Seçici
                  const Text(
                    'Avatar Rengi Seç',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Wrap(
                    spacing: 15,
                    children: _avatarColors.map((color) {
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.6),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 30,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // Username Input
                  TextField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Kullanıcı Adı (3-15 karakter)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.white70,
                      ),
                    ),
                    maxLength: 15,
                    onChanged: (value) {
                      setState(() {}); // Avatar önizlemesini güncelle
                    },
                  ),
                  const SizedBox(height: 30),

                  // Devam Et Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC143C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'DEVAM ET',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}