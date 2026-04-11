import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_l10n.dart';
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

  Future<void> _checkExistingRoom() async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) return;
      final userId = user['userId'];

      final roomsSnapshot = await FirebaseFirestore.instance
          .collection('rooms')
          .where('gameState', isEqualTo: 'waiting')
          .get();

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

  Future<void> _checkRoom() async {
    final roomCode = _roomCodeController.text.trim().toUpperCase();

    if (roomCode.isEmpty) {
      _showErrorDialog(AppL10n.enterRoomCode);
      return;
    }
    if (roomCode.length != 6) {
      _showErrorDialog(AppL10n.roomCodeLength);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomCode)
          .get();

      if (!roomDoc.exists) {
        setState(() => _isLoading = false);
        _showErrorDialog(AppL10n.roomNotFoundError);
        return;
      }

      final roomData = roomDoc.data()!;

      if (roomData['password'] != null && !_passwordRequired) {
        setState(() {
          _passwordRequired = true;
          _isLoading = false;
        });
        return;
      }

      if (roomData['password'] != null &&
          _passwordController.text != roomData['password']) {
        setState(() => _isLoading = false);
        _showErrorDialog(AppL10n.wrongPassword);
        return;
      }

      if (roomData['gameState'] != 'waiting') {
        setState(() => _isLoading = false);
        _showErrorDialog(AppL10n.gameAlreadyStarted);
        return;
      }

      final user = await AuthService.getCurrentUser();
      if (user == null) {
        setState(() => _isLoading = false);
        _showErrorDialog(AppL10n.userNotFoundShort);
        return;
      }

      final userId = user['userId'];
      final players = roomData['players'] as Map<String, dynamic>;

      if (players.containsKey(userId)) {
        setState(() => _isLoading = false);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => RoomLobbyScreen(roomCode: roomCode)),
          );
        }
        return;
      }

      if (roomData['playerCount'] >= roomData['maxPlayers']) {
        setState(() => _isLoading = false);
        _showErrorDialog(AppL10n.roomFull);
        return;
      }

      await _joinRoom(roomCode);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(AppL10n.tryAgain);
    }
  }

  Future<void> _joinRoom(String roomCode) async {
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        _showErrorDialog(AppL10n.userNotFoundShort);
        return;
      }

      await FirebaseFirestore.instance.collection('rooms').doc(roomCode).update({
        'players.${user['userId']}': {
          'username': user['displayName'],
          'avatarColor': user['avatarColor'],
          'isHost': false,
          'joinedAt': FieldValue.serverTimestamp(),
        },
        'playerCount': FieldValue.increment(1),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => RoomLobbyScreen(roomCode: roomCode)),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog(AppL10n.joinError);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: Text(AppL10n.error,
            style: const TextStyle(color: Colors.white)),
        content: Text(message,
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppL10n.ok,
                style: const TextStyle(color: Color(0xFFDC143C))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppL10n.joinRoomTitle),
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
                const SizedBox(height: 40),

                // ODA KODU
                Text(AppL10n.roomCodeLabel,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                TextField(
                  controller: _roomCodeController,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'ABC123',
                    hintStyle: const TextStyle(
                        color: Colors.white38, letterSpacing: 4),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                  ),
                  onChanged: (value) {
                    _roomCodeController.value = TextEditingValue(
                      text: value.toUpperCase(),
                      selection: _roomCodeController.selection,
                    );
                  },
                ),
                const SizedBox(height: 30),

                // MEVCUT ODA UYARISI
                if (_existingRoomData != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded,
                                color: Colors.orange, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              AppL10n.alreadyInRoomWarning,
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            const Icon(Icons.meeting_room,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              AppL10n.roomLabel(_existingRoomCode!),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.people,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              AppL10n.playerCountDisplay(
                                _existingRoomData!['playerCount'],
                                _existingRoomData!['maxPlayers'],
                              ),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.gamepad,
                                color: Colors.white70, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              AppL10n.gameModeDisplay(
                                  _existingRoomData!['gameMode']),
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoomLobbyScreen(
                                      roomCode: _existingRoomCode!),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              AppL10n.returnToRoom,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // ŞİFRE
                if (_passwordRequired) ...[
                  Text(AppL10n.passwordLabel,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: AppL10n.passwordHintJoin,
                      hintStyle:
                          const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.lock,
                          color: Colors.white70),
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
                        ? const CircularProgressIndicator(
                            color: Colors.white)
                        : Text(
                            AppL10n.joinRoomBtn,
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
    _roomCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
