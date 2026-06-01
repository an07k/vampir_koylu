import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../games/game_definition.dart';
import '../games/game_registry.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import 'platform_lobby_screen.dart';

class PlatformCreateRoomScreen extends StatefulWidget {
  final String gameId;
  final PlayMode mode;

  const PlatformCreateRoomScreen({
    super.key,
    required this.gameId,
    required this.mode,
  });

  @override
  State<PlatformCreateRoomScreen> createState() =>
      _PlatformCreateRoomScreenState();
}

class _PlatformCreateRoomScreenState extends State<PlatformCreateRoomScreen> {
  final _passwordController = TextEditingController();
  late final GameDefinition _game;
  late int _maxSeats;
  late Map<String, dynamic> _config;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _game = GameRegistry.byId(widget.gameId)!;
    _maxSeats = _game.meta.minSeats;
    _config = Map<String, dynamic>.from(_game.defaultConfig());
  }

  Future<void> _create() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        _toast('Kullanıcı bulunamadı');
        setState(() => _isLoading = false);
        return;
      }
      final code = await RoomService.createRoom(
        gameId: widget.gameId,
        mode: widget.mode,
        maxSeats: _maxSeats,
        hostUid: user['userId'],
        hostDisplayName: user['displayName'] ?? 'Host',
        hostAvatarColor: user['avatarColor'] ?? '#DC143C',
        password: _passwordController.text.trim(),
        config: _config,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PlatformLobbyScreen(roomCode: code)),
      );
    } catch (e) {
      _toast('Oda oluşturulamadı');
      setState(() => _isLoading = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final m = _game.meta;
    final configWidget = _game.buildLobbyConfig(context, _config, () => setState(() {}));
    return Scaffold(
      appBar: AppBar(
        title: Text('${m.name} • Oda'),
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
                _modeBanner(),
                const SizedBox(height: 24),

                if (m.minSeats != m.maxSeats) ...[
                  const Text('Oyuncu sayısı',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Row(
                    children: [
                      Text('$_maxSeats',
                          style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.secondary)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Slider(
                          value: _maxSeats.toDouble(),
                          min: m.minSeats.toDouble(),
                          max: m.maxSeats.toDouble(),
                          divisions: m.maxSeats - m.minSeats,
                          activeColor: AppColors.secondary,
                          onChanged: (v) => setState(() => _maxSeats = v.toInt()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                const Text('Şifre (opsiyonel)',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
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

                if (configWidget != null) ...[
                  const SizedBox(height: 24),
                  const Text('Oyun ayarları',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  configWidget,
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _create,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ODA OLUŞTUR',
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

  Widget _modeBanner() {
    final isMulti = widget.mode == PlayMode.multi;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(isMulti ? Icons.devices : Icons.phone_android,
              color: AppColors.secondary),
          const SizedBox(width: 12),
          Text(isMulti ? 'Herkes kendi telefonunda' : 'Tek telefon',
              style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
