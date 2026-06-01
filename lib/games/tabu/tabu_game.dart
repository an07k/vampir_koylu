import 'package:flutter/material.dart';
import '../game_definition.dart';
import 'tabu_cards.dart';
import 'tabu_resolver.dart';
import 'tabu_match_screen.dart';

/// Tabu — describe the word without saying any of the forbidden words. A
/// single shared device passed around between teams.
class TabuGame extends GameDefinition {
  @override
  GameMeta get meta => const GameMeta(
        gameId: 'tabu',
        name: 'Tabu',
        emoji: '🗣️',
        description: 'Yasaklı kelimeleri söylemeden anlat.',
        // Single shared device: only the host seat exists, so the create-room
        // screen hides the player-count slider. Teams are configured below.
        minSeats: 1,
        maxSeats: 1,
        supportedModes: {PlayMode.single},
      );

  @override
  final GameResolver resolver = TabuResolver();

  @override
  Map<String, dynamic> defaultConfig() => {
        'targetScore': 30,
        'roundDuration': 60,
        'passLimit': 3,
        'teams': ['Takım 1', 'Takım 2'],
        'categories': ['genel'],
      };

  @override
  Widget? buildLobbyConfig(
    BuildContext context,
    Map<String, dynamic> config,
    VoidCallback onChanged,
  ) {
    return _TabuLobbyConfig(config: config, onChanged: onChanged);
  }

  @override
  Widget buildMatchScreen(
    BuildContext context, {
    required String roomCode,
    required String matchId,
    required String seatId,
  }) {
    return TabuMatchScreen(roomCode: roomCode, matchId: matchId, seatId: seatId);
  }

  @override
  Widget buildRoleReveal(
    BuildContext context, {
    required String roomCode,
    required String matchId,
    required String seatId,
  }) {
    return TabuMatchScreen(roomCode: roomCode, matchId: matchId, seatId: seatId);
  }
}

/// Stateful so team-name [TextEditingController]s survive rebuilds triggered by
/// [onChanged]. Writes directly into the shared [config] map.
class _TabuLobbyConfig extends StatefulWidget {
  final Map<String, dynamic> config;
  final VoidCallback onChanged;

  const _TabuLobbyConfig({required this.config, required this.onChanged});

  @override
  State<_TabuLobbyConfig> createState() => _TabuLobbyConfigState();
}

class _TabuLobbyConfigState extends State<_TabuLobbyConfig> {
  static const _teal = Color(0xFF00897B);
  static const _scoreOptions = [20, 30, 50];
  static const _durationOptions = [45, 60, 90];
  static const _teamCountOptions = [2, 3, 4];

  late List<TextEditingController> _nameCtrls;

  List<String> get _teams =>
      List<String>.from(widget.config['teams'] ?? const ['Takım 1', 'Takım 2']);

  @override
  void initState() {
    super.initState();
    _nameCtrls = _teams
        .map((name) => TextEditingController(text: name))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _nameCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _setTeamCount(int count) {
    final names = _teams;
    while (names.length < count) {
      names.add('Takım ${names.length + 1}');
      _nameCtrls.add(TextEditingController(text: names.last));
    }
    while (names.length > count) {
      names.removeLast();
      _nameCtrls.removeLast().dispose();
    }
    widget.config['teams'] = names;
    widget.onChanged();
    setState(() {});
  }

  void _setName(int i, String value) {
    final names = _teams;
    names[i] = value;
    widget.config['teams'] = names;
    widget.onChanged();
  }

  List<String> get _selectedCategories =>
      List<String>.from(widget.config['categories'] ?? const ['genel']);

  void _toggleCategory(String id) {
    final sel = _selectedCategories;
    if (sel.contains(id)) {
      if (sel.length <= 1) return; // keep at least one
      sel.remove(id);
    } else {
      sel.add(id);
    }
    widget.config['categories'] = sel;
    widget.onChanged();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final teamCount = _nameCtrls.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _intChips(
          label: 'Takım sayısı',
          options: _teamCountOptions,
          selected: teamCount,
          suffix: '',
          onPick: _setTeamCount,
        ),
        const SizedBox(height: 12),
        const Text('Takım isimleri',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 6),
        ...List.generate(teamCount, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _nameCtrls[i],
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => _setName(i, v),
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.group, color: Colors.white38, size: 20),
                hintText: 'Takım ${i + 1}',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        const Text('Kategoriler',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: tabuCategories.map((cat) {
            final sel = _selectedCategories.contains(cat.id);
            return FilterChip(
              label: Text('${cat.emoji} ${cat.name}'),
              selected: sel,
              onSelected: (_) => _toggleCategory(cat.id),
              labelStyle: TextStyle(color: sel ? Colors.white : Colors.white70),
              selectedColor: _teal,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              checkmarkColor: Colors.white,
              showCheckmark: false,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        _intChips(
          label: 'Kazanma puanı',
          options: _scoreOptions,
          selected: widget.config['targetScore'] ?? 30,
          suffix: '',
          onPick: (v) {
            widget.config['targetScore'] = v;
            widget.onChanged();
            setState(() {});
          },
        ),
        const SizedBox(height: 12),
        _intChips(
          label: 'Tur süresi',
          options: _durationOptions,
          selected: widget.config['roundDuration'] ?? 60,
          suffix: 'sn',
          onPick: (v) {
            widget.config['roundDuration'] = v;
            widget.onChanged();
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _intChips({
    required String label,
    required List<int> options,
    required int selected,
    required String suffix,
    required ValueChanged<int> onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 10,
          children: options.map((o) {
            final sel = o == selected;
            return ChoiceChip(
              label: Text('$o$suffix'),
              selected: sel,
              onSelected: (_) => onPick(o),
              labelStyle: TextStyle(color: sel ? Colors.white : Colors.white70),
              selectedColor: _teal,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
            );
          }).toList(),
        ),
      ],
    );
  }
}
