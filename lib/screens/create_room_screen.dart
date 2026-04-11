import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../constants/app_l10n.dart';
import 'room_lobby_screen.dart';
import '../services/auth_service.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _roomCode = '';
  int _playerCount = 10;
  String _gameMode = 'classic';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateRoomCode();
  }

  int get _minPlayerCount => _gameMode == 'eccentric' ? 7 : 4;

  void _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    _roomCode =
        List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
    setState(() {});
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppL10n.userNotFound),
            backgroundColor: Colors.red,
          ));
        }
        setState(() => _isLoading = false);
        return;
      }

      final userId = user['userId'];
      final displayName = user['displayName'];
      final avatarColor = user['avatarColor'];

      bool created = false;
      String codeToUse = _roomCode;

      for (int attempt = 0; attempt < 5; attempt++) {
        final roomRef =
            FirebaseFirestore.instance.collection('rooms').doc(codeToUse);

        created = await FirebaseFirestore.instance.runTransaction((tx) async {
          final snap = await tx.get(roomRef);
          if (snap.exists) return false;

          tx.set(roomRef, {
            'roomCode': codeToUse,
            'hostId': userId,
            'hostUsername': displayName,
            'password': _passwordController.text.isEmpty
                ? null
                : _passwordController.text,
            'maxPlayers': _playerCount,
            'playerCount': 1,
            'gameMode': _gameMode,
            'gameState': 'waiting',
            'players': {
              userId: {
                'username': displayName,
                'avatarColor': avatarColor,
                'isHost': true,
                'joinedAt': FieldValue.serverTimestamp(),
              }
            },
            'createdAt': FieldValue.serverTimestamp(),
          });
          return true;
        });

        if (created) break;

        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final random = Random();
        codeToUse =
            List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
        setState(() => _roomCode = codeToUse);
      }

      if (!created) throw Exception(AppL10n.roomCreateFailed);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => RoomLobbyScreen(roomCode: codeToUse)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppL10n.roomCreateFailed),
          backgroundColor: Colors.red,
        ));
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.createRoomTitle),
        backgroundColor: const Color(0xFF8B0000),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1A1A1A),
              const Color(0xFF8B0000).withValues(alpha: 0.3),
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
                Text(AppL10n.roomCodeLabel,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
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
                          backgroundColor: const Color(0xFF8B0000)),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // ŞİFRE
                Text(AppL10n.passwordOptional,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: AppL10n.passwordHintRoom,
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 12),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // OYUNCU SAYISI
                Text(AppL10n.playerCountLabel,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
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
                        min: _minPlayerCount.toDouble(),
                        max: 15,
                        divisions: 15 - _minPlayerCount,
                        activeColor: const Color(0xFFDC143C),
                        inactiveColor: Colors.white30,
                        onChanged: (value) =>
                            setState(() => _playerCount = value.toInt()),
                      ),
                    ),
                  ],
                ),
                Text(
                  AppL10n.playerRange(_minPlayerCount),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(height: 30),

                // OYUN MODU
                Text(AppL10n.gameModeLabel,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),

                // Klasik
                GestureDetector(
                  onTap: () => setState(() => _gameMode = 'classic'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gameMode == 'classic'
                          ? const Color(0xFFDC143C).withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppL10n.classic,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 5),
                              Text(AppL10n.classicDesc,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Egzantrik
                GestureDetector(
                  onTap: () => setState(() {
                    _gameMode = 'eccentric';
                    if (_playerCount < 7) _playerCount = 7;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _gameMode == 'eccentric'
                          ? const Color(0xFFDC143C).withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.05),
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppL10n.eccentric,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              const SizedBox(height: 5),
                              Text(AppL10n.eccentricDesc,
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white54)),
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
                        : Text(
                            AppL10n.createRoom,
                            style: const TextStyle(
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
