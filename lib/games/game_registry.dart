import 'game_definition.dart';
import 'vampir/vampir_game.dart';
import 'tabu/tabu_game.dart';

/// Canonical catalog of playable games. Adding a game = implementing
/// [GameDefinition] and registering an instance here.
class GameRegistry {
  static final List<GameDefinition> _games = <GameDefinition>[
    VampirGame(),
    TabuGame(),
  ];

  static List<GameDefinition> get all =>
      _games.where((g) => g.meta.enabled).toList();

  static GameDefinition? byId(String gameId) {
    for (final g in _games) {
      if (g.meta.gameId == gameId) return g;
    }
    return null;
  }
}
