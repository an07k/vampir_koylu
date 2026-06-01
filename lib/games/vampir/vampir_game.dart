import 'package:flutter/material.dart';
import '../game_definition.dart';
import 'vampir_resolver.dart';
import 'vampir_match_screen.dart';

/// Vampir Köylü game module. Real night/day/role logic lives in
/// [VampirResolver]; the in-match UI (with its own role-reveal gate) is
/// [VampirMatchScreen].
class VampirGame extends GameDefinition {
  @override
  GameMeta get meta => const GameMeta(
        gameId: 'vampir',
        name: 'Vampir Köylü',
        emoji: '🧛',
        description: 'Köylüler vampirleri bulmaya çalışır.',
        minSeats: 4,
        maxSeats: 15,
        supportedModes: {PlayMode.single, PlayMode.multi},
      );

  @override
  final GameResolver resolver = VampirResolver();

  @override
  Map<String, dynamic> defaultConfig() => {'gameMode': 'classic'};

  @override
  Widget? buildLobbyConfig(
    BuildContext context,
    Map<String, dynamic> config,
    VoidCallback onChanged,
  ) {
    final mode = config['gameMode'] ?? 'classic';
    Widget option(String value, String label) => RadioListTile<String>(
          value: value,
          groupValue: mode,
          onChanged: (v) {
            config['gameMode'] = v;
            onChanged();
          },
          title: Text(label, style: const TextStyle(color: Colors.white)),
          activeColor: const Color(0xFFDC143C),
          contentPadding: EdgeInsets.zero,
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        option('classic', 'Klasik'),
        option('eccentric', 'Egzantrik'),
      ],
    );
  }

  @override
  Widget buildMatchScreen(
    BuildContext context, {
    required String roomCode,
    required String matchId,
    required String seatId,
  }) {
    return VampirMatchScreen(
      roomCode: roomCode,
      matchId: matchId,
      seatId: seatId,
    );
  }

  @override
  Widget buildRoleReveal(
    BuildContext context, {
    required String roomCode,
    required String matchId,
    required String seatId,
  }) {
    // The match screen gates on its own internal role reveal, so the platform
    // can route straight to it.
    return VampirMatchScreen(
      roomCode: roomCode,
      matchId: matchId,
      seatId: seatId,
    );
  }
}
