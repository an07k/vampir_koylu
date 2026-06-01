import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import 'platform_lobby_screen.dart';

/// Multi-device join: enter a room code (+ optional password) to take a seat
/// in someone else's room, then drop into the shared lobby.
class PlatformJoinRoomScreen extends StatefulWidget {
  const PlatformJoinRoomScreen({super.key});

  @override
  State<PlatformJoinRoomScreen> createState() => _PlatformJoinRoomScreenState();
}

class _PlatformJoinRoomScreenState extends State<PlatformJoinRoomScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _join() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _toast('Oda kodu gir');
      return;
    }
    setState(() => _isLoading = true);
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      _toast('Kullanıcı bulunamadı');
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final err = await RoomService.joinRoom(
      code: code,
      uid: user['userId'],
      displayName: user['displayName'] ?? 'Oyuncu',
      avatarColor: user['avatarColor'] ?? '#DC143C',
      password: _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (err != null) {
      _toast(err);
      setState(() => _isLoading = false);
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => PlatformLobbyScreen(roomCode: code)),
    );
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Odaya Katıl'),
        backgroundColor: AppColors.primary,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.background, Color(0x4D8B0000)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Oda kodu',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 24, letterSpacing: 8),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Şifre (varsa)',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _join,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('KATIL',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
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
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
