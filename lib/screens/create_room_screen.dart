import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'room_lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _roomCode = '';
  int _playerCount = 10;
  String _gameMode = 'classic'; // 'classic' veya 'eccentric'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateRoomCode();
  }

  // 6 HANELİ RASTGELE KOD OLUŞTUR
  void _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    _roomCode = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    setState(() {});
  }

  // ODA OLUŞTURMA
  Future<void> _createRoom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Kullanıcı bilgilerini al
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final username = userDoc.data()!['username'];
      final avatarColor = userDoc.data()!['avatarColor'];

      // Odayı Firestore'a kaydet
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(_roomCode)
          .set({
        'roomCode': _roomCode,
        'hostId': userId,
        'hostUsername': username,
        'password': _passwordController.text.isEmpty ? null : _passwordController.text,
        'maxPlayers': _playerCount,
        'playerCount': 1,
        'gameMode': _gameMode,
        'gameState': 'waiting',
        'players': {
          userId: {
            'username': username,
            'avatarColor': avatarColor,
            'isHost': true,
            'joinedAt': FieldValue.serverTimestamp(),
          }
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Oda oluşturuldu: $_roomCode');

      // Oda bekleme alanına git
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoomLobbyScreen(roomCode: _roomCode),
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Oda oluşturma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oda oluşturulamadı. Tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oda Oluştur'),
        backgroundColor: const Color(0xFF8B0000),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ODA KODU
                const Text(
                  'Oda Kodu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _roomCode,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC143C),
                                letterSpacing: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _generateRoomCode,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // ŞİFRE
                const Text(
                  'Şifre (Opsiyonel)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Şifre girmezseniz oda herkese açık olur',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // OYUNCU SAYISI
                const Text(
                  'Oyuncu Sayısı',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '$_playerCount',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFDC143C),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Slider(
                        value: _playerCount.toDouble(),
                        min: 4,
                        max: 15,
                        divisions: 9,
                        activeColor: const Color(0xFFDC143C),
                        inactiveColor: Colors.white30,
                        onChanged: (value) {
                          setState(() {
                            _playerCount = value.toInt();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const Text(
                  '4-15 arası',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 30),

                // OYUN MODU
                const Text(
                  'Oyun Modu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                
                // Klasik Mod
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _gameMode = 'classic';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gameMode == 'classic'
                          ? const Color(0xFFDC143C).withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _gameMode == 'classic'
                            ? const Color(0xFFDC143C)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _gameMode == 'classic'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _gameMode == 'classic'
                              ? const Color(0xFFDC143C)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Klasik',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Vampir, Köylü, Doktor',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Egzantrik Mod
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _gameMode = 'eccentric';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gameMode == 'eccentric'
                          ? const Color(0xFFDC143C).withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _gameMode == 'eccentric'
                            ? const Color(0xFFDC143C)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _gameMode == 'eccentric'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: _gameMode == 'eccentric'
                              ? const Color(0xFFDC143C)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Egzantrik',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '+ Rastgele 1-2 özel rol (Âşık, Deli, vs.)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // ODA OLUŞTUR BUTONU
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC143C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'ODA OLUŞTUR',
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
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}