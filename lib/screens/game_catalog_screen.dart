import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../games/game_definition.dart';
import '../games/game_registry.dart';
import 'platform_create_room_screen.dart';

/// Game picker — the entry point for starting a new game. Tapping a game asks
/// for a play mode (if it supports both) then opens room creation.
class GameCatalogScreen extends StatelessWidget {
  const GameCatalogScreen({super.key});

  Future<void> _onGameTap(BuildContext context, GameDefinition game) async {
    PlayMode? mode;
    if (game.meta.supportsBothModes) {
      mode = await _selectMode(context);
      if (mode == null) return;
    } else {
      mode = game.meta.supportedModes.first;
    }
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlatformCreateRoomScreen(gameId: game.meta.gameId, mode: mode!),
      ),
    );
  }

  Future<PlayMode?> _selectMode(BuildContext context) {
    return showModalBottomSheet<PlayMode>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Nasıl oynanacak?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ),
            _modeTile(
              ctx,
              PlayMode.multi,
              Icons.devices,
              'Herkes kendi telefonunda',
              'Her oyuncu kendi cihazından katılır.',
            ),
            _modeTile(
              ctx,
              PlayMode.single,
              Icons.phone_android,
              'Tek telefon',
              'Tek cihaz elden ele dolaşır.',
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _modeTile(BuildContext ctx, PlayMode mode, IconData icon, String title,
      String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      onTap: () => Navigator.pop(ctx, mode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final games = GameRegistry.all;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyun Seç'),
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
        child: games.isEmpty
            ? const Center(
                child: Text('Henüz oyun yok.',
                    style: TextStyle(color: Colors.white54)))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: games.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _gameCard(context, games[i]),
              ),
      ),
    );
  }

  Widget _gameCard(BuildContext context, GameDefinition game) {
    final m = game.meta;
    return InkWell(
      onTap: () => _onGameTap(context, game),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Text(m.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(m.description,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text('${m.minSeats}-${m.maxSeats} oyuncu',
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
