import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_lobby_screen.dart';
import '../services/auth_service.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordRequired = false;
  String? _existingRoomCode;
  Map<String, dynamic>? _existingRoomData;

  @override
  void initState() {
    super.initState();
    _checkExistingRoom();
  }

  // MEVCUT ODA KONTROLÜ
  Future<void> _checkExistingRoom() async {
  try {
    final user = await AuthService.getCurrentUser();
    if (user == null) return;
    final userId = user['userId'];

    // Tüm waiting durumundaki odalara bak
    final roomsSnapshot = await FirebaseFirestore.instance
        .collection('rooms')
        .where('gameState', isEqualTo: 'waiting')
        .get();

    // Kullanıcının bulunduğu odayı bul
    for (var doc in roomsSnapshot.docs) {
      final roomData = doc.data();
      final players = roomData['players'] as Map<String, dynamic>;

      if (players.containsKey(userId)) {
        setState(() {
          _existingRoomCode = doc.id;
          _existingRoomData = roomData;
        });
        break;
      }
    }
  } catch (e) {
    debugPrint('❌ Mevcut oda kontrol hatası: $e');
  }
}
  

  // ODA KODU KONTROL ET
  Future<void> _checkRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();

    if (roomCode.isEmpty) {
      _showErrorDialog('Lütfen oda kodunu girin');
      return;
    }

    if (roomCode.length != 6) {
      _showErrorDialog('Oda kodu 6 haneli olmalıdır');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Oda var mı kontrol et
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomCode)
          .get();

      if (!roomDoc.exists) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Oda bulunamadı');
        return;
      }

      final roomData = roomDoc.data()!;

      // Şifre var mı kontrol et
      if (roomData['password'] != null && !_passwordRequired) {
        setState(() {
          _passwordRequired = true;
          _isLoading = false;
        });
        return;
      }

      // Şifre kontrolü
      if (roomData['password'] != null) {
        if (_passwordController.text != roomData['password']) {
          setState(() {
            _isLoading = false;
          });
          _showErrorDialog('Yanlış şifre');
          return;
        }
      }

      // Oyun başlamış mı kontrol et
      if (roomData['gameState'] != 'waiting') {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Oyun zaten başlamış');
        return;
      }

      // Kullanıcı zaten odada mı kontrol et
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        setState(() { _isLoading = false; });
        _showErrorDialog('Kullanıcı bilgisi bulunamadı');
        return;
      }
      final userId = user['userId'];
      final players = roomData['players'] as Map<String, dynamic>;
      if (players.containsKey(userId)) {
        setState(() {
          _isLoading = false;
        });
        // Zaten odadaysa direkt lobby'ye git
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => RoomLobbyScreen(roomCode: roomCode),
            ),
          );
        }
        return;
      }

      // Oda dolu mu kontrol et
      if (roomData['playerCount'] >= roomData['maxPlayers']) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Oda dolu');
        return;
      }

      // Odaya katıl
      await _joinRoom(roomCode);

    } catch (e) {
      debugPrint('❌ Oda kontrol hatası: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Bir hata oluştu. Tekrar deneyin.');
    }
  }

  // ODAYA KATIL
  Future<void> _joinRoom(String roomCode) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        _showErrorDialog('Kullanıcı bilgisi bulunamadı');
        return;
      }

      final userId = user['userId'];
      final displayName = user['displayName'];
      final avatarColor = user['avatarColor'];

      // Odaya oyuncu ekle
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomCode)
          .update({
        'players.$userId': {
          'username': displayName,
          'avatarColor': avatarColor,
          'isHost': false,
          'joinedAt': FieldValue.serverTimestamp(),
        },
        'playerCount': FieldValue.increment(1),
      });

      debugPrint('✅ Odaya katıldı: $roomCode');

      // Oda bekleme alanına git
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoomLobbyScreen(roomCode: roomCode),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Odaya katılma hatası: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Odaya katılırken hata oluştu');
    }
  }

  // HATA DİALOG
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
      appBar: AppBar(
        title: const Text('Odaya Katıl'),
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
                const SizedBox(height: 40),

                // ODA KODU
                const Text(
                  'Oda Kodu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _roomCodeController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: const TextStyle(
                      color: Colors.white38,
                      letterSpacing: 4,
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    // Otomatik büyük harf
                    _roomCodeController.value = TextEditingValue(
                      text: value.toUpperCase(),
                      selection: _roomCodeController.selection,
                    );
                  },
                ),
                const SizedBox(height: 30),

                // MEVCUT ODA UYARISI (varsa)
                if (_existingRoomData != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.orange,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                              size: 24,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Zaten bir odanız var',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // Oda Bilgileri
                        Row(
                          children: [
                            const Icon(
                              Icons.meeting_room,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Oda: $_existingRoomCode',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_existingRoomData!['playerCount']}/${_existingRoomData!['maxPlayers']} Oyuncu',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.gamepad,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _existingRoomData!['gameMode'] == 'classic'
                                  ? 'Klasik'
                                  : 'Egzantrik',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        // ODAYA DÖN butonu
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoomLobbyScreen(
                                    roomCode: _existingRoomCode!,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ODAYA DÖN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // ŞİFRE (Sadece gerekirse göster)
                if (_passwordRequired) ...[
                  const Text(
                    'Şifre',
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
                      hintText: 'Oda şifresi',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.lock,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // KATIL BUTONU
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC143C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'ODAYA KATIL',
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
    _roomCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
